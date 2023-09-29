/*region Header
      Module Steps 
      1 - Deploy VNet
      2 - Deploy Subnets using a loop
      3 - Output back to master module the following params (hub.id, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param hubName string
param hubCIDR array
param tags object = {}

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//1. vNet created for network protected environments
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
