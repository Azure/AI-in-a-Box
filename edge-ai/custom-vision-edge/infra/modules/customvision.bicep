/*region Header
      Module Steps 
      1 - Create Custom Vision Account
      2 - Save Custom Vision Endpoint to Key Vault
      3 - Save Custom Vision Key to Key Vault
      
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param keyVaultName string
param cognitiveServiceName string
@allowed([
  'S0'
])
param sku string = 'S0'


//Retrieve the name of the newly created key vault
resource kvRef 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
//https://learn.microsoft.com/en-us/azure/ai-services/create-account-bicep
//1. Create Custom Vision Account
resource customVisionAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: cognitiveServiceName
  location: location 
  sku: {
    name: sku // Valid name:F0, F1, S, S0, S1, S2, S3, S4, S5, S6, P0, P1, and P2. 
  }
  kind: 'CustomVision.Training'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: cognitiveServiceName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
//2. Save Custom Vision Endpoint to Key Vault
resource CvEndPointToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'CustomVisionEndPoint'
  parent: kvRef
  properties: {
    value: customVisionAccount.properties.endpoint
  }
}

// //3. Save Custom Vision Key to Key Vault
resource CvKeyToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'CustomVisionKey'
  parent: kvRef
  properties: {
    value: customVisionAccount.listKeys().key1
  }
}

output customVisionAccountAccountID string = customVisionAccount.id
output customVisionAccountPrincipalId string = customVisionAccount.identity.principalId
