//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

targetScope = 'resourceGroup'

param resourceGroupName string  
param location string 
param keyVaultName string 

//below info is stored in parameter file: parameters-kv.json
param kvSecretPermissions array
param kvKeyPermissions array

param tenantId string = subscription().tenantId

//param objectId string // = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'  
param objectId string 

//====================================================================================
// Existing Resource Group 
//====================================================================================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope:subscription()
}

module deployKeyVault 'key-vault.bicep' = {
  name : 'module-deployKeyVault'
  scope : resourceGroup
  params : {
    location: location
    keyVaultName: keyVaultName
    kvSecretPermissions:kvSecretPermissions
    kvKeyPermissions:kvKeyPermissions
    tenantId:tenantId
    objectId:objectId
  }
}

output keyVaultName string = deployKeyVault.outputs.keyVaultName
