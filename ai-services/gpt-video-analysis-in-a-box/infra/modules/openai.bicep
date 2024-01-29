param resourceLocation string
param openaiName string 
param gptModelName string 
param gptModelVersion string 
param gptDeploymentName string
param principalId string
param publicNetworkAccess string
param keyVaultName string 
param uamiId string

resource kvRef 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource openai 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: openaiName
  location: resourceLocation
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    customSubDomainName: openaiName
    apiProperties: {
      statisticsEnabled: false
    }
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: publicNetworkAccess
  }
}

resource gpt4deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openai
  name: gptDeploymentName
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName
      version: gptModelVersion
    }
  }
  sku: {
    capacity: 4
    name: 'Standard'
  }
}


resource openaiAPISecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'openai-api-base-url'
  parent: kvRef
  properties: {
    value: openai.properties.endpoint
  }
}

resource openaiAPIKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'open-api-key'
  parent: kvRef
  properties: {
    value: openai.listKeys().key1
  }
}


resource openaiUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}

resource appAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openai.id, principalId, openaiUser.id)
  scope: openai
  properties: {
    roleDefinitionId: openaiUser.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output openaiID string = openai.id
output openaiName string = openai.name
output openaiBaseUrl string = openai.properties.endpoint
output openaiGPTModel string = gpt4deployment.name
