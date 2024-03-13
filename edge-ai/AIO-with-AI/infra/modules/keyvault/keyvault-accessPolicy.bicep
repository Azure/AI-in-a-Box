param vaultName string
param vmUserAssignedIdentityPrincipalID string

resource keyvaultaccesspolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: '${vaultName}/add'
  properties: {
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
  }
}
