/*region Header
      Module Steps 
      1 - Deploy Hub VNet
      2 - Deploy DNS Zones for most frequent services - OpenAI, Search, Cog Services and Blob Storage
      3 - Output back to main module the following params (hub ID, private DNS Zone IDs)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param hubName string
param hubCIDR array
param tags object = {}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

// 1. Hub VNet deployment
// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
resource hub 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: hubName
  location: resourceLocation
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: hubCIDR
    }
  }
}

// 2. Private DNS Zones
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones
resource openaiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: tags
  properties: {}
}

resource searchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.search.azure.com'
  location: 'global'
  tags: tags
  properties: {}
}

resource cogServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
  tags: tags
  properties: {}
}

resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: tags
  properties: {}
}

// 3. Virtual Network Links - Allows Hub Vnet to resolve Private DNS Zones
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones/virtualnetworklinks
resource openaiVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: openaiPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hub.id
    }
  }
}

resource searchVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: searchPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hub.id
    }
  }
}

resource cogServicesVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: cogServicesPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hub.id
    }
  }
}

resource storageVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: storagePrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hub.id
    }
  }
}

output hubID string = hub.id
output openaiPrivateDnsZoneId string = openaiPrivateDnsZone.id
output searchPrivateDnsZoneId string = searchPrivateDnsZone.id
output cogServicesPrivateDnsZoneId string = cogServicesPrivateDnsZone.id
output storagePrivateDnsZoneId string = storagePrivateDnsZone.id
