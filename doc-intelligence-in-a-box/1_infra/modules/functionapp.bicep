/*region Header
      Module Steps 
      1 - Create Function App Storage Account
      2 - Create App Service Plan
      3 - Create Function App
      4 - Create App Insights
      5 - Save Function App Host Key to Key Vault
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param funcAppName string
param funAppStorageName string
param keyVaultName string
param uamiId string
param uamiClientId string
param modelName string = 'contoso-safety-forms'

var serverFarmName = '${funcAppName}-ASP'
var appInsightsName = '${funcAppName}-insight'

//Retrieve the name of the newly created key vault
resource kvRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts
//1. Create Function App Storage Account
resource r_funcAppStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: funAppStorageName
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms
//2. Create App Service Plan
resource serverFarmNameResource 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: serverFarmName
  location: resourceLocation
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites
//3. Create Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: funcAppName
  location: resourceLocation
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    reserved: true
    clientAffinityEnabled: true
    httpsOnly: true
    serverFarmId: serverFarmNameResource.id
    siteConfig: {
      ftpsState: 'FtpsOnly'
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: azAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: azAppInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funAppStorageName};AccountKey=${listKeys(funAppStorageName, '2021-04-01').keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
          value: 'true'
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_ENDPOINT'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=FormRecognizerEndPoint)'
        }
        {
          name: 'AZURE_FORM_RECOGNIZER_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=FormRecognizerKey)'
        }
        {
          name: 'RG_MID_CLIENT_ID'
          value: uamiClientId
        }
        {
          name: 'CUSTOM_BUILT_MODEL_ID'
          value: modelName
        }
      ]
      use32BitWorkerProcess: false
    }
  }
  dependsOn: [
    r_funcAppStorage
  ]
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components
//4. Create App Insights
resource azAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: resourceLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
//5. Save host key to key vault if you need to reconfigure the functions app
resource FunctionAppHostKeyToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'FunctionAppHostKey'
  parent: kvRef
  properties: {
    value: listKeys('${functionApp.id}/host/default', functionApp.apiVersion).functionKeys.default
  }
}

output serverFarmName string = serverFarmName
output funcAppName string = funcAppName
output funAppStorageName string = funAppStorageName
output appInsightsName string = appInsightsName
output principalId string = functionApp.identity.principalId
