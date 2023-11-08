//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================
//targetScope = 'subscription'
targetScope = 'resourceGroup'

param location string  
param resourceGroupName string  
param keyVaultName  string  

param midName string
param azureFunctionsAppName string

var funAppStorageName = '${azureFunctionsAppName}storage'


//====================================================================================
// Resource Group and KeyVault Policy Set up 
//      Azure Functions App (Infrastructure only) with below resources 
//           Hosting Plan
//           Azure Functions App
//      Azure Functions Code ---- This needs to be manually deployed from VSD
//====================================================================================

// Resource Group already created
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope:subscription()
}

//====================================================================================
// Create Azure Functions and ASP 
// After creation, there is another step to deploy code to the Azure Functions 
//====================================================================================

resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope:resourceGroup
}


resource userAssignedMid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: midName
  scope:resourceGroup
}


module azureFunctionsApp 'azure-functionsapp.bicep' = {
  name: 'module-azure-functionsapp'
  scope: resourceGroup
  params:{
    midName:midName
    location:location
    funAppStorageName:funAppStorageName
    midClientId:userAssignedMid.properties.clientId
    azureFunctionsAppName:azureFunctionsAppName
    paramFormRecognizerEndPoint:formKeyVault.getSecret('FormRecognizerEndPoint')
    paramFormRecognizerKey:formKeyVault.getSecret('FormRecognizerKey')
    keyVaultName:keyVaultName
  }
}

// output from this module 
output azureFunctionsAppName string = azureFunctionsAppName
output funAppStorageName string = funAppStorageName
// output from the called module
output serverFarmName string = azureFunctionsApp.outputs.serverFarmName
output appInsightsName string = azureFunctionsApp.outputs.appInsightsName

