param name string
param location string = resourceGroup().location
param vmUserAssignedIdentityPrincipalID string

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        objectId: vmUserAssignedIdentityPrincipalID
        permissions: {
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
          keys: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
    tenantId: subscription().tenantId
    enabledForDiskEncryption: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    enableRbacAuthorization: false
    // networkAcls: {
    //   bypass: 'AzureServices'
    //   defaultAction: 'Deny'
    // }
  }
}

output keyvaultId string = keyvault.id
