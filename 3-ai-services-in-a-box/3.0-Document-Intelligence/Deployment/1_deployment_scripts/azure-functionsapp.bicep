//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param midName string
param location string
param funAppStorageName string
param midClientId string
param azureFunctionsAppName string
@secure()
param paramFormRecognizerEndPoint string
@secure()
param paramFormRecognizerKey string

param keyVaultName string

var serverFarmName = '${azureFunctionsAppName}-ASP'
var appInsightsName = '${azureFunctionsAppName}-insight'

resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource funcAppStorage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: funAppStorageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}


// /************************************************************************/
// // Application Insights
// /************************************************************************/
resource azAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties:{
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// /************************************************************************/
// // Azure Functions App 
// /************************************************************************/
resource azureFunctionsApp 'Microsoft.Web/sites@2022-03-01' = {
  name: azureFunctionsAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${midName}': {
      }
    }
  }
  properties: {
    reserved: true
    clientAffinityEnabled: true
    httpsOnly: true
    serverFarmId: serverFarmNameResource.id
    siteConfig: {
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      linuxFxVersion: 'PYTHON|3.9'
      //linuxFxVersion: 'PYTHON|3.9.1' // This is the version with which code was developed. Recommended to use standard verion 3.9
      appSettings: [
        {
          name:'APPINSIGHTS_INSTRUMENTATIONKEY'
          value:azAppInsights.properties.InstrumentationKey
        }
        {
          name:'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value:azAppInsights.properties.ConnectionString
        }
        {
          name:'AzureWebJobsStorage'
          //value:'DefaultEndpointsProtocol=https;AccountName=${funAppStorageName};AccountKey=${listKeys(funAppStorageName, funcAppStorage.apiVersion).keys[0].value}'
          value:'DefaultEndpointsProtocol=https;AccountName=${funAppStorageName};AccountKey=${listKeys(funAppStorageName,'2021-04-01').keys[0].value}'
        }
       
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'python' }
        { name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE', value: 'true' }
        { name: 'AZURE_FORM_RECOGNIZER_ENDPOINT', value: paramFormRecognizerEndPoint }
        { name: 'AZURE_FORM_RECOGNIZER_KEY', value: paramFormRecognizerKey }
        { name: 'RG_MID_CLIENT_ID', value: midClientId }
        { name: 'CUSTOM_BUILT_MODEL_ID', value: 'Replace-with-Model-ID-Created-From-Form-Recognizer' }
        // { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
        // {
        //   name:'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        //   //value:'DefaultEndpointsProtocol=https;AccountName=${funAppStorageName};AccountKey=${listKeys(funAppStorageName,'2021-04-01').keys[0].value}'
        //   value:'DefaultEndpointsProtocol=https;AccountName=${funAppStorageName};AccountKey=${listKeys(funAppStorageName,funcAppStorage.apiVersion).keys[0].value}'
        // }
        // { name: 'WEBSITE_CONTENTSHARE', value:azureFunctionsAppName
        // }
      ]
    }
  }
  dependsOn: [
    funcAppStorage
  ]
}

// /************************************************************************/
// // Host 
// /************************************************************************/
resource serverFarmNameResource 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: serverFarmName
  location: location
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties:{
    reserved: true
  }
}

// /************************************************************************/
// // Save host key to key vault if you need to reconfigure the functions app
// /************************************************************************/
resource FunctionAppHostKeyToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'FunctionAppHostKey'
  parent: formKeyVault
  properties: {
    value: listKeys('${azureFunctionsApp.id}/host/default', azureFunctionsApp.apiVersion).functionKeys.default
  }
}


output serverFarmName string = serverFarmName
output appInsightsName string = appInsightsName



