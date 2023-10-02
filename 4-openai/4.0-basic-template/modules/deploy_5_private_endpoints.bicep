/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param subnetID string
param openaiAccountID string
param searchAccountID string
param docIntelAccountID string
param storageAccountID string

param storagePrivateDnsZoneID string
param openaiPrivateDnsZoneID string
param searchPrivateDnsZoneID string
param cogServicesPrivateDnsZoneID string

param tags object = {}

// Variables - get resource names from IDs
var openaiAccountName = last(split(openaiAccountID, '/'))
var searchAccountName = last(split(searchAccountID, '/'))
var docIntelAccountName = last(split(docIntelAccountID, '/'))
var storageAccountName = last(split(storageAccountID, '/'))

//Create Resources----------------------------------------------------------------------------------------------------------------------------
resource openaiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${openaiAccountName}pe'
  location: resourceLocation
  tags: tags
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-private-endpoint'
        properties: {
          privateLinkServiceId: openaiAccountID
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${searchAccountName}pe'
  location: resourceLocation
  tags: tags
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'search-private-endpoint'
        properties: {
          privateLinkServiceId: searchAccountID
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource docIntelPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${docIntelAccountName}pe'
  location: resourceLocation
  tags: tags
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'docIntel-private-endpoint'
        properties: {
          privateLinkServiceId: docIntelAccountID
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}pe'
  location: resourceLocation
  tags: tags
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-private-endpoint'
        properties: {
          privateLinkServiceId: storageAccountID
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource openaiPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'default'
  parent: openaiPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: openaiPrivateDnsZoneID
        }
      }
    ]
  }
}

resource searchPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'default'
  parent: searchPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: searchPrivateDnsZoneID
        }
      }
    ]
  }
}

resource docIntelPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'default'
  parent: docIntelPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: cogServicesPrivateDnsZoneID
        }
      }
    ]
  }
}

resource storagePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'default'
  parent: storagePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: storagePrivateDnsZoneID
        }
      }
    ]
  }
}

output openaiPrivateEndpointName string = searchPrivateEndpoint.name
output storagePrivateEndpointName string = storagePrivateEndpoint.name
output searchPrivateEndpointName string = searchPrivateEndpoint.name
