/*region Header
      Module Steps 
      1 - Get Function App Host Keys
      2 - Create Logic App 
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param logicAppFormProcName string
param azureFunctionsAppName string
param uamiId string
param storageAccountName string
param adlsCnxId string
param adlsCnxName string
param cosmosDbCnxId string
param cosmosDbCnxName string
param keyVaultName string

//Create Logic App
resource LogicAppFormProc 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppFormProcName
  location: resourceLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_blob_is_added_or_modified_(properties_only)_(V2)': {
          recurrence: {
            frequency: 'Month'
            interval: 1
          }
          evaluatedRecurrence: {
            frequency: 'Month'
            interval: 1
          }
          splitOn: '@triggerBody()'
          metadata: {
            'JTJmZmlsZXMtMS1pbnB1dA==': '/files-1-input'
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storageAccountName}\'))}/triggers/batch/onupdatedfile'
            queries: {
              checkBothCreatedAndModifiedDateTime: false
              folderId: 'JTJmZmlsZXMtMS1pbnB1dA=='
              maxFileCount: 1
            }
          }
        }
      }
      actions: {
        Get_Key_Vault_Secret: {
          runAfter: {}
          type: 'Http'
          inputs: {
            authentication: {
              audience: 'https://vault.azure.net'
              type: 'ManagedServiceIdentity'
              identity: uamiId
            }
            method: 'GET'
            queries: {
              'api-version': '2016-10-01'
            }
            uri: 'https://${keyVaultName}.vault.azure.net/secrets/FunctionAppHostKey/'
          }
          runtimeConfiguration: {
            secureData: {
              properties: [
                'outputs'
              ]
            }
          }
        }
        InitSplitFileStatusCode: {
          runAfter: {
            Get_Key_Vault_Secret: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'SplitFileStatusCode'
                type: 'integer'
                value: 0
              }
            ]
          }
        }
        Until: {
          actions: {
            ForEachFile: {
              foreach: '@json(body(\'SplitFileFunction\'))[\'single_file_list\']'
              actions: {
                'Create_or_update_document_(V3)': {
                  runAfter: {
                    RecognizeFileFunction: [
                      'Succeeded'
                    ]
                  }
                  type: 'ApiConnection'
                  inputs: {
                    body: '@body(\'RecognizeFileFunction\')'
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'documentdb_1\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    path: '/v2/cosmosdb/@{encodeURIComponent(\'AccountNameFromSettings\')}/dbs/@{encodeURIComponent(\'form-db\')}/colls/@{encodeURIComponent(\'form-docs\')}/docs'
                  }
                }
                RecognizeFileFunction: {
                  runAfter: {}
                  type: 'Http'
                  inputs: {
                    body: {
                      date: '@{items(\'ForEachFile\')?[\'date\']}'
                      date_time: '@{items(\'ForEachFile\')?[\'date_time\']}' //
                      day: '@{items(\'ForEachFile\')?[\'day\']}'
                      file_name: '@{items(\'ForEachFile\')?[\'file_name\']}'
                      file_path: '@{items(\'ForEachFile\')?[\'file_path\']}'
                      input_container: 'files-2-split'
                      month: '@{items(\'ForEachFile\')?[\'month\']}'
                      output_container: 'files-3-recognized'
                      storage_account: storageAccountName
                      year: '@{items(\'ForEachFile\')?[\'year\']}'
                    }
                    headers: {
                      'Content-Type': 'application/json'
                    }
                    method: 'POST'
                    uri: 'https://${azureFunctionsAppName}.azurewebsites.net/api/RecognizeFile?code=@{body(\'Get_Key_Vault_Secret\')?[\'value\']}'
                  }
                  runtimeConfiguration: {
                    secureData: {
                      properties: [
                        'inputs'
                        'outputs'
                      ]
                    }
                  }
                }
              }
              runAfter: {
                SetSplitFileStatusCode: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
            }
            SetSplitFileStatusCode: {
              runAfter: {
                SplitFileFunction: [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'SplitFileStatusCode'
                value: '@outputs(\'SplitFileFunction\')[\'statusCode\']'
              }
            }
            SplitFileFunction: {
              runAfter: {}
              type: 'Http'
              inputs: {
                body: {
                  file_name: '@{triggerBody()?[\'Name\']}'
                  file_path: '@{triggerBody()?[\'Path\']}'
                  input_container: 'files-1-input'
                  output_container: 'files-2-split'
                  storage_account: storageAccountName
                }
                headers: {
                  'Content-Type': 'application/json'
                }
                method: 'POST'
                uri: 'https://${azureFunctionsAppName}.azurewebsites.net/api/SplitFile?code=@{body(\'Get_Key_Vault_Secret\')?[\'value\']}'
              }
              runtimeConfiguration: {
                secureData: {
                  properties: [
                    'inputs'
                    'outputs'
                  ]
                }
              }
            }
          }
          runAfter: {
            InitSplitFileStatusCode: [
              'Succeeded'
            ]
          }
          expression: '@equals(variables(\'SplitFileStatusCode\'), 200)'
          limit: {
            count: 2
            timeout: 'PT5M'
          }
          type: 'Until'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: adlsCnxId
            connectionName: adlsCnxName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/azureblob'
          }
          documentdb_1: {
            connectionId: cosmosDbCnxId
            connectionName: cosmosDbCnxName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/documentdb'
          }
        }
      }
    }
  }
}
