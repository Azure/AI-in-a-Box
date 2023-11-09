//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param formRecognierName string
param location string
param keyVaultName string


resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource formrecognizer 'Microsoft.CognitiveServices/accounts@2021-04-30' = {
  name: formRecognierName
  location: location
  sku: {
    //name: 'F0' // can change to 'S0' later for more resources. 
    name: 'S0' // Valid name:F0, F1, S, S0, S1, S2, S3, S4, S5, S6, P0, P1, and P2. 
  }
  kind: 'FormRecognizer'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: formRecognierName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}


// save adls key to key vault
resource FrEndPointToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'FormRecognizerEndPoint'
  parent: formKeyVault
  properties: {
    value: formrecognizer.properties.endpoint
  }
}


// save adls key to key vault
resource FrKeyToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'FormRecognizerKey'
  parent: formKeyVault
  properties: {
    value: listKeys(formrecognizer.id, formrecognizer.apiVersion).key1
  }
}

output formRecognizerId string = formrecognizer.id
output formRecognizerPrincipalId string = formrecognizer.identity.principalId
