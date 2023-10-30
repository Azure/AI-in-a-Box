@description('Specifies the name of the deployment.')
param name string
@description('Specifies the name of the environment.')
param environment string
@description('Specifies the name of the Azure Machine Learning workspace Name.')
param amlworkspace string
@description('Specifies the location of the Azure Machine Learning workspace and dependent resources.')
param location string = resourceGroup().location
param amlcomputename string = 'aml-cluster'
@description('Specifies whether to reduce telemetry collection and enable additional encryption.')
param hbi_workspace bool = false


var tenantId = subscription().tenantId
var storageAccountName = 'st${name}${environment}${uniqueString(resourceGroup().id)}'
var keyVaultName = 'kv-${name}-${environment}${uniqueString(resourceGroup().id)}'
var applicationInsightsName = 'appi-${name}-${environment}'

//var workspaceName = 'mlw${name}${environment}'
var workspaceName = amlworkspace

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
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

resource aisn 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource kvn 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
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

resource amlwn 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  name: workspaceName
  location: location
  properties: {
    friendlyName: workspaceName
    storageAccount: stg.id
    keyVault: kvn.id
    applicationInsights: aisn.id
    hbiWorkspace: hbi_workspace
  }
}

resource amlwcompute 'Microsoft.MachineLearningServices/workspaces/computes@2023-06-01-preview' = {
  parent: amlwn
  name: amlcomputename
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 1
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
      vmPriority: 'Dedicated'
      vmSize: 'Standard_DS3_v2'
    }
  }
}
