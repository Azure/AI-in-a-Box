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
param utcValue string = utcNow()

@description('Unique Prefix')
param prefix string = 'aitoolkit'

@description('Resource Location')
param resourceLocation string

param env string = 'Dev'

param tags object = {
  Owner: 'aitoolkit'
  Project: 'aitoolkit'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}

param hubCIDR array
param spokeCIDR array
param hubName string
param spokeName string

param coreNetworkResourceGroup string
param spokeNetworkResourceGroup string
param aiResourceGroup string
param storageResourceGroup string

//********************************************************
// Resource Config Parameters
//********************************************************

//Storage Account Module Parameters - Data Lake Storage Account for Synapse Workspace
@description('Storage Account Type')
param storageAccountType string

//----------------------------------------------------------------------


//********************************************************
// Variables
//********************************************************
var vNetSubnetName = '${prefix}subnet'
var openaiAccountName = '${prefix}openai'
var storageAccountName = '${prefix}stg'
var searchAccountName = '${prefix}search'
var docIntelAccountName = '${prefix}docIntel'

var coreNetworkResourceGroupFull = '${prefix}-${coreNetworkResourceGroup}'
var spokeNetworkResourceGroupFull = '${prefix}-${spokeNetworkResourceGroup}'
var aiResourceGroupFull = '${prefix}-${aiResourceGroup}'
var storageResourceGroupFull = '${prefix}-${storageResourceGroup}'

resource coreNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: coreNetworkResourceGroupFull
  location: resourceLocation
}

resource spokeNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: spokeNetworkResourceGroupFull
  location: resourceLocation
}

resource aiRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: aiResourceGroupFull
  location: resourceLocation
}

resource storageRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: storageResourceGroupFull
  location: resourceLocation
}

//********************************************************
// Deploy Core Platform Services 
//********************************************************
module m_hub 'modules/deploy_0_hub.bicep' = {
  name: 'deploy_hub'
  scope: resourceGroup(coreNetworkResourceGroupFull)
  dependsOn: [
    spokeNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    hubCIDR: hubCIDR
    hubName: hubName
  }
}

module m_spoke 'modules/deploy_1_spoke.bicep' = {
  name: 'deploy_spoke'
  scope: resourceGroup(spokeNetworkResourceGroupFull)
  dependsOn: [
    spokeNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    coreRG: coreNetworkResourceGroupFull
    spokeCIDR: spokeCIDR
    spokeName: spokeName
    defaultSubnetName: 'default'
    hubName: hubName
  }
}

module m_peerings 'modules/deploy_2_peering.bicep' = {
  name: 'deploy_peering'
  scope: resourceGroup(coreNetworkResourceGroupFull)
  dependsOn: [
    m_hub, m_spoke
  ]
  params: {
    hubName: hubName
    spokeID: m_spoke.outputs.spokeID
  }
}


module m_ai_services 'modules/deploy_3_ai_services.bicep' = {
  name: 'deploy_ai_services'
  scope: resourceGroup(aiResourceGroupFull)
  dependsOn: [
    aiRG
  ]
  params: {
    resourceLocation: resourceLocation
    openaiAccountName: openaiAccountName
    searchAccountName: searchAccountName
    docIntelAccountName: docIntelAccountName
  }
}


module m_storage 'modules/deploy_4_storage.bicep' = {
  name: 'deploy_storage'
  scope: resourceGroup(storageResourceGroupFull)
  dependsOn: [
    storageRG
  ]
  params: {
    resourceLocation: resourceLocation
    storageAccountName: storageAccountName
  }
}

module m_private_endpoints 'modules/deploy_5_private_endpoints.bicep' = {
  name: 'deploy_dns'
  scope: resourceGroup(spokeNetworkResourceGroupFull)
  dependsOn: [
    coreNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    subnetID: m_spoke.outputs.subnetID
    openaiAccountID: m_ai_services.outputs.openaiAccountID
    searchAccountID: m_ai_services.outputs.searchAccountID
    docIntelAccountID: m_ai_services.outputs.docIntelAccountID
    storageAccountID: m_storage.outputs.storageAccountID
    openaiAccountName: openaiAccountName
    searchAccountName: searchAccountName
    docIntelAccountName: docIntelAccountName
    storageAccountName: storageAccountName
    openaiPrivateDnsZoneID: m_hub.outputs.openaiPrivateDnsZoneId
    searchPrivateDnsZoneID: m_hub.outputs.searchPrivateDnsZoneId
    cogServicesPrivateDnsZoneID: m_hub.outputs.cogServicesPrivateDnsZoneId
    storagePrivateDnsZoneID: m_hub.outputs.storagePrivateDnsZoneId
  }
}

// module m_dns 'modules/deploy_6_dns.bicep' = {
//   name: 'deploy_dns'
//   scope: resourceGroup(coreNetworkResourceGroupFull)
//   dependsOn: [
//     coreNetworkRG
//   ]
//   params: {
//     vnetID: m_spoke.outputs.vNetID
//     subnetID: m_spoke.outputs.subnetID
//     spokeRG: spokeNetworkResourceGroupFull
//     openaiPrivateEndpointName: m_private_endpoints.outputs.openaiPrivateEndpointName
//     storagePrivateEndpointName: m_private_endpoints.outputs.storagePrivateEndpointName
//     searchPrivateEndpointName: m_private_endpoints.outputs.searchPrivateEndpointName
//     tags: tags
//   }
// }

//********************************************************
// RBAC Role Assignments
//********************************************************


//********************************************************
// Post Deployment Scripts
//********************************************************

