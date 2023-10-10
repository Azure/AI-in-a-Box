@description('Specifies the name of the deployment.')
param name string
@description('Specifies the name of the environment.')
param environment string
@description('Specifies the location of the Azure Machine Learning workspace and dependent resources.')
param location string = resourceGroup().location
@description('Specifies whether to reduce telemetry collection and enable additional encryption.')
param hbi_workspace bool = false


var tenantId = subscription().tenantId
var storageAccountName_var = 'st${name}${environment}'
var keyVaultName_var = 'kv-${name}-${environment}'
var applicationInsightsName_var = 'appi-${name}-${environment}'

var workspaceName_var = 'mlw${name}${environment}'


var storageAccount = storageAccountName.id
var keyVault = keyVaultName.id
var applicationInsights = applicationInsightsName.id


resource storageAccountName 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName_var
  location: location
  sku: {
      name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource applicationInsightsName 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName_var
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource keyVaultName 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName_var
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enableSoftDelete: true
  }
}

resource workspaceName 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  name: workspaceName_var
  location: location
  properties: {
    friendlyName: workspaceName_var
    storageAccount: storageAccount
    keyVault: keyVault
    applicationInsights: applicationInsights
    hbiWorkspace: hbi_workspace
  }
  dependsOn: [
    storageAccountName
    keyVaultName
    applicationInsightsName
  ]
}