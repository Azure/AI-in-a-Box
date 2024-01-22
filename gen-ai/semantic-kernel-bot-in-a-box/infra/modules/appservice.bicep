param location string
param appServicePlanName string
param appServiceName string
param msiID string
param msiClientID string
param sku string = 'S1'
param tags object = {}
param openaiGPTModel string
param openaiEmbeddingsModel string

param documentIntelligenceName string
var documentIntelligenceNames = !empty(documentIntelligenceName) ? [documentIntelligenceName] : []
param bingName string
var bingNames = !empty(bingName) ? [bingName] : []
param openaiName string
param storageName string
param searchName string
var searchNames = !empty(searchName) ? [searchName] : []

param openaiEndpoint string
param searchEndpoint string
param documentIntelligenceEndpoint string
param sqlConnectionString string
param cosmosEndpoint string


resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openaiName
}

resource bingAccounts 'Microsoft.Bing/accounts@2020-06-10' existing = [for name in bingNames: {
  name: name
}]

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageName
}

resource searchAccounts 'Microsoft.Search/searchServices@2023-11-01' existing = [for name in searchNames: {
  name: name
}]

resource documentIntelligences 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = [for name in documentIntelligenceNames: {
  name: name
}]

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
  }
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  tags: union(tags, { 'azd-service-name': 'semantic-kernel-bot-app' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${msiID}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      http20Enabled: true
      appSettings: [
        {
          name: 'MicrosoftAppType'
          value: 'UserAssignedMSI'
        }
        {
          name: 'MicrosoftAppId'
          value: msiClientID
        }
        {
          name: 'MicrosoftAppTenantId'
          value: tenant().tenantId
        }
        {
          name: 'AOAI_API_ENDPOINT'
          value: openaiEndpoint
        }
        {
          name: 'AOAI_API_KEY'
          value: openai.listKeys().key1
        }
        {
          name: 'AOAI_GPT_MODEL'
          value: openaiGPTModel
        }
        {
          name: 'AOAI_EMBEDDINGS_MODEL'
          value: openaiEmbeddingsModel
        }
        {
          name: 'SEARCH_API_ENDPOINT'
          value: searchEndpoint
        }
        {
          name: 'SEARCH_API_KEY'
          value: !empty(searchNames) ? searchAccounts[0].listQueryKeys().value[0].key : ''
        }
        {
          name: 'SEARCH_INDEX'
          value: 'index-name'
        }
        {
          name: 'SEARCH_SEMANTIC_CONFIG'
          value: 'index-name-semantic-configuration'
        }
        {
          name: 'DOCINTEL_API_ENDPOINT'
          value: documentIntelligenceEndpoint
        }
        {
          name: 'DOCINTEL_API_KEY'
          value: !empty(documentIntelligenceName) ? documentIntelligences[0].listKeys().key1 : ''
        }
        {
          name: 'SQL_CONNECTION_STRING'
          value: sqlConnectionString
        }
        {
          name: 'COSMOS_API_ENDPOINT'
          value: cosmosEndpoint
        }
        {
          name: 'DIRECT_LINE_SECRET'
          value: ''
        }
        {
          name: 'BING_API_ENDPOINT'
          value: !empty(bingName) ? 'https://api.bing.microsoft.com/' : ''
        }
        {
          name: 'BING_API_KEY'
          value: !empty(bingName) ? bingAccounts[0].listKeys().key1 : ''
        }
        {
          name: 'PROMPT_WELCOME_MESSAGE'
          value: 'Welcome to Semantic Kernel Bot in-a-box! Ask me anything to get started.'
        }
        {
          name: 'PROMPT_SYSTEM_MESSAGE'
          value: 'Answer the questions as accurately as possible using the provided functions.'
        }
        {
          name: 'PROMPT_SUGGESTED_QUESTIONS'
          value: '[]'
        }
        {
          name: 'SSO_ENABLED'
          value: 'false'
        }
        {
          name: 'SSO_CONFIG_NAME'
          value: ''
        }
        {
          name: 'SSO_MESSAGE_TITLE'
          value: 'Please sign in to continue.'
        }
        {
          name: 'SSO_MESSAGE_PROMPT'
          value: 'Sign in'
        }
        {
          name: 'SSO_MESSAGE_SUCCESS'
          value: 'User logged in successfully! Please repeat your question.'
        }
        {
          name: 'SSO_MESSAGE_FAILED'
          value: 'Log in failed. Type anything to retry.'
        }
        {
          name: 'USE_STEPWISE_PLANNER'
          value: 'true'
        }
        {
          name: 'BLOB_API_ENDPOINT'
          value: 'https://${storageName}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'BLOB_API_KEY'
          value: storage.listKeys().keys[0].value
        }
      ]
    }
  }
}

output hostName string = appService.properties.defaultHostName
