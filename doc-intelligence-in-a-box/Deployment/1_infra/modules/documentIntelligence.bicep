/*region Header
      Module Steps 
      1 - Create Form Recognizer
      2 - Save Form Recognizer Endpoint to Key Vault
      3 - Save Form Recognizer Key to Key Vault
      
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param keyVaultName string
param documentIntelligenceAccountName string

//Retrieve the name of the newly created key vault
resource kvRef 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
//1. Create Form Recognizer
resource documentIntelligenceAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: documentIntelligenceAccountName
  location: resourceLocation 
  sku: {
    name: 'S0' // Valid name:F0, F1, S, S0, S1, S2, S3, S4, S5, S6, P0, P1, and P2. 
  }
  kind: 'FormRecognizer'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: documentIntelligenceAccountName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
//2. Save Form Recognizer Endpoint to Key Vault
resource FrEndPointToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'FormRecognizerEndPoint'
  parent: kvRef
  properties: {
    value: documentIntelligenceAccount.properties.endpoint
  }
}

//3. Save Form Recognizer Key to Key Vault
resource FrKeyToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'FormRecognizerKey'
  parent: kvRef
  properties: {
    value: documentIntelligenceAccount.listKeys().key1
  }
}

output documentIntelligenceAccountID string = documentIntelligenceAccount.id
output documentIntelligencePrincipalId string = documentIntelligenceAccount.identity.principalId
