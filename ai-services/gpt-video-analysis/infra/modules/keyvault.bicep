targetScope = 'resourceGroup'

param keyVaultName string
param resourceLocation string
param spObjectId string
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalId
        permissions: {
          keys: ['get', 'list','create']
          secrets: ['get', 'list', 'set']
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: spObjectId
        permissions: {
          keys: ['all']
          secrets: ['all']
        }
      }
    ]
  }
}

output keyvaulturl string = keyVault.properties.vaultUri
