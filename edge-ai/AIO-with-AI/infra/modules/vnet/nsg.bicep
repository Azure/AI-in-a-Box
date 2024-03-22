/*region Header
      Module Steps 
      1 - Creae NSG
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param nsgName string
param securityRules array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}
output nsgID string = nsg.id
