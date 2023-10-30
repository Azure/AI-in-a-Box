/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - (optional) Create Azure Document Intelligence Instance
      3 - (optional) Create Azure Search Instance
      4 - Create Storage Account
      5 - Create CosmosDB Account
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param prefix string
param subnetID string
param privateDnsZoneId string
param tags object = {}


//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var storageAccountName = '${prefix}storage${uniqueSuffix}'
var storageAccountType = 'Standard_LRS'

//Create Resources----------------------------------------------------------------------------------------------------------------------------


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

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-pe'
  location: resourceLocation
  tags: tags
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'private-endpoint-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'default'
          properties: {
            privateDnsZoneId: privateDnsZoneId
          }
        }
      ]
    }
  }
}

output openaiAccountID string = storageAccount.id
