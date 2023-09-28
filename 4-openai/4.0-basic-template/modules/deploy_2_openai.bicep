/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param openAiAccountName string
param vnetID string
param subnetID string
param tags object

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//1. Create Azure OpenAI Instance
resource openaiAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: openAiAccountName
  location: resourceLocation
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAiAccountName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

resource openaiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${openAiAccountName}pe'
  location: resourceLocation
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-private-endpoint'
        properties: {
          privateLinkServiceId: openaiAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
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
  parent: openaiPrivateEndpoint
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