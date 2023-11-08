//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param location string
param mid string

param logicAppOutlookName string
param storageAccountName string
param adlsConnectionName string
param adlsConnectionId string 
param outlookConnectionName string
param outlookConnectionId string

//id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/outlook'
resource logicAppOutLook 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppOutlookName
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
        'When_a_new_email_arrives_(V2)': {
          splitOn: '@triggerBody()?[\'value\']'
          type: 'ApiConnectionNotification'
          inputs: {
            fetch: {
              method: 'get'
              pathTemplate: {
                template: '/v2/Mail/OnNewEmail'
              }
              queries: {
                fetchOnlyWithAttachment: true
                folderPath: 'Inbox'
                importance: 'Any'
                includeAttachments: true
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'outlook\'][\'${outlookConnectionId}\']'
                //name:outlookConnectionId
              }
            }
            subscribe: {
              body: {
                NotificationUrl: '@{listCallbackUrl()}'
              }
              method: 'post'
              pathTemplate: {
                template: '/MailSubscriptionPoke/$subscriptions'
              }
              queries: {
                fetchOnlyWithAttachment: true
                folderPath: 'Inbox'
                importance: 'Any'
              }
            }
          }
        }
      }
      actions: {
        For_each: {
          foreach: '@triggerBody()?[\'Attachments\']'
          actions: {
            Condition: {
              actions: {
                'Create_block_blob_(V2)': {
                  runAfter: {
                  }
                  type: 'ApiConnection'
                  inputs: {
                    body: '@base64ToBinary(items(\'For_each\')?[\'ContentBytes\'])'
                    host: {
                      connection: {
                        //name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                        name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    path: '/v2/codeless/datasets/@{encodeURIComponent(\'${storageAccountName}\')}/CreateBlockBlob'
                    queries: {
                      folderPath: '/files-1-input'
                      name: 'Outlook_@{items(\'For_each\')?[\'Name\']}'
                    }
                  }
                  runtimeConfiguration: {
                    contentTransfer: {
                      transferMode: 'Chunked'
                    }
                  }
                }
              }
              runAfter: {
              }
              expression: {
                and: [
                  {
                    contains: [
                      '@items(\'For_each\')?[\'Name\']'
                      '.pdf'
                    ]
                  }
                  {
                    equals: [
                      ''
                      ''
                    ]
                  }
                ]
              }
              type: 'If'
            }
          }
          runAfter: {
          }
          type: 'Foreach'
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
          outlook: {
            connectionId: outlookConnectionId
            connectionName: outlookConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/outlook'
          }
        }
      }
    }
  }
}
