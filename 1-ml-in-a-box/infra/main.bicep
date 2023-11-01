/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       11/30/2023
      Description:      Pattern 4: AI-in-a-Box (ML) - MLOPs
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Create Storage Accounts
      2 - Create Application Insights
      3 - Create Key Vault
      4 - Create ML Workspace
      5 - Create ML Workspace Compute
*/

//********************************************************
// Global Parameters
//********************************************************
@description('Unique Prefix')
param prefix string = 'aibox'

@description('Unique Suffix')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id),0,3)

@description('Specifies the location of the Azure Machine Learning workspace and dependent resources.')
param resourceLocation string = resourceGroup().location

// @description('Specifies the name of the deployment.')
// param deploymentName string = 'aibox'   
// @description('Specifies the name of the environment.')
// param environment string = 'dev'

@description('Specifies the name of the Azure Machine Learning workspace Name.')
param amlworkspace string
param amlcomputename string = 'aml-cluster'
@description('Specifies whether to reduce telemetry collection and enable additional encryption.')
param hbi_workspace bool = false

//********************************************************
// Resource Config Parameters
//********************************************************
var tenantId = subscription().tenantId
var storageAccountName = 'stg${prefix}${uniqueSuffix}'
var applicationInsightsName = 'appi-${prefix}${uniqueSuffix}'
var keyVaultName = 'kv-${prefix}${uniqueSuffix}'

//var workspaceName = 'mlw${name}${environment}'
var workspaceName = amlworkspace

//********************************************************
// Deploy Core Platform Services 
//********************************************************

//1. Deploy Required Storage Account(s)
//Deploy Storage Accounts (Create your Storage Account (ADLS Gen2 & HNS Enabled) for your ML Workspace)
//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?tabs=bicep
resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: resourceLocation
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

//2. Deploy Application Insights Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep
resource aisn 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: (((resourceLocation == 'eastus2') || (resourceLocation == 'westcentralus')) ? 'southcentralus' : resourceLocation)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

//3. Deploy Required Key Vault
//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
resource kvn 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: resourceLocation
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

//4. Deploy Machine Learning Workspace
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
resource amlwn 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  name: workspaceName
  location: resourceLocation
  properties: {
    friendlyName: workspaceName
    storageAccount: stg.id
    keyVault: kvn.id
    applicationInsights: aisn.id
    hbiWorkspace: hbi_workspace
  }
}

//5. Deploy ML Workspace Compute Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces/computes?pivots=deployment-language-bicep
resource amlwcompute 'Microsoft.MachineLearningServices/workspaces/computes@2023-06-01-preview' = {
  parent: amlwn
  name: amlcomputename
  location: resourceLocation
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
