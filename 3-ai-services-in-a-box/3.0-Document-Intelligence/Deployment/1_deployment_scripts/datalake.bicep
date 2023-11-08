//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param storageAccountName string
param containerList array
param mid string
param location string
param keyVaultName string


resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


resource adls 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  identity:{
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mid}': {}
    }
  }
  sku:{
    name:'Standard_LRS'
  }
  kind:'StorageV2'
  properties:{
    isHnsEnabled : true
    networkAcls:{
      bypass: 'AzureServices'
      defaultAction:'Allow'
      virtualNetworkRules:[]
      ipRules:[]
    }
    supportsHttpsTrafficOnly:true
    encryption:{
      services:{
        file:{
          enabled:true
        }
        blob: {
          enabled:true
        }
      }
      keySource:'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  name: 'default'
  parent: adls
  properties:{
    deleteRetentionPolicy: {
      days: 1
      enabled: false
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for container in containerList: {
  name: container
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}]


// save adls key to key vault
resource AdlsKeyToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AdlsPrimaryKey'
  parent: formKeyVault
  properties: {
    value: listKeys(adls.id, adls.apiVersion).keys[0].value
  }
}


// save adls end point dfs to key vault
resource AdlsEndPointDfsToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AdlsEndPointDfs'
  parent: formKeyVault
  properties: {
    value: adls.properties.primaryEndpoints.dfs
  }
}

// save adls end point web to key vault
resource AdlsEndPointWebToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AdlsEndPointWeb'
  parent: formKeyVault
  properties: {
    value: adls.properties.primaryEndpoints.web
  }
}

output storageAccountPrimaryEndPointWeb string = adls.properties.primaryEndpoints.web
output storageAccountPrimaryEndPointDfs string = adls.properties.primaryEndpoints.dfs
output storageAccountName string = adls.name
output storageAccountId string = adls.id
