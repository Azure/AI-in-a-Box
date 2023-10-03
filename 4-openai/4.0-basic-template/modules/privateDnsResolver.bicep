/*region Header
      Module Steps 
      1 - Deploy Hub VNet
      2 - Deploy DNS Zones for most frequent services - OpenAI, Search, Cog Services and Blob Storage
      3 - Output back to main module the following params (hub ID, private DNS Zone IDs)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param vnetId string
param subnetId string
param prefix string
param tags object = {}

//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var resolverName = '${prefix}-resolver-${uniqueSuffix}'

//Create Resources----------------------------------------------------------------------------------------------------------------------------
resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: resolverName
  location: resourceLocation
  tags: tags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
  }
  resource inEndpoint 'inboundEndpoints' = {
    name: 'inbound-endpoint'
    location: resourceLocation
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




output dnsIp string = resolver::inEndpoint.properties.ipConfigurations[0].privateIpAddress
