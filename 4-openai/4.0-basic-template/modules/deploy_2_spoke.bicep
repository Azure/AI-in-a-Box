/*region Header
      Module Steps 
      1 - Deploy Spoke VNet with a default subnet
      2 - Peer Spoke with Hub Vnet
      3 - Output back to main module the following params (spokeID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param hubID string
param spokeName string
param defaultSubnetName string
param spokeCIDR array
param tags object = {}

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//1. vNet created for network protected environments
resource spoke 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: spokeName
  location: resourceLocation
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: spokeCIDR
    }
    subnets: [{
      name: defaultSubnetName
      properties: {
        addressPrefix: '10.1.0.0/24'
      }
    }]
  }
}

resource destinationToSourcePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'spoke-to-hub'
  parent: spoke
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: hubID
    }
  }
}

output spokeID string = spoke.id
output subnetID string = spoke.properties.subnets[0].id
