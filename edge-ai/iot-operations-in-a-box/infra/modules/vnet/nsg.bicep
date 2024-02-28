param nsgName string
param securityRules array = []
param location string
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}
output nsgID string = nsg.id
