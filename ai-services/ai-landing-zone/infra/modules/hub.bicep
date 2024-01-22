/*region Header
      Module Steps 
      1 - Deploy Hub VNet
      2 - Deploy DNS Zones for most frequent services - OpenAI, Search, Cog Services and Blob Storage
      3 - Output back to main module the following params (hub ID, private DNS Zone IDs)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param tags object = {}
param hubName string
param hubAddressPrefixes string[]
param gatewaySubnetName string
param gatewaySubnetPrefix string
param firewallSubnetName string
param firewallSubnetPrefix string
param dnsSubnetName string
param dnsSubnetPrefix string

resource hub 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: hubName
  location: location
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: hubAddressPrefixes
    }
    subnets: [
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: dnsSubnetName
        properties: {
          addressPrefix: dnsSubnetPrefix
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
  resource gatewaySubnet 'subnets' existing = {
    name: gatewaySubnetName
  }
  resource firewallSubnet 'subnets' existing = {
    name: firewallSubnetName
  }
  resource dnsSubnet 'subnets' existing = {
    name: dnsSubnetName
  }
}

output hubID string = hub.id
output gatewaySubnetId string = hub::gatewaySubnet.id
output firewallSubnetId string = hub::firewallSubnet.id
output dnsSubnetId string = hub::dnsSubnet.id
