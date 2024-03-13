param publicipName string
param publicipproperties object
param location string = resourceGroup().location

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
