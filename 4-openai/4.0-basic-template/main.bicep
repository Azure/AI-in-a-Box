/*region Header
      =========================================================================================================
      Created by:       Author: Marco Cardoso | macardoso@microsoft.com 
      Created on:       09/13/2023
      Description:      Pattern 4 OpenAI
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Create or connect to VNet and subnet for Private Endpoints
      2 - Create OpenAI instance
      3 - Create Cognitive Search
      4 - Create Storage Account
      5 - Create Private Endpoints for all services
      6 - Apply necessary RBAC
      7 - Create OpenAI Deployments
*/

targetScope = 'subscription'

//********************************************************
// Workload Deployment Control Parameters
//********************************************************
param ctrlDeployCognitiveSearch bool = true         // Controls whether to create a Cognitive Search instance

//********************************************************
// Global Parameters
//********************************************************
@description('Unique Prefix')
param prefix string = 'aitoolkit'

@description('Resource Location')
param resourceLocation string

//********************************************************
// Resource Config Parameters
//********************************************************
param coreNetworkingTags object
param spokeNetworkingTags object
param projectTags object

param hubCIDR array
param spokeCIDR array
param hubName string
param spokeName string

param coreNetworkResourceGroup string
param spokeNetworkResourceGroup string
param aiResourceGroup string

//----------------------------------------------------------------------


//********************************************************
// Variables
//********************************************************
var openaiAccountName = '${prefix}openai'
var storageAccountName = '${prefix}stg'
var searchAccountName = '${prefix}search'
var docIntelAccountName = '${prefix}docIntel'

resource coreNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: coreNetworkResourceGroup
  location: resourceLocation
}

resource spokeNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: spokeNetworkResourceGroup
  location: resourceLocation
}

resource aiRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: aiResourceGroup
  location: resourceLocation
}

// 1. Deploy Hub Vnet and Private DNS Zones
module m_hub 'modules/deploy_1_hub.bicep' = {
  name: 'deploy_hub'
  scope: resourceGroup(coreNetworkResourceGroup)
  dependsOn: [
    coreNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    hubCIDR: hubCIDR
    hubName: hubName
    tags: coreNetworkingTags
  }
}

// 2. Deploy Spoke VNet and Spoke-To-Hub peering
module m_spoke 'modules/deploy_2_spoke.bicep' = {
  name: 'deploy_spoke'
  scope: resourceGroup(spokeNetworkResourceGroup)
  dependsOn: [
    m_hub, spokeNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    spokeCIDR: spokeCIDR
    spokeName: spokeName
    defaultSubnetName: 'default'
    hubID: m_hub.outputs.hubID
    tags: spokeNetworkingTags
  }
}

// 3. Deploy Hub-to-Spoke peering
module m_peerings 'modules/deploy_3_peering.bicep' = {
  name: 'deploy_peering'
  scope: resourceGroup(coreNetworkResourceGroup)
  dependsOn: [
    m_hub, m_spoke
  ]
  params: {
    hubName: hubName
    spokeID: m_spoke.outputs.spokeID
  }
}

// 4. Deploy AI Services
module m_ai_services 'modules/deploy_4_ai_services.bicep' = {
  name: 'deploy_ai_services'
  scope: resourceGroup(aiResourceGroup)
  dependsOn: [
    aiRG
  ]
  params: {
    resourceLocation: resourceLocation
    openaiAccountName: openaiAccountName
    searchAccountName: searchAccountName
    docIntelAccountName: docIntelAccountName
    storageAccountName: storageAccountName
    tags: projectTags
  }
}


// 6. Deploy private endpoints for all services
module m_private_endpoints 'modules/deploy_5_private_endpoints.bicep' = {
  name: 'deploy_private_endpoints'
  scope: resourceGroup(spokeNetworkResourceGroup)
  dependsOn: [
    coreNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    subnetID: m_spoke.outputs.subnetID
    openaiAccountID: m_ai_services.outputs.openaiAccountID
    searchAccountID: m_ai_services.outputs.searchAccountID
    docIntelAccountID: m_ai_services.outputs.docIntelAccountID
    storageAccountID: m_ai_services.outputs.storageAccountID
    openaiPrivateDnsZoneID: m_hub.outputs.openaiPrivateDnsZoneId
    searchPrivateDnsZoneID: m_hub.outputs.searchPrivateDnsZoneId
    cogServicesPrivateDnsZoneID: m_hub.outputs.cogServicesPrivateDnsZoneId
    storagePrivateDnsZoneID: m_hub.outputs.storagePrivateDnsZoneId
    tags: spokeNetworkingTags
  }
}

//********************************************************
// RBAC Role Assignments
//********************************************************


//********************************************************
// Post Deployment Scripts
//********************************************************

