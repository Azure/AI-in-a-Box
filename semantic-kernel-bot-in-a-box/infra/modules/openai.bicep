param resourceLocation string
param prefix string
param tags object = {}

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3)
var openaiAccountName = '${prefix}-openai-${uniqueSuffix}'


resource openaiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openaiAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openaiAccountName
    apiProperties: {
      statisticsEnabled: false
    }
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource gpt4deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openaiAccount
  name: 'gpt-4'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
  }
  sku: {
    capacity: 10
    name: 'Standard'
  }
}

resource gpt35deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openaiAccount
  name: 'gpt-35-turbo'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
  }
  sku: {
    capacity: 10
    name: 'Standard'
  }
  dependsOn: [gpt4deployment]
}


resource adaEmbeddingsdeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openaiAccount
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
  dependsOn: [gpt35deployment]
}

output openaiAccountID string = openaiAccount.id
