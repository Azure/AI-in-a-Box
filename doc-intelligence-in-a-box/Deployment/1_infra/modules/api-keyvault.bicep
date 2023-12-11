param connectionName string //= 'aidocjh2_keyvault'
param resourceLocation string
resource connections_keyvault_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: resourceLocation
  properties: {
    displayName: connectionName
    parameterValues: {
      //authentication: 'oauthMI'
      //vaultName:'aidocjh2-kv-jhdoc'
        }
    statuses: [
      {
        status: 'Ready'
      }
    ]
    api: {
      name: 'keyvault'
      displayName: 'Azure Key Vault'
      description: 'Azure Key Vault is a service to securely store and access secrets.'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceLocation, 'keyvault')
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}


output keyVaultConnectionID string = connections_keyvault_name_resource.id
