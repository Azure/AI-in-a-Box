/*region Header
      Module Steps 
      1 - Create a Public IP Address
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string = resourceGroup().location
param publicipName string
param publicipproperties object

//https://learn.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses
resource publicip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: publicipproperties
}
output publicipId string = publicip.id
output publicipAddress string = publicip.properties.ipAddress
