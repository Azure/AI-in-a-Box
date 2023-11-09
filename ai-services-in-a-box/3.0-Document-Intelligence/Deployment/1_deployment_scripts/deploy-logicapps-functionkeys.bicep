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
param keyVaultName string  
param resourceNamePrefix string 
param azureFunctionsAppName string

param midName string
param storageAccountName string
param cosmosAccountName string 
param logicAppOutlookName string
param logicAppFormProcName string


var outlookEmailId = ''         // empty string worked. api created. need manually authorize. 
var outlookEmailPassword = ''   // empty string worked. api created. need manually authorize. 
// API Connections
var adlsConnectionWithKey = '${resourceNamePrefix}ApiToAdlsWithKey'
var cosmosDbConnectionWithKey = '${resourceNamePrefix}ApiToCosmosDbWithKey'
var outlookConnectionName = '${resourceNamePrefix}ApiToOutlook'

//====================================================================================
// Reusing Resources already created
//====================================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope:subscription()
}

resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing= {
  name: keyVaultName
  scope:resourceGroup
}

resource userAssignedMid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: midName
  scope:resourceGroup
}

//====================================================================================
// Create Logic Apps with working API connections 
//====================================================================================
// Resources Created: 
//      API Connection to Outlook (need to authorize in Azure Portal w EmailId and Password) 
//      API Connection to Azure Data Lake (fully working, no additional  setup needed)
//      API Connection to Azure Cosmos DB (fully working, no additional  setup needed)
//      Azure Logic App - Outlook 
//           API to Azure Data Lake Fully Functioning 
//           After Authorize Outlook Email, the Logic App will work. Tested. 
//      Azure Logic App - Form Processing 
//           API to Azure Data Lake Fully Functioning 
//           API to Cosmos DB needs manual config 
//           Need to manually add SplitFile and RecognizeFile Function Keys
//=====================================================================================


//*************************************************************************************
// Create APIs for Logic APPs 
//*************************************************************************************

module apiAdls 'api-adls.bicep' = {
  name: 'module-apiAdls'
  scope: resourceGroup
  params: {
    location: location
    storageAccountName:storageAccountName
    adlsConnectionWithKey:adlsConnectionWithKey
    paramAdlsPrimaryKey:formKeyVault.getSecret('AdlsPrimaryKey')
  }
}

module apiCosmosDb 'api-cosmosdb.bicep' = {
  name: 'module-apiCosmosDb'
  scope: resourceGroup
  params: {
    location: location
    cosmosAccountName:cosmosAccountName
    cosmosDbConnectionWithKey:cosmosDbConnectionWithKey
    paramCosmosAccountKey:formKeyVault.getSecret('CosmosDbPrimaryKey')
  }
}

module apiOutlook 'api-outlook.bicep' = {
  name: 'module-apiOutlook'
  scope: resourceGroup
  params: {
    location: location
    outlookEmailId:outlookEmailId
    outlookEmailPassword:outlookEmailPassword
    outlookConnectionName:outlookConnectionName
  }
}

//*************************************************************************************
// Create Azure Logic Apps
// use the working API connection created above 
//*************************************************************************************

module logicAppOutlook'logicapp-outlook.bicep' = {
  name : 'module-logicAppOutlookName'
  scope: resourceGroup
  params: {
    logicAppOutlookName: logicAppOutlookName
    location:location
    mid:userAssignedMid.id
    storageAccountName:storageAccountName
    adlsConnectionName: adlsConnectionWithKey
    adlsConnectionId:apiAdls.outputs.adlsConnectionId
    outlookConnectionName:outlookConnectionName
    outlookConnectionId:apiOutlook.outputs.outlookConnectionId
  }
}


//*************************************************************************************
// Create form processing logic app that uses azure functions app's functions key
//*************************************************************************************
module logicAppFormProc'logicapp-formproc-functionkeys.bicep' = {
  name : 'module-logicAppFormProc'
  scope: resourceGroup
  params: {
    logicAppFormProcName: logicAppFormProcName
    azureFunctionsAppName:azureFunctionsAppName
    location:location
    mid:userAssignedMid.id
    storageAccountName:storageAccountName
    adlsConnectionName:adlsConnectionWithKey
    adlsConnectionId:apiAdls.outputs.adlsConnectionId
    cosmosDbConnectionName:cosmosDbConnectionWithKey
    cosmosDbConnectionId:apiCosmosDb.outputs.cosmosDbConnectionId
    FunctionRecognizeFileKey:listKeys('/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/sites/${azureFunctionsAppName}/functions/RecognizeFile','2022-03-01').default 
    FunctionSplitFileKey:listKeys('/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Web/sites/${azureFunctionsAppName}/functions/SplitFile','2022-03-01').default   
  }
}


output outlookConnection string = outlookConnectionName
