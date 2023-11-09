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

param location string 
param keyVaultName string 

//below info is stored in parameter file: parameters-kv.json
param kvSecretPermissions array
param kvKeyPermissions array

param tenantId string = subscription().tenantId

//param objectId string // = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'  
param objectId string 

resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enabledForDeployment:true
    enabledForTemplateDeployment:true
    enableSoftDelete: false
    enableRbacAuthorization: true
  }
  dependsOn:[]
}


resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: 'add'
  parent:formKeyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: {
          secrets: kvSecretPermissions
          keys:kvKeyPermissions
        }
      }
    ]
  }
}

output keyVaultName string = formKeyVault.name
output keyVaultObject object = formKeyVault
