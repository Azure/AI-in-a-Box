/*region Header
      Module Steps 
      1 - Create Storage Account
      2 - Create default/root folder structure
      3 - Create containers
      4 - Save adls key to key vault
      5 - Save adls end point dfs to key vault
      6 - Save adls end point web to key vault
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param storageAccountName string
param location string

//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
//1. Create your Storage Account
resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
  sku: {
      name: 'Standard_LRS'
  }
}

//2. Create your default/root folder structure
resource storageAccount_default 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: stg
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

//3. Create another container called iot in the root
resource containerBronze 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  parent: storageAccount_default
  name: 'iot'
  properties: {
    publicAccess: 'None'
  }
}    

output stgId string = stg.id
output stgName string = stg.name
