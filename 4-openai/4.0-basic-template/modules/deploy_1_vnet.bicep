/*region Header
      Module Steps 
      1 - Deploy VNet
      2 - Deploy Subnets using a loop
      3 - Output back to master module the following params (vNetID, subnetID)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param vNetName string
param vNetSubnetName string
param vNetIPAddressPrefixes array

//Create Resources----------------------------------------------------------------------------------------------------------------------------
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks
//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets
//1. vNet created for network protected environments
resource r_vNet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vNetName
  location: resourceLocation
  properties:{
    addressSpace:{
      addressPrefixes: vNetIPAddressPrefixes
    }
    subnets: [{
      name: vNetSubnetName
      properties: {
        addressPrefix: '10.0.0.0/24'
      }
    }]
  }
}

output vNetID string = r_vNet.id
output subnetID string = r_vNet.properties.subnets[0].id