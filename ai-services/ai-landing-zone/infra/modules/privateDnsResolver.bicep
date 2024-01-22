/*region Header
      Module Steps 
      1 - Deploy Hub VNet
      2 - Deploy DNS Zones for most frequent services - OpenAI, Search, Cog Services and Blob Storage
      3 - Output back to main module the following params (hub ID, private DNS Zone IDs)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param dnsResolverName string
param vnetId string
param subnetId string
param tags object = {}


//Create Resources----------------------------------------------------------------------------------------------------------------------------
resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnsResolverName
  location: location
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
  }
  resource inEndpoint 'inboundEndpoints' = {
    name: 'inbound-endpoint'
    location: location
    tags: tags
    properties: {
      ipConfigurations: [
        {
          privateIpAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      ]
    }
  }
}


output dnsResolverInboundIp string = resolver::inEndpoint.properties.ipConfigurations[0].privateIpAddress
