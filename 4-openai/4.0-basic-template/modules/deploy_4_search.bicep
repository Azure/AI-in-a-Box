/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param searchAccountName string
param vnetID string
param subnetID string
param tags object

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//1. Create Azure Search Instance
resource searchAccount 'Microsoft.Search/searchServices@2020-08-01' = {
  name: searchAccountName
  location: resourceLocation
  sku: {
    name: 'standard'
  }
  properties: {
    publicNetworkAccess: 'disabled'
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${searchAccountName}pe'
  location: resourceLocation
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'search-private-endpoint'
        properties: {
          privateLinkServiceId: searchAccount.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.search.azure.com'
  location: 'global'
  tags: tags
  properties: {}
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetID
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'default'
  parent: searchPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}