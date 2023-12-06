/*region Header
      Module Steps 
      1 - Deploy Spoke VNet with a default subnet
      2 - Peer Spoke with Hub Vnet
      3 - Output back to main module the following params (spokeID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param tags object = {}
param dnsResolverInboundIp string
param spokeName string
param spokeAddressPrefixes string[]
param privateEndpointSubnetName string
param privateEndpointSubnetPrefix string


//Create Resources----------------------------------------------------------------------------------------------------------------------------

resource spoke 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: spokeName
  location: location
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: spokeAddressPrefixes
    }
    subnets: [
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
        }
      }
  ]
    dhcpOptions: {
      dnsServers: [
        dnsResolverInboundIp
      ]
    }
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: privateEndpointSubnetName
  }

}

output spokeID string = spoke.id
output privateEndpointsSubnetID string = spoke::privateEndpointSubnet.id
