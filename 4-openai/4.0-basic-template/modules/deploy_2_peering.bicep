/*region Header
      Module Steps 
      1 - Deploy VNet
      2 - Deploy Subnets using a loop
      3 - Output back to master module the following params (spokeID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param hubName string
param spokeID string

//Existing Resources----------------------------------------------------------------------------------------------------------------------------

resource hub 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: hubName
}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

resource destinationToSourcePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'hub-to-spoke'
  parent: hub
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: spokeID
    }
  }
}
