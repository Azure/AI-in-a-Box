param appServiceName string
param openaiAccountName string
param documentIntelligenceAccountName string
param searchAccountName string
param cosmosAccountName string


resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource openaiUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}
resource searchIndexDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
}
resource cosmosContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource openaiAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: openaiAccountName
}

resource appToOpenai 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appService.name, openaiUser.id)
  scope: openaiAccount
  properties: {
    roleDefinitionId: openaiUser.id
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource searchAccount 'Microsoft.Search/searchServices@2020-08-01' existing = {
  name: searchAccountName
}

resource appToSearch 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appService.name, searchIndexDataContributor.id)
  scope: searchAccount
  properties: {
    roleDefinitionId: searchIndexDataContributor.id
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: cosmosAccountName
}

resource appToCosmos 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appService.name, cosmosContributor.id)
  scope: cosmosAccount
  properties: {
    roleDefinitionId: cosmosContributor.id
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
