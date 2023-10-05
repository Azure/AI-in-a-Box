/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       10/04/2023
      Description:      Pattern 3 Azure AI Services - Document Intelligence
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Create or connect to VNet and subnet for Private Endpoints
      2 - Create Azure Applied AI Services In instance
      3 - Create Document Intelligence Service
      4 - Create Storage Account
      5 - Create Private Endpoints for all services
      6 - Apply necessary RBAC
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

//********************************************************
// Resource Config Parameters
//********************************************************
param coreNetworkingTags object
param spokeNetworkingTags object
param projectTags object

param coreNetworkResourceGroup string
param spokeNetworkResourceGroup string
param appResourceGroup string


param existingHubName string
//----------------------------------------------------------------------

//********************************************************
// Variables
//********************************************************

//********************************************************
// Resource Groups
//********************************************************
resource coreNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: coreNetworkResourceGroup
  location: resourceLocation
  tags: coreNetworkingTags
}

resource spokeNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: spokeNetworkResourceGroup
  location: resourceLocation
  tags: spokeNetworkingTags
}

resource appRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: appResourceGroup
  location: resourceLocation
  tags: projectTags
}

// 1. Deploy Hub Vnet and Private DNS Zones

// 1. Deploy Hub Vnet and Private DNS Zones
module m_hub 'modules/hub.bicep' = {
  name: 'deploy_hub'
  scope: resourceGroup(coreNetworkResourceGroup)
  dependsOn: [
    coreNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    existingHubName: existingHubName
    tags: coreNetworkingTags
  }
}

// 2. Deploy Spoke VNet and Spoke-To-Hub peering

// 3. Deploy Hub-to-Spoke peering


//********************************************************
// RBAC Role Assignments
//********************************************************

//********************************************************
// Post Deployment Scripts
//********************************************************
