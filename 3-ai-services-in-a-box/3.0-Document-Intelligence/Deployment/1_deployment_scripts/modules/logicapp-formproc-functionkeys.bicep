//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param logicAppFormProcName string //= 'appFormProc'
param azureFunctionsAppName string
param storageAccountName string
param location string
param mid string
param adlsConnectionName string
param adlsConnectionId string 
param cosmosDbConnectionName string
param cosmosDbConnectionId string

param FunctionRecognizeFileKey string 
param FunctionSplitFileKey string 

resource LogicAppFormProc 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppFormProcName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mid}': {
      }
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
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
        InitSplitFileStatusCode: {
          runAfter: {
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
                        name: '@parameters(\'$connections\')[\'documentdb_1\'][\'${cosmosDbConnectionName}\']'
                      }
                    }
                    method: 'post'
                    path: '/v2/cosmosdb/@{encodeURIComponent(\'cosmosdb-forms\')}/dbs/@{encodeURIComponent(\'form-db\')}/colls/@{encodeURIComponent(\'form-docs\')}/docs'
                  }
                }
                RecognizeFileFunction: {
                  runAfter: {
                  }
                  type: 'Http'
                  inputs: {
                    body: {
                      date: '@{items(\'ForEachFile\')?[\'date\']}'
                      date_time: '@{items(\'ForEachFile\')?[\'date_time\']}'
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
                    uri: 'https://${azureFunctionsAppName}.azurewebsites.net/api/RecognizeFile?code=${FunctionRecognizeFileKey}'
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
              runAfter: {
              }
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
                uri: 'https://${azureFunctionsAppName}.azurewebsites.net/api/SplitFile?code=${FunctionSplitFileKey}'
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
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: adlsConnectionId
            connectionName: adlsConnectionName
            // will add this type of connection in future
            /*
            connectionProperties: {
              authentication: {
                identity: mid
                type: 'ManagedServiceIdentity'
              }
            }
            */
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
          }
          documentdb_1: {
            connectionId: cosmosDbConnectionId
            connectionName: cosmosDbConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/documentdb'
          }
        }
      }
    }
  }
}
