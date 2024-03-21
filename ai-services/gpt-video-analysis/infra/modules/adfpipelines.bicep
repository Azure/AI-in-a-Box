param factoryName string
param cosmosdb string
param cosmoscontainer string
param cosmosDBEndpoint string
param keyvaulturl string 
param storageaccounturl string
param storageaccountcontainer string = 'videosin'
param opeanaibasiurl string
param uamiID string
param gpt4vdeploymentname string

var keyvaultresource = 'https://vault.azure.net'
// ...

resource uamicredential 'Microsoft.DataFactory/factories/credentials@2018-06-01' = {
  name: '${factoryName}/uamicredential'
  properties: {
    type: 'ManagedIdentity'
    typeProperties: {
      resourceId: uamiID
    }
  }
  dependsOn: []
}

resource lsCosmosDbNoSql1 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/CosmosDbNoSql1'
  properties: {
    parameters: {
      cosmosaccount: {
        type: 'string'
        defaultValue: cosmosDBEndpoint
      }
      dbname: {
        type: 'string'
        defaultValue: cosmosdb
      }
    }
    annotations: []
    type: 'CosmosDb'
    typeProperties: {
      accountEndpoint: '@{linkedService().cosmosaccount}'
      database: '@{linkedService().dbname}'
      credential: {
        type: 'CredentialReference'
        referenceName: 'uamicredential'
      }
    }
  }
  dependsOn: [
    uamicredential
  ]
}

resource lsGPT4VDeployment 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/GPT4VDeployment'
  properties: {
    parameters: {
      open_ai_base: {
        type: 'string'
        defaultValue: opeanaibasiurl
      }
      gpt4deployment: {
        type: 'string'
        defaultValue: gpt4vdeploymentname
      }
    }
    annotations: []
    type: 'RestService'
    typeProperties: {
      url: '@{linkedService().open_ai_base}'
      enableServerCertificateValidation: true
      authenticationType: 'ManagedServiceIdentity'
      aadResourceId: 'https://cognitiveservices.azure.com'
      credential: {
        type: 'CredentialReference'
        referenceName: 'uamicredential'
      }
      resource: 'https://cognitiveservices.azure.com'
    }
  }
  dependsOn: [
    uamicredential
  ]
}

resource lskvopenai_vision 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/kvopenai_vision'
  properties: {
    annotations: []
    type: 'AzureKeyVault'
    typeProperties: {
      baseUrl: keyvaulturl
      credential: {
        type: 'CredentialReference'
        referenceName: 'uamicredential'
    }
    }
  }
  dependsOn: [
    uamicredential
  ]
}

resource lsBlobStorageVideos 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${factoryName}/lsBlobStorageVideos'
  properties: {
    parameters: {
      endpoint: {
        type: 'string'
        defaultValue: storageaccounturl
      }
    }
    annotations: []
    type: 'AzureBlobStorage'
    typeProperties: {
      serviceEndpoint: storageaccounturl
      accountKind: 'StorageV2'
      credential: {
        type: 'CredentialReference'
        referenceName: 'uamicredential'
    }
    }
  }
  dependsOn: [
    uamicredential
  ]
}
resource dsCosmosGPTOutput 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/CosmosGPTOutput'
  properties: {
    linkedServiceName: {
      referenceName: 'CosmosDbNoSql1'
      type: 'LinkedServiceReference'
      parameters: {
        cosmosaccount: {
          value: '@dataset().cosmosaccount'
          type: 'Expression'
        }
        dbname: {
          value: '@dataset().cosmosdb'
          type: 'Expression'
        }
      }
    }
    parameters: {
      cosmosaccount: {
        type: 'string'
      }
      cosmosdb: {
        type: 'string'
      }
      cosmoscontainer: {
        type: 'string'
      }
    }
    annotations: []
    type: 'CosmosDbSqlApiCollection'
    schema: {}
    typeProperties: {
      collectionName: {
        value: '@dataset().cosmoscontainer'
        type: 'Expression'
      }
    }
  }
 dependsOn: [
  lsCosmosDbNoSql1
]
 }

resource dsOAIGPT4V 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/OAIGPT4V'
  properties: {
    linkedServiceName: {
      referenceName: 'GPT4VDeployment'
      type: 'LinkedServiceReference'
      parameters: {
        open_ai_base: {
          value: '@dataset().openai_api_base'
          type: 'Expression'
        }
        gpt4deployment: {
          value: '@dataset().gpt4v_deployment_name'
          type: 'Expression'
        }
      }
    }
    parameters: {
      openai_api_base: {
        type: 'String'
      }
      gpt4v_deployment_name: {
        type: 'string'
      }
      relative_url: {
        type: 'string'
      }
    }
    annotations: []
    type: 'RestResource'
    typeProperties: {
      relativeUrl: {
        value: '@dataset().relative_url'
        type: 'Expression'
      }
    }
    schema: []
  }
  dependsOn: [
    lsGPT4VDeployment
  ]
}

resource dsvideo 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/video'
  properties: {
    linkedServiceName: {
      referenceName: 'lsBlobStorageVideos'
      type: 'LinkedServiceReference'
      parameters: {
        endpoint: {
          value: '@dataset().endpoint'
          type: 'Expression'
        }
      }
    }
    parameters: {
      container: {
        type: 'string'
      }
      endpoint: {
        type: 'string'
      }
    }
    annotations: []
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: {
          value: '@dataset().container'
          type: 'Expression'
        }
      }
    }
  }
  dependsOn: [
    lsBlobStorageVideos
  ]
}

resource dsvideofile 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${factoryName}/videofile'
  properties: {
    linkedServiceName: {
      referenceName: 'lsBlobStorageVideos'
      type: 'LinkedServiceReference'
    }
    parameters: {
      container: {
        type: 'string'
      }
      filename: {
        type: 'string'
      }
      folder: {
        type: 'string'
      }
    }
    annotations: []
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        fileName: {
          value: '@dataset().filename'
          type: 'Expression'
        }
        folderPath: {
          value: '@dataset().folder'
          type: 'Expression'
        }
        container: {
          value: '@dataset().container'
          type: 'Expression'
        }
      }
    }
  }
  dependsOn: [
    lsBlobStorageVideos
  ]
}

resource plGet_Secure_Values_from_Key_Vault 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${factoryName}/GetSecureValuesFromKeyVault'
  properties: {
    activities: [
      {
        name: 'get open-api-key'
        type: 'WebActivity'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: true
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: '${keyvaulturl}secrets/open-api-key?api-version=7.0'
          method: 'GET'
          headers: {}
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: keyvaultresource
          }
        }
      }
      {
        name: 'Set pipeline return variables'
        type: 'SetVariable'
        dependsOn: [
          {
            activity: 'get open-api-key'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'get open-ai-base'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'get computer-vision-url'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'get computer-vision-api-key'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'get sas-token'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          secureOutput: true
          secureInput: true
        }
        userProperties: []
        typeProperties: {
          variableName: 'pipelineReturnValue'
          value: [
            {
              key: 'open_api_key'
              value: {
                type: 'Expression'
                content: '@activity(\'get open-api-key\').output.value'
              }
            }
            {
              key: 'openai_api_base_url'
              value: {
                type: 'Expression'
                content: '@activity(\'get open-ai-base\').output.value'
              }
            }
            {
              key: 'vision_api_base_url'
              value: {
                type: 'Expression'
                content: '@activity(\'get computer-vision-url\').output.value'
              }
            }
            {
              key: 'vision_api_key'
              value: {
                type: 'Expression'
                content: '@activity(\'get computer-vision-api-key\').output.value'
              }
            }
            {
              key: 'sas_token'
              value: {
                type: 'Expression'
                content: '@activity(\'get sas-token\').output.value'
              }
            }
          ]
          setSystemVariable: true
        }
      }
      {
        name: 'get open-ai-base'
        type: 'WebActivity'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: '${keyvaulturl}secrets/openai-api-base-url?api-version=7.0'
          method: 'GET'
          headers: {}
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: keyvaultresource
          }      
        }
      }
     {
        name: 'get computer-vision-url'
        type: 'WebActivity'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: '${keyvaulturl}secrets/vision-api-base-url?api-version=7.0'
          method: 'GET'
          headers: {}
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: keyvaultresource
          }
        }
      }
      {
        name: 'get computer-vision-api-key'
        type: 'WebActivity'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: true
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: '${keyvaulturl}secrets/vision-api-key?api-version=7.0'
          method: 'GET'
          headers: {}
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: keyvaultresource
          }
        }
      }
      {
        name: 'get sas-token'
        type: 'WebActivity'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: true
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: '${keyvaulturl}secrets/sas-token?api-version=7.0'
          method: 'GET'
          headers: {}
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: keyvaultresource
          }
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    annotations: []
  }
  dependsOn: [
    lskvopenai_vision
  ]
}

resource plchildAnalyzeVideo 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${factoryName}/childAnalyzeVideo'
  properties: {
    activities: [
      {
        name: 'Set index name'
        type: 'SetVariable'
        dependsOn: []
        policy: {
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          variableName: 'indexName'
          value: {
            value: '@concat(\'ix\',substring(replace(guid(),\'-\',\'\'),4,19),\'-ix\')'
            type: 'Expression'
          }
        }
      }
      {
        name: 'Set index id'
        type: 'SetVariable'
        dependsOn: [
          {
            activity: 'Set index name'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          variableName: 'indexID'
          value: {
            value: '@replace(variables(\'indexName\'),\'-ix\',\'-id\')'
            type: 'Expression'
          }
        }
      }
      {
        name: 'Create Index'
        type: 'WebActivity'
        dependsOn: [
          {
            activity: 'Set index id'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: {
            value: '@{pipeline().parameters.computer_vision_url}computervision/retrieval/indexes/@{variables(\'indexName\')}?api-version=2023-05-01-preview'
            type: 'Expression'
          }
          method: 'PUT'
          headers: {
            'Content-Type': 'application/json'
            'Ocp-Apim-Subscription-Key': {
              value: '@pipeline().parameters.vision_api_key'
              type: 'Expression'
            }
          }
          body: {
            features: [
              {
                name: 'vision'
                domain: 'surveillance'
              }
              {
                name: 'speech'
              }
            ]
          }
          
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: 'https://cognitiveservices.azure.com'
          }
        }
      }
      {
        name: 'Ingest Video into Index'
        type: 'WebActivity'
        dependsOn: [
          {
            activity: 'Create Index'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: true
          secureInput: true
        }
        userProperties: []
        typeProperties: {
          url: {
            value: '@{pipeline().parameters.computer_vision_url}computervision/retrieval/indexes/@{variables(\'indexName\')}/ingestions/my-ingestion?api-version=2023-05-01-preview'
            type: 'Expression'
          }
          method: 'PUT'
          headers: {
            'Content-Type': 'application/json'
            'Ocp-Apim-Subscription-Key': {
              value: '@pipeline().parameters.vision_api_key'
              type: 'Expression'
            }
          }
          body: {
            value: '{"videos": [{"mode": "add","documentId": "@{variables(\'indexID\')}","documentUrl": "@{pipeline().parameters.storageaccounturl}@{pipeline().parameters.storageaccountfolder}/@{pipeline().parameters.fileName}?@{pipeline().parameters.sas_token}"}],"generateInsightIntervals": false,"moderation": false,"filterDefectedFrames": false,"includeSpeechTranscript": true}'
            type: 'Expression'
          }
          authentication: {
            type: 'UserAssignedMSI'
            credential: {
              referenceName: 'uamicredential'
              type: 'CredentialReference'
            }
            resource: 'https://cognitiveservices.azure.com'
          }
        }
      }
      {
        name: 'Check and wait until ingestion complete'
        type: 'Until'
        dependsOn: [
          {
            activity: 'Ingest Video into Index'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          expression: {
            value: '@or(equals(variables(\'ingestionStatus\'),\'Completed\'),equals(variables(\'ingestionStatus\'),\'Failed\'))'
            type: 'Expression'
          }
          activities: [
            {
              name: 'Check if completed'
              type: 'IfCondition'
              dependsOn: [
                {
                  activity: 'Set ingestion status'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]
              userProperties: []
              typeProperties: {
                expression: {
                  value: '@or(equals(variables(\'ingestionStatus\'),\'Completed\'),equals(variables(\'ingestionStatus\'),\'Failed\'))'
                  type: 'Expression'
                }
                ifFalseActivities: [
                  {
                    name: 'Wait and check again in a bit'
                    type: 'Wait'
                    dependsOn: []
                    userProperties: []
                    typeProperties: {
                      waitTimeInSeconds: 30
                    }
                  }
                ]
              }
            }
            {
              name: 'Call API to see if ingestion completed'
              type: 'WebActivity'
              dependsOn: []
              policy: {
                timeout: '0.12:00:00'
                retry: 0
                retryIntervalInSeconds: 30
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                url: {
                  value: '@{pipeline().parameters.computer_vision_url}computervision/retrieval/indexes/@{variables(\'indexName\')}/ingestions?api-version=2023-05-01-preview'
                  type: 'Expression'
                }
                method: 'GET'
                headers: {
                  'Ocp-Apim-Subscription-Key': {
                    value: '@pipeline().parameters.vision_api_key'
                    type: 'Expression'
                  }
                }
                body: ''
                authentication: {
                  type: 'UserAssignedMSI'
                  credential: {
                    referenceName: 'uamicredential'
                    type: 'CredentialReference'
                  }
                  resource: 'https://cognitiveservices.azure.com'
                }
              }
            }
            {
              name: 'Set ingestion status'
              type: 'SetVariable'
              dependsOn: [
                {
                  activity: 'Call API to see if ingestion completed'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]
              policy: {
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                variableName: 'ingestionStatus'
                value: {
                  value: '@activity(\'Call API to see if ingestion completed\').output.value[0].state'
                  type: 'Expression'
                }
              }
            }
          ]
          timeout: '0.00:15:00'
        }
      }
      {
        name: 'Check if success'
        type: 'IfCondition'
        dependsOn: [
          {
            activity: 'Check and wait until ingestion complete'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          expression: {
            value: '@equals(variables(\'ingestionStatus\'),\'Completed\')'
            type: 'Expression'
          }
          ifFalseActivities: [
            {
              name: 'Fail1'
              type: 'Fail'
              dependsOn: []
              userProperties: []
              typeProperties: {
                message: 'Ingestion failed or timed out'
                errorCode: '500'
              }
            }
          ]
          ifTrueActivities: [
            {
              name: 'Analyze Video with GPT-4V'
              type: 'WebActivity'
              state: 'Inactive'
              onInactiveMarkAs: 'Succeeded'
              dependsOn: []
              policy: {
                timeout: '0.12:00:00'
                retry: 0
                retryIntervalInSeconds: 30
                secureOutput: false
                secureInput: true
              }
              userProperties: []
              typeProperties: {
                url: {
                  value: '@{pipeline().parameters.openai_api_base}/openai/deployments/@{pipeline().parameters.gpt_4v_deployment_name}/extensions/chat/completions?api-version=2023-12-01-preview'
                  type: 'Expression'
                }
                method: 'POST'
                headers: {
                  'Content-Type': 'application/json'
                  'api-key': {
                    value: '@pipeline().parameters.open_ai_key'
                    type: 'Expression'
                  }
                }
                body: {
                  value: '{"enhancements": { "video": { "enabled": true } }, "dataSources": [ { "type": "AzureComputerVisionVideoIndex", "parameters": { "computerVisionBaseUrl": "@{pipeline().parameters.computer_vision_url}//computervision", "computerVisionApiKey": "@{pipeline().parameters.vision_api_key}", "indexName": "@{variables(\'indexName\')}", "videoUrls": ["@{pipeline().parameters.storageaccounturl}/@{pipeline().parameters.storageaccountfolder}/@{pipeline().parameters.fileName}?@{pipeline().parameters.sas_token}"]}}], "messages": [ { "role": "system", "content": [{"type": "text","text": "@{pipeline().parameters.sys_message}" }]}, { "role": "user", "content": [ { "type": "acv_document_id", "acv_document_id": "@{variables(\'indexID\')}" } ] }, { "role": "user", "content": [ { "type": "text", "text": "@{pipeline().parameters.user_prompt}" } ] } ], @{pipeline().parameters.temperature} @{pipeline().parameters.top_p} "max_tokens": 4096 }'
                  type: 'Expression'
                }
                authentication: {
                  type: 'UserAssignedMSI'
                  credential: {
                    referenceName: 'uamicredential'
                    type: 'CredentialReference'
                  }
                  resource: 'https://cognitiveservices.azure.com'
                }
              }
            }
            {
              name: 'Copy GPT4 Response to Cosmos'
              type: 'Copy'
              dependsOn: []
              policy: {
                timeout: '0.12:00:00'
                retry: 0
                retryIntervalInSeconds: 30
                secureOutput: false
                secureInput: true
              }
              userProperties: []
              typeProperties: {
                source: {
                  type: 'RestSource'
                  additionalColumns: [
                    {
                      name: 'timestamp'
                      value: {
                        value: '@pipeline().TriggerTime'
                        type: 'Expression'
                      }
                    }
                    {
                      name: 'fileurl'
                      value: {
                        value: '@{pipeline().parameters.storageaccounturl}@{pipeline().parameters.storageaccountfolder}@{pipeline().parameters.fileName}'
                        type: 'Expression'
                      }
                    }
                    {
                      name: 'filename'
                      value: {
                        value: '@pipeline().parameters.fileName'
                        type: 'Expression'
                      }
                    }
                    {
                      name: 'shortdate'
                      value: {
                        value: '@formatDateTime(pipeline().TriggerTime,\'yyyy-MM-dd\')'
                        type: 'Expression'
                      }
                    }
                    {
                      name: 'temperature'
                      value: {
                        value: '@replace(pipeline().parameters.temperature,\'"temperature:"\',\'""\')'
                        type: 'Expression'
                      }
                    }
                    {
                      name: 'top_p'
                      value: {
                        value: '@replace(pipeline().parameters.top_p,\'"top_p:"\',\'""\')'
                        type: 'Expression'
                      }
                    }
                  ]
                  httpRequestTimeout: '00:05:00'
                  requestInterval: '00.00:00:00.010'
                  requestMethod: 'POST'
                  requestBody: {
                    value: '{"enhancements": { "video": { "enabled": true } }, "dataSources": [ { "type": "AzureComputerVisionVideoIndex", "parameters": { "computerVisionBaseUrl": "@{pipeline().parameters.computer_vision_url}computervision", "computerVisionApiKey": "@{pipeline().parameters.vision_api_key}", "indexName": "@{variables(\'indexName\')}", "videoUrls": ["@{pipeline().parameters.storageaccounturl}@{pipeline().parameters.storageaccountfolder}/@{pipeline().parameters.fileName}?@{pipeline().parameters.sas_token}"]}}], "messages": [ { "role": "system", "content": [{"type": "text","text": "@{pipeline().parameters.sys_message}" }]}, { "role": "user", "content": [ { "type": "acv_document_id", "acv_document_id": "@{variables(\'indexID\')}" } ] }, { "role": "user", "content": [ { "type": "text", "text": "@{pipeline().parameters.user_prompt}" } ] } ],  @{pipeline().parameters.temperature} @{pipeline().parameters.top_p} "max_tokens": 4096 }'
                    type: 'Expression'
                  }
                  additionalHeaders: {
                    'api-key': {
                      value: '@pipeline().parameters.open_ai_key'
                      type: 'Expression'
                    }
                    'Content-Type': 'application/json'
                  }
                  paginationRules: {
                    supportRFC5988: 'true'
                  }
                }
                sink: {
                  type: 'CosmosDbSqlApiSink'
                  writeBehavior: 'insert'
                }
                enableStaging: false
                translator: {
                  type: 'TabularTranslator'
                  mappings: [
                    {
                      source: {
                        path: '$[\'id\']'
                      }
                      sink: {
                        path: 'id'
                      }
                    }
                    {
                      source: {
                        path: '$[\'choices\'][0][\'message\'][\'content\']'
                      }
                      sink: {
                        path: 'content'
                      }
                    }
                    {
                      source: {
                        path: '$[\'usage\'][\'prompt_tokens\']'
                      }
                      sink: {
                        path: 'prompt_tokens'
                      }
                    }
                    {
                      source: {
                        path: '$[\'usage\'][\'completion_tokens\']'
                      }
                      sink: {
                        path: 'completion_tokens'
                      }
                    }
                    {
                      source: {
                        path: '$[\'timestamp\']'
                      }
                      sink: {
                        path: 'timestamp'
                      }
                    }
                    {
                      source: {
                        path: '$[\'fileurl\']'
                      }
                      sink: {
                        path: 'orignalfileurl'
                      }
                    }
                    {
                      source: {
                        path: '$[\'filename\']'
                      }
                      sink: {
                        path: 'filename'
                      }
                    }
                    {
                      source: {
                        path: '$[\'shortdate\']'
                      }
                      sink: {
                        path: 'shortdate'
                      }
                    }
                    {
                      source: {
                        path: '$[\'temperature\']'
                      }
                      sink: {
                        path: 'temperature'
                      }
                    }
                    {
                      source: {
                        path: '$[\'temp_p\']'
                      }
                      sink: {
                        path: 'temp_p'
                      }
                    }
                  ]
                  collectionReference: ''
                }
              }
              inputs: [
                {
                  referenceName: 'OAIGPT4V'
                  type: 'DatasetReference'
                  parameters: {
                    openai_api_base: {
                      value: '@pipeline().parameters.openai_api_base'
                      type: 'Expression'
                    }
                    gpt4v_deployment_name: {
                      value: '@pipeline().parameters.gpt_4v_deployment_name'
                      type: 'Expression'
                    }
                    relative_url: {
                      value: '@{pipeline().parameters.openai_api_base}/openai/deployments/@{pipeline().parameters.gpt_4v_deployment_name}/extensions/chat/completions?api-version=2023-12-01-preview'
                      type: 'Expression'
                    }
                  }
                }
              ]
              outputs: [
                {
                  referenceName: 'CosmosGPTOutput'
                  type: 'DatasetReference'
                  parameters: {
                    cosmosaccount: {
                      value: '@pipeline().parameters.cosmosaccount'
                      type: 'Expression'
                    }
                    cosmosdb: {
                      value: '@pipeline().parameters.cosmosdb'
                      type: 'Expression'
                    }
                    cosmoscontainer: {
                      value: '@pipeline().parameters.cosmoscontainer'
                      type: 'Expression'
                    }
                  }
                }
              ]
            }
            {
              name: 'Get Damage Probabilty'
              description: 'Damage[probabliity]'
              type: 'Lookup'
              dependsOn: [
                {
                  activity: 'Copy GPT4 Response to Cosmos'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]
              policy: {
                timeout: '0.12:00:00'
                retry: 0
                retryIntervalInSeconds: 30
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                source: {
                  type: 'CosmosDbSqlApiSource'
                  query: {
                    value: 'SELECT SUBSTRING(gptoutput.content, INDEX_OF(gptoutput.content, "DamageProbability[") + 18, INDEX_OF(gptoutput.content, "]", INDEX_OF(gptoutput.content, "DamageProbability[") + 18) - INDEX_OF(gptoutput.content, "DamageProbability[") - 18) AS DamageProbability\nFROM gptoutput WHERE gptoutput.filename=\'@{pipeline().parameters.fileName}\'\n'
                    type: 'Expression'
                  }
                  preferredRegions: []
                  detectDatetime: true
                }
                dataset: {
                  referenceName: 'CosmosGPTOutput'
                  type: 'DatasetReference'
                  parameters: {
                    cosmosaccount: {
                      value: '@pipeline().parameters.cosmosaccount'
                      type: 'Expression'
                    }
                    cosmosdb: {
                      value: '@pipeline().parameters.cosmosdb'
                      type: 'Expression'
                    }
                    cosmoscontainer: {
                      value: '@pipeline().parameters.cosmoscontainer'
                      type: 'Expression'
                    }
                  }
                }
              }
            }
            {
              name: 'Set processed folder'
              type: 'SetVariable'
              dependsOn: [
                {
                  activity: 'Get Damage Probabilty'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]
              policy: {
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                variableName: 'processedfolder'
                value: {
                  value: '@if(equals(activity(\'Get Damage Probabilty\').output.firstRow.DamageProbability,\'1\'),\'processed\' , \'reviewfordamage\')'
                  type: 'Expression'
                }
              }
            }
            {
              name: 'Move file to processed container'
              type: 'Copy'
              dependsOn: [
                {
                  activity: 'Set processed folder'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]
              policy: {
                timeout: '0.12:00:00'
                retry: 0
                retryIntervalInSeconds: 30
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                source: {
                  type: 'BinarySource'
                  storeSettings: {
                    type: 'AzureBlobStorageReadSettings'
                    recursive: true
                    deleteFilesAfterCompletion: true
                  }
                  formatSettings: {
                    type: 'BinaryReadSettings'
                  }
                }
                sink: {
                  type: 'BinarySink'
                  storeSettings: {
                    type: 'AzureBlobStorageWriteSettings'
                  }
                }
                enableStaging: false
              }
              inputs: [
                {
                  referenceName: 'videofile'
                  type: 'DatasetReference'
                  parameters: {
                    container: {
                      value: '@pipeline().parameters.storageaccountfolder'
                      type: 'Expression'
                    }
                    filename: {
                      value: '@pipeline().parameters.fileName'
                      type: 'Expression'
                    }
                    folder: ' '
                  }
                }
              ]
              outputs: [
                {
                  referenceName: 'videofile'
                  type: 'DatasetReference'
                  parameters: {
                    container: 'videosprocessed'
                    filename: {
                      value: '@pipeline().parameters.fileName'
                      type: 'Expression'
                    }
                    folder: {
                      value: '@variables(\'processedfolder\')'
                      type: 'Expression'
                    }
                  }
                }
              ]
            }
          ]
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    parameters: {
      fileName: {
        type: 'string'
        defaultValue: 'Timeline-2023-07-13 12.59.59.740 PM.mp4'
      }
      computer_vision_url: {
        type: 'string'
      }
      vision_api_key: {
        type: 'string'
      }
      gpt_4v_deployment_name: {
        type: 'string'
      }
      open_ai_key: {
        type: 'string'
      }
      openai_api_base: {
        type: 'string'
      }
      sys_message: {
        type: 'string'
      }
      user_prompt: {
        type: 'string'
      }
      sas_token: {
        type: 'string'
      }
      storageaccounturl: {
        type: 'string'
      }
      storageaccountfolder: {
        type: 'string'
      }
      temperature: {
        type: 'string'
      }
      top_p: {
        type: 'string'
      }
      cosmosaccount: {
        type: 'string'
      }
      cosmosdb: {
        type: 'string'
      }
      cosmoscontainer: {
        type: 'string'
      }
    }
    variables: {
      indexName: {
        type: 'String'
      }
      indexID: {
        type: 'String'
      }
      ingestionStatus: {
        type: 'String'
        defaultValue: 'Running'
      }
      sasurl: {
        type: 'String'
      }
      damageprobablity: {
        type: 'String'
      }
      processedfolder: {
        type: 'String'
      }
    }
    annotations: []
  }
  dependsOn: [
    dsOAIGPT4V
    dsCosmosGPTOutput
    dsvideofile
  ]
}

resource orchestratorGetandAnalyzeVideos 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${factoryName}/orchestratorGetandAnalyzeVideos'
  properties: {
    activities: [
      {
        name: 'Get Videos'
        type: 'GetMetadata'
        dependsOn: [
          {
            activity: 'Get Secure Values from Key Vault'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'Check if top_p is specified'
            dependencyConditions: [
              'Succeeded'
            ]
          }
          {
            activity: 'Check if temperature is specified'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          dataset: {
            referenceName: 'video'
            type: 'DatasetReference'
            parameters: {
              container: {
                value: '@pipeline().parameters.storageaccountcontainer'
                type: 'Expression'
              }
              endpoint: {
                value: '@pipeline().parameters.storageaccounturl'
                type: 'Expression'
              }
            }
          }
          fieldList: [
            'childItems'
          ]
          storeSettings: {
            type: 'AzureBlobStorageReadSettings'
            recursive: true
            enablePartitionDiscovery: false
          }
          formatSettings: {
            type: 'BinaryReadSettings'
          }
        }
      }
      {
        name: 'Get Secure Values from Key Vault'
        type: 'ExecutePipeline'
        dependsOn: []
        userProperties: []
        typeProperties: {
          pipeline: {
            referenceName: 'GetSecureValuesFromKeyVault'
            type: 'PipelineReference'
          }
          waitOnCompletion: true
          parameters: {}
        }
      }
      {
        name: 'ForEach Video File'
        type: 'ForEach'
        dependsOn: [
          {
            activity: 'Get Videos'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@activity(\'Get Videos\').output.childItems'
            type: 'Expression'
          }
          isSequential: false
          activities: [
            {
              name: 'childAnalyzeVideo'
              type: 'ExecutePipeline'
              dependsOn: []
              userProperties: []
              typeProperties: {
                pipeline: {
                  referenceName: 'childAnalyzeVideo'
                  type: 'PipelineReference'
                }
                waitOnCompletion: true
                parameters: {
                  fileName: {
                    value: '@item().name'
                    type: 'Expression'
                  }
                  computer_vision_url: {
                    value: '@activity(\'Get Secure Values from Key Vault\').output.pipelineReturnValue.vision_api_base_url'
                    type: 'Expression'
                  }
                  vision_api_key: {
                    value: '@activity(\'Get Secure Values from Key Vault\').output.pipelineReturnValue.vision_api_key'
                    type: 'Expression'
                  }
                  gpt_4v_deployment_name: {
                    value: gpt4vdeploymentname
                    type: 'Expression'
                  }
                  open_ai_key: {
                    value: '@activity(\'Get Secure Values from Key Vault\').output.pipelineReturnValue.open_api_key'
                    type: 'Expression'
                  }
                  openai_api_base: {
                    value: '@activity(\'Get Secure Values from Key Vault\').output.pipelineReturnValue.openai_api_base_url'
                    type: 'Expression'
                  }
                  sys_message: {
                    value: '@pipeline().parameters.sys_message'
                    type: 'Expression'
                  }
                  user_prompt: {
                    value: '@pipeline().parameters.user_prompt'
                    type: 'Expression'
                  }
                  sas_token: {
                    value: '@activity(\'Get Secure Values from Key Vault\').output.pipelineReturnValue.sas_token'
                    type: 'Expression'
                  }
                  storageaccounturl: {
                    value: '@pipeline().parameters.storageaccounturl'
                    type: 'Expression'
                  }
                  storageaccountfolder: {
                    value: '@pipeline().parameters.storageaccountcontainer'
                    type: 'Expression'
                  }
                  temperature: {
                    value: '@variables(\'temperature\')'
                    type: 'Expression'
                  }
                  top_p: {
                    value: '@variables(\'top_p\')'
                    type: 'Expression'
                  }
                  cosmosaccount: {
                    value: '@pipeline().parameters.cosmosaccount'
                    type: 'Expression'
                  }
                  cosmosdb: {
                    value: '@pipeline().parameters.cosmosdb'
                    type: 'Expression'
                  }
                  cosmoscontainer: {
                    value: '@pipeline().parameters.cosmoscontainer'
                    type: 'Expression'
                  }
                }
              }
            }
          ]
        }
      }
      {
        name: 'Check if top_p is specified'
        type: 'IfCondition'
        dependsOn: []
        userProperties: []
        typeProperties: {
          expression: {
            value: '@equals(trim(string(pipeline().parameters.top_p)),\'\')'
            type: 'Expression'
          }
          ifFalseActivities: [
            {
              name: 'Set top_p detail option'
              type: 'SetVariable'
              dependsOn: []
              policy: {
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                variableName: 'top_p'
                value: {
                  value: '"top_p": @{pipeline().parameters.top_p},'
                  type: 'Expression'
                }
              }
            }
          ]
        }
      }
      {
        name: 'Check if temperature is specified'
        type: 'IfCondition'
        dependsOn: []
        userProperties: []
        typeProperties: {
          expression: {
            value: '@equals(trim(string(pipeline().parameters.temperature)),\'\')'
            type: 'Expression'
          }
          ifFalseActivities: [
            {
              name: 'Set temperature'
              type: 'SetVariable'
              dependsOn: []
              policy: {
                secureOutput: false
                secureInput: false
              }
              userProperties: []
              typeProperties: {
                variableName: 'temperature'
                value: {
                  value: '"temperature": @{pipeline().parameters.temperature},'
                  type: 'Expression'
                }
              }
            }
          ]
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    parameters: {
      sys_message: {
        type: 'string'
        defaultValue: 'Your task is to analyze vehicles for damage.  You will be presented videos of vehicles. Each video will only show a portion of the vehicle. Hint: the name of the video contains the area of the car that should be examined in the video.  You need to inspect the video closely and describe any damage to the vehicle, such as dents, scratches, broken lights, broken windows, etc. Sometimes duct tape may be used to cover up damage which may be potential damage and should be described as well. You need to pay close attention, especially to distinguish between damage to the vehicles body and glare. First provide a summary of the vehicle and the damage or potential damage to the vehicle in the video. Also return a description for what type of vehicle it is in the format of VehicleType[vehicletype] for example VehicleType[Ford F150].. If you can\'t identify the exact model type, return what type of vehicle it is such as VehicleType[Sedan] or VehicleType[Truck].  Rank each video on a scale of 1 to 10 where 1 is the probability of no damage and 10 is a high probability of damage. Describe your reasoning for the rank and output your rank in the format of DamageProbability[rank], for example DamageProbability[4]. If there is damage, along with describing what the damage is, provide a short description of the damage in the format of Damage[damages]. For example Damage[dent] or Damage[dent, scratch]. If there is no damage, return Damage[NA]. Also rank the severity of the damage where a scratch or small dent would be Low; multiple scratches, many scratches, larger dents, broken headlights would be Medium;  broken windows, very large dents would be High. Provide the severity ranking in the format of Severity[severityranking]. For example Severity[medium]. If there is no damage, return Severity[NA]. Provide a short description of the location of the damage for example, Location[damagelocation]. For example,  Location[hood] or Location[front passenger door, hood].  If there is noo damage, return the general location of the  portion  of the vehicle being examined, for example Location[passenger side low].'
      }
      user_prompt: {
        type: 'string'
        defaultValue: 'Describe any damage or potential damage to the vehicle that you see in the video. '
      }
      storageaccounturl: {
        type: 'string'
        defaultValue: storageaccounturl
      }
      storageaccountcontainer: {
        type: 'string'
        defaultValue: storageaccountcontainer
      }
      temperature: {
        type: 'string'
        defaultValue: '0.5'
      }
      top_p: {
        type: 'string'
      }
      cosmosaccount: {
        type: 'string'
        defaultValue: cosmosDBEndpoint
      }
      cosmosdb: {
        type: 'string'
        defaultValue: cosmosdb
      }
      cosmoscontainer: {
        type: 'string'
        defaultValue: cosmoscontainer
      }
    }
    variables: {
      top_p: {
        type: 'String'
      }
      temperature: {
        type: 'String'
      }
    }
    annotations: []
  }
  dependsOn: [
    dsvideo
    plGet_Secure_Values_from_Key_Vault
    plchildAnalyzeVideo
  ]
}



