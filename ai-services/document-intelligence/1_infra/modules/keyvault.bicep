/*region Header
      Module Steps 
      1 - Create Key Vault
      2 - Create Necessary Secrets
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
targetScope = 'resourceGroup'

param resourceLocation string
param keyVaultName string
param principalId string
param spObjectId string

//key vault access policy permissions that comes from main.bicepparam kvSecretPermissions array and kvkeyPermissions array
param kvSecretPermissions array
param kvKeyPermissions array

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
//1. Create Key Vault
resource r_keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalId
        permissions: {
          secrets: kvSecretPermissions
          keys: kvKeyPermissions
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: spObjectId //This is your Service Principal Object ID so you can give the SP access to the Key Vault Secrets
        permissions: {
          secrets: kvSecretPermissions
          keys: kvKeyPermissions
        }
      }
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    enableSoftDelete: false
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
  dependsOn: []
}

output keyVaultName string = r_keyVault.name
output keyVaultObject object = r_keyVault
output keyVaultID string = r_keyVault.id
