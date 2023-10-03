/*region Header
      Module Steps 
      1 - Deploy Spoke VNet with a default subnet
      2 - Peer Spoke with Hub Vnet
      3 - Output back to main module the following params (spokeID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param prefix string
param tags object = {}
param dnsIp string
param existingSpokeName string = ''
param existingPrivateEndpointSubnetName string = ''


//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var spokeName = !empty(existingSpokeName) ? existingSpokeName : '${prefix}-ai-vnet-${uniqueSuffix}'
var privateEndpointSubnetName = !empty(existingPrivateEndpointSubnetName) ? existingPrivateEndpointSubnetName : 'private-endpoints-subnet'
var spokeCIDR = ['10.1.0.0/16']
var privateEndpointSubnetCIDR = '10.1.0.0/16'

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//1. vNet created for network protected environments

resource existingSpoke 'Microsoft.Network/virtualNetworks@2020-11-01' existing = if (!empty(existingSpokeName)) {
  name: spokeName

  resource privateEndpointSubnet 'subnets' existing = {
    name: privateEndpointSubnetName
  }
}

resource spoke 'Microsoft.Network/virtualNetworks@2020-11-01' = if (empty(existingSpokeName)) {
  name: spokeName
  location: resourceLocation
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: spokeCIDR
    }
    subnets: [{
      name: privateEndpointSubnetName
      properties: {
        addressPrefix: privateEndpointSubnetCIDR
      }
    }]
    dhcpOptions: {
      dnsServers: [
        dnsIp
      ]
    }
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: privateEndpointSubnetName
  }
}

output spokeID string = existingSpoke.id ?? spoke.id
output privateEndpointsSubnetID string = existingSpoke::privateEndpointSubnet.id ?? spoke::privateEndpointSubnet.id
