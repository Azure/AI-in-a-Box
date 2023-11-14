param keyVaultName string
param resourceLocation string = resourceGroup().location
param tenantId string = subscription().tenantId

resource kvn 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: resourceLocation
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
