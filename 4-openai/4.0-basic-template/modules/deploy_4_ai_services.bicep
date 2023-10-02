/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param openaiAccountName string
param searchAccountName string
param docIntelAccountName string
param storageAccountName string
param storageAccountType string = 'Standard_LRS'
param tags object = {}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

// 1. Create Azure OpenAI Instance
// https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
resource openaiAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: openaiAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openaiAccountName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

//2. Create Azure Document Intelligence
// https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
resource docIntelAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: docIntelAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: docIntelAccountName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}


// 3. Create Azure Search Instance
// https://learn.microsoft.com/en-us/azure/templates/microsoft.search/searchservices
resource searchAccount 'Microsoft.Search/searchServices@2020-08-01' = {
  name: searchAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'standard'
  }
  properties: {
    publicNetworkAccess: 'disabled'
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

// 4. Create Storage Account and default container
// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: resourceLocation
  tags: tags
  properties:{
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  sku: {
    name: storageAccountType
  }
}

resource storageAccount_default 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

output openaiAccountID string = openaiAccount.id
output searchAccountID string = searchAccount.id
output docIntelAccountID string = docIntelAccount.id
output storageAccountID string = storageAccount.id
