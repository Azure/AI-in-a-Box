param cvName string 
param cvLocation string 
param keyVaultName string 
param uamiId string

resource kvRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource computerVision 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: cvName
  location: cvLocation
  sku: {
    name: 'S1'
  }
  kind: 'ComputerVision'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    
  }
}

resource visionAPISecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'vision-api-base-url'
  parent: kvRef
  properties: {
    value: computerVision.properties.endpoint
  }
}

resource visionAPIKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'vision-api-key'
  parent: kvRef
  properties: {
    value: computerVision.listKeys().key1
  }
}

