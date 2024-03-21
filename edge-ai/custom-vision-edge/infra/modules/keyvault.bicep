/*region Header
      Module Steps 
      1 - Create ML Workspace
      2 - Create ML Workspace Compute Instance
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param keyVaultName string
param location string 
param tenantId string = subscription().tenantId
param principalId string

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
resource kvn 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: principalId
        permissions: {
          keys: [
            'all'
            'create'
            'delete'
            'get'
            'update'
            'list'
            'purge'
          ]
          secrets: [
            'all'
            'set'
            'get'
            'delete'
            'purge'
          ]
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
}

output keyVaultName string = kvn.name
output keyVaultObject object = kvn
output keyVaultId string = kvn.id
