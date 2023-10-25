/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       10/04/2023
      Description:      Pattern 4: AI-in-a-Box (AOAI) - Landing Zone
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

param deployDnsZones array = [
  'privatelink.openai.azure.com'
  'privatelink.search.azure.com'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.documents.azure.com'
]

param coreNetworkResourceGroup string
param spokeNetworkResourceGroup string
param appResourceGroup string

param existingHubName string
param existingSpokeName string
param existingPrivateEndpointSubnet string

param deployDnsResolver bool
param deploySearch bool
param deployDocIntel bool
param deployCosmos bool

//----------------------------------------------------------------------

//********************************************************
// Variables
//********************************************************

//********************************************************
// Resource Groups - Create your Resource Groups
//********************************************************
//https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
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

module m_private_dns_resolver 'modules/privateDnsResolver.bicep' = if (deployDnsResolver) {
  name: 'deploy_private_dns_resolver'
  scope: resourceGroup(coreNetworkResourceGroup)
  dependsOn: [
    coreNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    vnetId: m_hub.outputs.hubID
    subnetId: m_hub.outputs.dnsSubnetId
    tags: coreNetworkingTags
  }
}

module m_private_dns_zones 'modules/privateDnsZone.bicep' = [for zone in deployDnsZones: {
  name: 'deploy_dns_${zone}'
  scope: resourceGroup(coreNetworkResourceGroup)
  dependsOn: [
    coreNetworkRG
  ]
  params: {
    zone: zone
    hubId: m_hub.outputs.hubID
    tags: coreNetworkingTags
  }
}]

// 2. Deploy Spoke VNet and Spoke-To-Hub peering
module m_spoke 'modules/spoke.bicep' = {
  name: 'deploy_spoke'
  scope: resourceGroup(spokeNetworkResourceGroup)
  dependsOn: [
    m_hub, spokeNetworkRG
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    existingSpokeName: existingSpokeName
    existingPrivateEndpointSubnetName: existingPrivateEndpointSubnet
    dnsIp: m_private_dns_resolver.outputs.dnsIp
    tags: spokeNetworkingTags
  }
}

// 3. Deploy Hub-to-Spoke peering
module m_peer_hub_to_spoke 'modules/peering.bicep' = {
  name: 'deploy_peer_hub_to_spoke'
  scope: resourceGroup(coreNetworkResourceGroup)
  params: {
    from: m_hub.outputs.hubID
    to: m_spoke.outputs.spokeID
  }
}

module m_peer_spoke_to_hub 'modules/peering.bicep' = {
  name: 'deploy_peer_spoke_to_hub'
  scope: resourceGroup(spokeNetworkResourceGroup)
  params: {
    from: m_spoke.outputs.spokeID
    to: m_hub.outputs.hubID
  }
}

module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  scope: resourceGroup(appResourceGroup)
  dependsOn: [
    appRg
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[0].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_search 'modules/searchService.bicep' = if (deploySearch) {
  name: 'deploy_search'
  scope: resourceGroup(appResourceGroup)
  dependsOn: [
    appRg
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[1].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_docintel 'modules/documentIntelligence.bicep' = if (deployDocIntel) {
  name: 'deploy_docintel'
  scope: resourceGroup(appResourceGroup)
  dependsOn: [
    appRg
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[2].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_storage 'modules/storageaccount.bicep' = {
  name: 'deploy_storage'
  scope: resourceGroup(appResourceGroup)
  dependsOn: [
    appRg
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[3].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_cosmos 'modules/cosmos.bicep' = if (deployCosmos) {
  name: 'deploy_cosmos'
  scope: resourceGroup(appResourceGroup)
  dependsOn: [
    appRg
  ]
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[4].outputs.privateDnsZoneId
    tags: projectTags
  }
}

//********************************************************
// RBAC Role Assignments
//********************************************************

//********************************************************
// Post Deployment Scripts
//********************************************************
