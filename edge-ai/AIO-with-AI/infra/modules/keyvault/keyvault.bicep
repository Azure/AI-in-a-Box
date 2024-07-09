/*region Header
      Module Steps 
      1 - Create KeyVault
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param keyVaultName string
param location string = resourceGroup().location
param vmUserAssignedIdentityPrincipalID string
param spObjectId string

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
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
      {
        tenantId: subscription().tenantId
        objectId: spObjectId //This is your Service Principal Object ID or your own User Object ID so you can give the SP access to the Key Vault Secrets
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
      }
    ]
    tenantId: subscription().tenantId
    enabledForDiskEncryption: true
    softDeleteRetentionInDays: 7
    //enablePurgeProtection: true //Commented this out to disable purge protection
    enableRbacAuthorization: false
    // networkAcls: {
    //   bypass: 'AzureServices'
    //   defaultAction: 'Deny'
    // }
  }
}

output keyVaultId string = keyvault.id
output keyVaultName string = keyvault.name
