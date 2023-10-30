/*region Header
      Module Steps 
      1 - Deploy Hub VNet
      2 - Deploy DNS Zones for most frequent services - OpenAI, Search, Cog Services and Blob Storage
      3 - Output back to main module the following params (hub ID, private DNS Zone IDs)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param prefix string
param tags object = {}
param existingHubName string = ''

//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var hubName = !empty(existingHubName) ? existingHubName : '${prefix}-hub-vnet-${uniqueSuffix}'
var hubCIDR = ['10.0.0.0/16']
var inboundDNSSubnetName = 'inbound-dns-subnet'
var inboundDNSCIDR = '10.0.0.0/28'

//Create Resources----------------------------------------------------------------------------------------------------------------------------

// 1. Hub VNet deployment
// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks

resource existingHub 'Microsoft.Network/virtualNetworks@2020-11-01' existing = if (!empty(existingHubName)) {
  name: hubName
  resource inboundDNSSubnet 'subnets' existing = {
    name: inboundDNSSubnetName
  }
}

resource hub 'Microsoft.Network/virtualNetworks@2020-11-01' = if (empty(existingHubName)) {
  name: hubName
  location: resourceLocation
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: hubCIDR
    }
    subnets: [
      {
        name: inboundDNSSubnetName
        properties: {
          addressPrefix: inboundDNSCIDR
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ]
  }
  resource inboundDNSSubnet 'subnets' existing = {
    name: inboundDNSSubnetName
  }
}

output hubID string = existingHub.id ?? hub.id
output dnsSubnetId string = existingHub::inboundDNSSubnet.id ?? hub::inboundDNSSubnet.id
