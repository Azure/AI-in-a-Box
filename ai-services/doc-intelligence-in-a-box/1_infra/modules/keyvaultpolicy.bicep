/*region Header
      Module Steps 
      1 - Create Access Polcies for KeyVault
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
@description('Name of the KeyVault resource ex. kv-myservice')
param keyVaultResourceName string
@description('Principal Id of the Azure Function App')
param principalId string

//https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/accesspolicies
//1. Create Access Policies for KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultResourceName
  resource keyVaultPolicies 'accessPolicies' = {
    name: 'add'
    properties: {
      accessPolicies: [
        {
          tenantId: subscription().tenantId
          objectId: principalId
          permissions: {
            secrets: [
              'get'
            ]
          }
        }
      ]
    }
  }
}
