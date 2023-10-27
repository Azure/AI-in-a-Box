/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       10/04/2023
      Description:      Pattern 4 OpenAI
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - 
*/

targetScope = 'subscription'

//********************************************************
// Workload Deployment Control Parameters
//********************************************************

//********************************************************
// Global Parameters
//********************************************************
param resourceLocation string
param prefix string
param msaAppId string
@secure()
param msaAppPassword string
param tags object


param spokeNetworkResourceGroup string
param appResourceGroup string

//----------------------------------------------------------------------

//********************************************************
// Variables
//********************************************************
var uniqueSuffix = substring(uniqueString(subscription().id, appRg.id), 1, 3) 
var openaiAccountName = '${prefix}-openai-${uniqueSuffix}'
var searchAccountName = '${prefix}-search-${uniqueSuffix}'
var cosmosAccountName = '${prefix}-cosmos-${uniqueSuffix}'


resource appRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: appResourceGroup
}

module m_appsubnet 'modules/appsubnet.bicep' = {
  name: 'deploy_app_subnet'
  scope: resourceGroup(spokeNetworkResourceGroup)
  params: {
    prefix: prefix
  }
}

module m_app 'modules/appservice.bicep' = {
  name: 'deploy_app'
  scope: resourceGroup(appResourceGroup)
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
    appSubnetId: m_appsubnet.outputs.appSubnetId
    msaAppId: msaAppId
    msaAppPassword: msaAppPassword
    openaiAccountName: openaiAccountName
  }
}

module m_bot 'modules/botservice.bicep' = {
  name: 'deploy_bot'
  scope: resourceGroup(appResourceGroup)
  params: {
    resourceLocation: 'global'
    prefix: prefix
    tags: tags
    endpoint: 'https://${m_app.outputs.hostName}/api/messages'
    msaAppId: msaAppId
  }
}


//********************************************************
// RBAC Role Assignments
//********************************************************

module m_rbac 'modules/rbac.bicep' = {
  name: 'deploy_rbac'
  scope: resourceGroup(appResourceGroup)
  params: {
    prefix: prefix
    openaiAccountName: openaiAccountName
    searchAccountName: searchAccountName
    cosmosAccountName: cosmosAccountName
  }
}

//********************************************************
// Post Deployment Scripts
//********************************************************
