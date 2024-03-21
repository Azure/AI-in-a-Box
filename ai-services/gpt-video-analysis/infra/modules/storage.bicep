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
param uamiId string
param principalId string  //Service Principal ID
param month string = utcNow('MM')
param year string = utcNow('yyyy')

@description('The name of the primary Storage Account. If not provided, the workspace name will be used.')
@minLength(3)
@maxLength(24)
param storageAccountName string

// Use same PAT token for 3 month blocks, min PAT age is 6 months, max is 9 months
var SASEnd = dateTimeAdd('${year}-${padLeft((int(month) - (int(month) - 1) % 3), 2, '0')}-01', 'P9M')


resource kvRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
//1. Create your Storage Account (ADLS Gen2 & HNS Enabled)
resource blobStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
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
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
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
    name: 'Standard_LRS'
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices
//2. Create your default/root folder structure
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: blobStorage
  properties: {
    deleteRetentionPolicy: {
      days: 1
      enabled: false
    }
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices/containers
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for container in containerList: {
  name: container
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}]

var sasConfig = {
  canonicalizedResource: '/blob/${blobStorage.name}/${containers[0].name}'
  signedResource: 'c'
  signedProtocol: 'https'
  signedPermission: 'rl' //racwdxltmeop for all
  //signedServices: 'b'
  keyToSign: 'key1'
  signedStart: '2024-01-25T00:00:00Z'
  //signedExpiry: '2025-12-01T00:00:00Z'
  signedExpiry: SASEnd
  signedVersion: '2022-11-02'
}
var sasToken = listServiceSas(blobStorage.name,'2021-04-01', sasConfig).serviceSasToken

resource sasTokenSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'sas-token'
  parent: kvRef
  properties: {
    value: sasToken
    }
}

var roleIDStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor

var storageRoleAssignmentId = guid('blobcontributor-${uniqueString(uamiId)}')

resource assignStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: storageRoleAssignmentId
  dependsOn: [
    blobStorage
  ]
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleIDStorageBlobDataContributor)
    principalType: 'ServicePrincipal'
  }
}


output storageaccounturl string = blobStorage.properties.primaryEndpoints.blob
output storageAccountName string = blobStorage.name
output storageAccountId string = blobService.id

