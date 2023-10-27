/*region Header
      Module Steps 
      1 - Deploy Hub VNet
      2 - Deploy DNS Zones for most frequent services - OpenAI, Search, Cog Services and Blob Storage
      3 - Output back to main module the following params (hub ID, private DNS Zone IDs)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param zone string
param hubId string
param tags object = {}


//Create Resources----------------------------------------------------------------------------------------------------------------------------

// 2. Private DNS Zones
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zone
  location: 'global'
  tags: tags
  properties: {}
}


// 3. Virtual Network Links - Allows Hub Vnet to resolve Private DNS Zones
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones/virtualnetworklinks
resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubId
    }
  }
}


output privateDnsZoneId string = privateDnsZone.id
