/*region Header
      Module Steps 
      1 - Deploy VNet
      2 - Deploy Subnets using a loop
      3 - Output back to master module the following params (spokeID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param coreRG string
param hubName string
param spokeName string
param defaultSubnetName string
param spokeCIDR array

//Existing Resources----------------------------------------------------------------------------------------------------------------------------

resource hub 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: hubName
  scope: resourceGroup(coreRG)
}

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//1. vNet created for network protected environments
resource spoke 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: spokeName
  location: resourceLocation
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
      id: hub.id
    }
  }
}

output spokeID string = spoke.id
output subnetID string = spoke.properties.subnets[0].id
