/*region Header
      Module Steps 
      1 - Create ML Workspace
      2 - Create ML Workspace Compute Instance
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param keyVaultName string
param location string 
param tenantId string = subscription().tenantId

resource kvn 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enableSoftDelete: true
  }
}
output keyVaultId string = kvn.id
