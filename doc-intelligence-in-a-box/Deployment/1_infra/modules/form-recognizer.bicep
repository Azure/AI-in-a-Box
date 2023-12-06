/*region Header
      Module Steps 
      1 - Create Form Recognizer
      2 - Save Form Recognizer Endpoint to Key Vault
      3 - Save Form Recognizer Key to Key Vault
      
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param formRecognizerName string
param location string
param keyVaultName string

//Retrieve the name of the newly created key vault
resource kvRef 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
//1. Create Form Recognizer
resource formrecognizer 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: formRecognizerName
  location: location
  sku: {
    name: 'S0' // Valid name:F0, F1, S, S0, S1, S2, S3, S4, S5, S6, P0, P1, and P2. 
  }
  kind: 'FormRecognizer'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: formRecognizerName
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
    value: formrecognizer.properties.endpoint
  }
}

//3. Save Form Recognizer Key to Key Vault
resource FrKeyToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'FormRecognizerKey'
  parent: kvRef
  properties: {
    value: formrecognizer.listKeys().key1
  }
}

output formRecognizerId string = formrecognizer.id
output formRecognizerPrincipalId string = formrecognizer.identity.principalId
