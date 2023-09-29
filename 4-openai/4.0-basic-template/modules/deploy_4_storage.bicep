/*region Header
      Module Steps 
      1 - Create Azure storage Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param storageAccountName string
param storageAccountType string = 'Standard_LRS'

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//1. Create Azure Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: resourceLocation
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
  tags: {
    Type: 'Synapse Data Lake Storage'
  }
}

//2. Create your default/root folder structure
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

output storageAccountID string = storageAccount.id
