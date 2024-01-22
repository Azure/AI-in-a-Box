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

@description('Specifies the name of the resource group where Azure ML must be created.')
param resourceGroupName string

@description('URL of the GitHub repository containing the Azure Function deployment zip file.')
param gitHub_FunctionDeploymentZip string

@description('Specifies the name of the GitHub repository owner.')
param gitHub_repoOwnerName string

@description('Specifies the name of the GitHub repository.')
param gitHub_repoName string

// You can use the github cli command: "gh workflow list" to get the workflow_id
// Example:
// "https://api.github.com/repos/Welasco/test/actions/workflows/74415295/dispatches"
@description('Specifies the workflowid of the GitHub Actions.')
param gitHub_workflowId string

@description('Specifies the GitHub Personal Access Token (PAT).')
param gitHub_PAT string

// @description('Specifies the name of the deployment.')
// param deploymentName string = 'aibox'
// @description('Specifies the name of the environment.')
// param environment string = 'dev'

@description('Specifies the name of the Azure Machine Learning workspace Name.')
param amlworkspace string

@description('Specifies the name of the Azure Machine Learning workspace Compute Name.')
param amlcomputename string = 'aml-cluster'

@description('Specifies the name of the Azure Machine Learning workspace Deployment Name.')
param aml_flow_deployment_name string

@description('Specifies the name of the Azure Machine Learning workspace Endpoint Name.')
param aml_endpoint_name string

@description('Specifies the name of the Azure Machine Learning workspace Model Name.')
param aml_model_name string

@description('Specifies whether to reduce telemetry collection and enable additional encryption.')
param hbi_workspace bool = false

//********************************************************
// Resource Config Parameters
//********************************************************
var tenantId = subscription().tenantId
var storageAccountName = 'stg${prefix}${uniqueSuffix}'
var applicationInsightsName = 'appi-${prefix}${uniqueSuffix}'
var keyVaultName = 'kv-${prefix}${uniqueSuffix}'

//var workspaceName = 'aml${prefix}${uniqueSuffix}'
var workspaceName = amlworkspace

//********************************************************
// Deploy Core Platform Services
//********************************************************

//1. Deploy Required Storage Account(s)
//Deploy Storage Accounts (Create your Storage Account (ADLS Gen2 & HNS Enabled) for your ML Workspace)
//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?tabs=bicep
module stg './modules/storage.bicep' = {
  name: storageAccountName
  params: {
    storageAccountName: storageAccountName
    resourceLocation: resourceLocation
  }
}

//2. Deploy Azure Function App (Used to handle Azure Alerts and Invoke GitHub Actions)
// https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=bicep
module functionApp './modules/functionApp.bicep' = {
  name: 'func-${amlworkspace}'
  params: {
    location: resourceLocation
    aml_endpoint_name: aml_endpoint_name
    aml_flow_deployment_name: aml_flow_deployment_name
    aml_model_name: aml_model_name
    aml_workspace: amlworkspace
    existingStorageAccountName: stg.name
    functionname: 'func-${amlworkspace}'
    gitHub_FunctionDeploymentZip: gitHub_FunctionDeploymentZip
    gitHub_PAT: gitHub_PAT
    gitHub_repoName: gitHub_repoName
    gitHub_repoOwnerName: gitHub_repoOwnerName
    gitHub_workflowId: gitHub_workflowId
    resource_group: resourceGroupName
  }
}

//3. Deploy Application Insights Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep
module aisn './modules/insights.bicep' = {
  name: applicationInsightsName
  params: {
    resourceLocation: resourceLocation
    applicationInsightsName: applicationInsightsName
  }
}

//4. Deploy Required Key Vault
//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
module kvn './modules/keyvault.bicep' = {
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName
    resourceLocation: resourceLocation
    tenantId: tenantId
  }
}

//5. Deploy Machine Learning Workspace
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
module amlwn './modules/azureml.bicep' = {
  name: workspaceName
  params: {
    resourceLocation: resourceLocation
    aisnId: aisn.outputs.applicationInsightId
    amlcomputename: amlcomputename
    keyvaultId: kvn.outputs.keyVaultId
    storageAccountId: stg.outputs.stgId
    workspaceName: workspaceName
    hbi_workspace: hbi_workspace
  }
}

//6. Deploy Action Group
//https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/actiongroups
module ag './modules/action_group.bicep' = {
  name: 'ag-${amlworkspace}'
  params: {
    actiongroupname: 'ag-${amlworkspace}'
    functionappname: 'func-${amlworkspace}'
    functionappresourceid: functionApp.outputs.functionAppId
    groupshortname: length('ag-${amlworkspace}') <= 12 ? 'ag-${amlworkspace}' : take('ag-${amlworkspace}', 12)
    httpTriggerUrl: functionApp.outputs.functionAppUrl
    resourceLocation: 'global'
  }
}

//7. Deploy Azure Monitor Alert
//https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/metricalerts
module amljobalert './modules/azureml_job_alert.bicep' = {
  name: 'amljobalert-${amlworkspace}'
  params: {
    actionGroupId: ag.outputs.agGroupId
    alertrulename: 'alertjob-${amlworkspace}'
    azuremlworkspaceId: amlwn.outputs.azuremlworkspaceId
    azuremltargetResourceRegion: resourceLocation
    location: 'global'
  }
}
