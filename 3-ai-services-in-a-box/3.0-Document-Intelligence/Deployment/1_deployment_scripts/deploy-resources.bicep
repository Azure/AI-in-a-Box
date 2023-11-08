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

param keyVaultName string 
param location string 
param resourceGroupName string 

param midName string
param storageAccountName string
param formRecognierName string
param cosmosAccountName string

var cosmosDbName = 'form-db' // preset for solution
var cosmosDbContainerName = 'form-docs' // preset for solution

//====================================================================================
// Resource Group and KeyVault Policy Set up 
//====================================================================================

// Resource Group already created
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope:subscription()
}

@description('create resource with solution accelerator tag ID')
resource resourceId 'Microsoft.Resources/deployments@2020-10-01' = {
  name: 'pid-1b1b8df6-e4d2-5a68-bd35-8d842a935d5c' 
  properties:{
    mode: 'Incremental'
    template:{
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

//====================================================================================
// Resources Created and Security Permissions 
//====================================================================================
// Resources Created: 
//      Resource Group User Assigned MID
//      Azure Data Lake with containers 
//      Azure Cosmos DB
//      Azure Form Recognizer 
// Role Assignments:
//      Assigned 'Storage Blob Contributor' Role to Resource Group User Assigned MID
//      Assigned 'Storage Blob Contributor' Role to Azure Form Recognizer 
// Sensitive Information Saved to Key Vault
//      Azure Data Lake Primary Key saved to Key Vault as 'AdlsPrimaryKey'
//      Azure Data Lake End Points saved to Key Vault as 'AdlsEndPointDfs' and 'AdlsEndPointWeb'
//      Cosmos DB Primary Key saved to Key Vault as 'CosmosDbPrimaryKey'
//      Cosmos DB Connection String saved to Key Vault as 'CosmosDbConnectionString'
//      Form Recognizer End Point Saved to Key Vault as 'FormRecognizerEndPoint'
//      Form Recognizer Key saved to key vault as 'FormRecognizerKey'
//=====================================================================================


module userAssignedMid 'user-mid.bicep' = {
  name : 'module-user-mid'
  scope : resourceGroup
  params : {
    midName: midName
    location: location
  }
}

module datalakev2 'datalake.bicep' = {
  name : 'module-datalakev2'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    containerList:[
      'files-1-input'
      'files-2-split'
      'files-3-recognized'
      'samples'
    ]
    mid: userAssignedMid.outputs.midId
    location: location
    keyVaultName:keyVaultName
  }
}

module cosmosdb 'cosmos-db.bicep' = {
  name: 'module-cosmos-db'
  scope: resourceGroup
  params:{
    cosmosAccountName:cosmosAccountName
    cosmosDbName:cosmosDbName
    cosmosDbContainerName:cosmosDbContainerName
    location:location
    keyVaultName:keyVaultName
  }
}

module formrecognizer 'form-recognier.bicep' = {
  name:'module-formrecognizer'
  scope: resourceGroup
  params:{
    formRecognierName:formRecognierName
    location:location
    keyVaultName:keyVaultName
  }
}

module assignBlobContributorRoleToMid 'assign-blobcontributor.bicep' = {
  name: 'module-assignBlobContributorRoleToMid'
  scope: resourceGroup
  params:{
    storageAccountName:storageAccountName
    principalId:userAssignedMid.outputs.midPrincipleId
    principalType:'ServicePrincipal'
  }
}

module assignBlobContributorRoleToFR 'assign-blobcontributor.bicep' = {
  name: 'module-assignBlobContributorRoleToFR'
  scope: resourceGroup
  params:{
    storageAccountName:storageAccountName
    principalId:formrecognizer.outputs.formRecognizerPrincipalId
    principalType:'ServicePrincipal'
  }
}

output storageAccountName string = datalakev2.outputs.storageAccountName
output cosmosAccountName string =  cosmosdb.outputs.cosmosAccountName
