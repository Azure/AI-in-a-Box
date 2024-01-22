/*region Header
      Module Steps 
      1 - Deploy VNet
      2 - Deploy Subnets using a loop
      3 - Output back to main module the following params (spokeID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param from string
param to string


//Variables--------------------------------------------------------------------------------------------------------------------------
var fromName = last(split(from, '/'))
var toName = last(split(to, '/'))

resource fromVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: fromName
}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

resource destinationToSourcePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${fromName}-to-${toName}'
  parent: fromVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: to
    }
  }
}
