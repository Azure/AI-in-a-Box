/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Description:      AI-in-a-Box (AOAI) - Landing Zone
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Deploy Hub Vnet and Private DNS Zones
      2 - Deploy Spoke VNet and Spoke-To-Hub peering
      3 - Deploy Hub-to-Spoke peering
      4 - Deploy OpenAI Instance(s)
      5 - Deploy Cognitive Search
      6 - Deploy Document Intelligence
      7 - Deploy Storage Account
      8 - Deploy Cosmos DB
      9 - Apply necessary RBAC
*/

targetScope = 'subscription'

//********************************************************
// Global Parameters
//********************************************************
param location string
param environmentName string
param appName string

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

param coreNetworkResourceGroup string = ''
param spokeNetworkResourceGroup string = ''
param appResourceGroup string = ''

param hubName string = ''
param hubAddressPrefixes string[] = ['10.0.0.0/16']
param gatewaySubnetName string = 'GatewaySubnet'
param gatewaySubnetPrefix string = '10.0.0.0/27'
param firewallSubnetName string = 'AzureFirewallSubnet'
param firewallSubnetPrefix string = '10.0.1.0/26'
param dnsSubnetName string = 'DNSSubnet'
param dnsSubnetPrefix string = '10.0.2.0/26'

param dnsResolverName string = ''

param spokeName string = ''
param spokeAddressPrefixes string[] = ['10.1.0.0/16']
param privateEndpointSubnetName string = ''
param privateEndpointSubnetPrefix string = ''

param openaiAccountName string = ''
param docIntelName string = ''
param searchName string = ''
param storageName string = ''
param cosmosName string = ''

param deployDnsResolver bool = true
param deploySearch bool = true
param deployDocIntel bool = true
param deployCosmos bool = true

var abbrs = loadJsonContent('abbreviations.json')
var uniqueSuffix = substring(uniqueString(subscription().id, appRg.id), 1, 3) 

//********************************************************
// Resource Groups - Create your Resource Groups
//********************************************************
//https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/2022-09-01/resourcegroups?pivots=deployment-language-bicep
resource coreNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: !empty(coreNetworkResourceGroup) ? coreNetworkResourceGroup : '${abbrs.resourcesResourceGroups}nw-core-${environmentName}'
  location: location
  tags: coreNetworkingTags
}

resource spokeNetworkRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: !empty(spokeNetworkResourceGroup) ? spokeNetworkResourceGroup : '${abbrs.resourcesResourceGroups}nw-spoke-${environmentName}'
  location: location
  tags: spokeNetworkingTags
}

resource appRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: !empty(appResourceGroup) ? appResourceGroup : '${abbrs.resourcesResourceGroups}${appName}'
  location: location
  tags: projectTags
}

// 1. Deploy Hub Vnet and Private DNS Zones
module m_hub 'modules/hub.bicep' = {
  name: 'deploy_hub'
  scope: coreNetworkRG
  params: {
    location: location
    hubName: !empty(hubName) ? hubName : '${abbrs.networkVirtualNetworks}hub-${environmentName}'
    hubAddressPrefixes: hubAddressPrefixes
    gatewaySubnetName: gatewaySubnetName
    gatewaySubnetPrefix: gatewaySubnetPrefix
    firewallSubnetName: firewallSubnetName
    firewallSubnetPrefix: firewallSubnetPrefix
    dnsSubnetName: dnsSubnetName
    dnsSubnetPrefix: dnsSubnetPrefix
    tags: coreNetworkingTags
  }
}

module m_private_dns_resolver 'modules/privateDnsResolver.bicep' = if (deployDnsResolver) {
  name: 'deploy_private_dns_resolver'
  scope: coreNetworkRG
  params: {
    location: location
    dnsResolverName: !empty(dnsResolverName) ? dnsResolverName : '${abbrs.networkPrivateDnsResolvers}${environmentName}'
    vnetId: m_hub.outputs.hubID
    subnetId: m_hub.outputs.dnsSubnetId
    tags: coreNetworkingTags
  }
}

module m_private_dns_zones 'modules/privateDnsZone.bicep' = [for zone in deployDnsZones: {
  name: 'deploy_dns_${zone}'
  scope: coreNetworkRG
  params: {
    zone: zone
    hubId: m_hub.outputs.hubID
    tags: coreNetworkingTags
  }
}]

// 2. Deploy Spoke VNet and Spoke-To-Hub peering
module m_spoke 'modules/spoke.bicep' = {
  name: 'deploy_spoke'
  scope: spokeNetworkRG
  params: {
    location: location
    spokeName: !empty(spokeName) ? spokeName : '${abbrs.networkVirtualNetworks}spoke-${environmentName}'
    spokeAddressPrefixes: spokeAddressPrefixes
    privateEndpointSubnetName: !empty(privateEndpointSubnetName) ? privateEndpointSubnetName : 'PrivateEndpointsSubnet'
    privateEndpointSubnetPrefix: !empty(privateEndpointSubnetPrefix) ? privateEndpointSubnetPrefix : '10.1.0.0/24'
    dnsResolverInboundIp: m_private_dns_resolver.outputs.dnsResolverInboundIp
    tags: spokeNetworkingTags
  }
}

// 3. Deploy Hub-to-Spoke peering
module m_peer_hub_to_spoke 'modules/peering.bicep' = {
  name: 'deploy_peer_hub_to_spoke'
  scope: coreNetworkRG
  params: {
    from: m_hub.outputs.hubID
    to: m_spoke.outputs.spokeID
  }
}

module m_peer_spoke_to_hub 'modules/peering.bicep' = {
  name: 'deploy_peer_spoke_to_hub'
  scope: spokeNetworkRG
  params: {
    from: m_spoke.outputs.spokeID
    to: m_hub.outputs.hubID
  }
}

module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  scope: appRg
  params: {
    location: location
    openaiAccountName: !empty(openaiAccountName) ? openaiAccountName : '${abbrs.cognitiveServicesOpenAI}${appName}-${uniqueSuffix}'
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[0].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_docintel 'modules/documentIntelligence.bicep' = if (deployDocIntel) {
  name: 'deploy_docintel'
  scope: appRg
  params: {
    location: location
    docIntelName: !empty(docIntelName) ? docIntelName : '${abbrs.cognitiveServicesFormRecognizer}${appName}-${uniqueSuffix}'
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[2].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_search 'modules/searchService.bicep' = if (deploySearch) {
  name: 'deploy_search'
  scope: appRg
  params: {
    location: location
    searchName: !empty(searchName) ? searchName : '${abbrs.searchSearchServices}${appName}-${uniqueSuffix}'
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[1].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_storage 'modules/storageaccount.bicep' = {
  name: 'deploy_storage'
  scope: appRg
  params: {
    location: location
    storageName: !empty(storageName) ? storageName : '${abbrs.storageStorageAccounts}${replace(appName, '-', '')}${uniqueSuffix}'
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[3].outputs.privateDnsZoneId
    tags: projectTags
  }
}

module m_cosmos 'modules/cosmos.bicep' = if (deployCosmos) {
  name: 'deploy_cosmos'
  scope: appRg
  params: {
    location: location
    cosmosName: !empty(cosmosName) ? cosmosName : '${abbrs.documentDBDatabaseAccounts}${appName}-${uniqueSuffix}'
    subnetID: m_spoke.outputs.privateEndpointsSubnetID
    privateDnsZoneId: m_private_dns_zones[4].outputs.privateDnsZoneId
    tags: projectTags
  }
}
