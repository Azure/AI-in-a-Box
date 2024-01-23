/*region Header
      Module Steps 
      1 - Create OpenAI Account
      2 - Create GPT-3 Deployment
      3 - Create Text Embeddings Deployment
      4 - Create DALL-E Deployment
      5 - Create Role Assignment
      6 - Output OpenAI Account ID
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param openaiName string
param gptModel string
param gptVersion string
param msiPrincipalID string
param deployDalle3 bool
param publicNetworkAccess string
param tags object = {}

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openaiName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
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

resource gpt35turbodeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openai
  name: 'gpt-35-turbo'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0301'
    }
  }
  sku: {
    capacity: 10
    name: 'Standard'
  }
}

// resource gpt4deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
//   parent: openai
//   name: 'gpt-4'
//   properties: {
//     model: {
//       format: 'OpenAI'
//       name: gptModel
//       version: gptVersion
//     }
//   }
//   sku: {
//     capacity: 10
//     name: 'Standard'
//   }
// }

resource adaEmbeddingsdeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openai
  name: 'text-embedding-ada-002'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
  }
  sku: {
    capacity: 10
    name: 'Standard'
  }
  dependsOn: [gpt35turbodeployment]
}


// resource dalle3deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployDalle3) {
//   parent: openai
//   name: 'dall-e-3'
//   properties: {
//     model: {
//       format: 'OpenAI'
//       name: 'dall-e-3'
//       version: '3.0'
//     }
//   }
//   sku: {
//     capacity: 1
//     name: 'Standard'
//   }
//   dependsOn: [adaEmbeddingsdeployment]
// }

resource openaiUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}

resource appAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openai.id, msiPrincipalID, openaiUser.id)
  scope: openai
  properties: {
    roleDefinitionId: openaiUser.id
    principalId: msiPrincipalID
    principalType: 'ServicePrincipal'
  }
}

output openaiID string = openai.id
output openaiEndpoint string = openai.properties.endpoint
output openaiGPTModel string = gpt35turbodeployment.name
output openaiEmbeddingsModel string = adaEmbeddingsdeployment.name
