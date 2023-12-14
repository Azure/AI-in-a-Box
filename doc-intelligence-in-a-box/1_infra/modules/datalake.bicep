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
param resourceLocation string
param keyVaultName string
param containerList array
param uami string

@description('The name of the primary ADLS Gen2 Storage Account. If not provided, the workspace name will be used.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountType string = 'Standard_LRS'

//Retrieve the name of the newly created key vault
resource kvRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
//1. Create your Storage Account (ADLS Gen2 & HNS Enabled)
resource r_adls 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami}': {}
    }
  }
  kind: 'StorageV2'
  location: resourceLocation
  properties: {
    accessTier: 'Hot'
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
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    supportsHttpsTrafficOnly: true
  }
  sku: {
    name: storageAccountType
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices
//2. Create your default/root folder structure
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: r_adls
  properties: {
    deleteRetentionPolicy: {
      days: 1
      enabled: false
    }
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
//3. Create containers:  'files-1-input','files-2-split','files-3-recognized','samples'
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for container in containerList: {
  name: container
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}]

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
//4. Save adls key to key vault
resource AdlsKeyToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AdlsPrimaryKey'
  parent: kvRef
  properties: {
    //value: listKeys(r_adls.id, r_adls.apiVersion).keys[0].value r_adls.id.listKeys().keys[0].value
    value: r_adls.listKeys().keys[0].value
  }
}

//5. Save adls end point dfs to key vault
resource AdlsEndPointDfsToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AdlsEndPointDfs'
  parent: kvRef
  properties: {
    value: r_adls.properties.primaryEndpoints.dfs
  }
}

//6. Save adls end point web to key vault
resource AdlsEndPointWebToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AdlsEndPointWeb'
  parent: kvRef
  properties: {
    value: r_adls.properties.primaryEndpoints.web
  }
}

output storageAccountPrimaryEndPointWeb string = r_adls.properties.primaryEndpoints.web
output storageAccountPrimaryEndPointDfs string = r_adls.properties.primaryEndpoints.dfs
output storageAccountName string = r_adls.name
output storageAccountId string = r_adls.id
