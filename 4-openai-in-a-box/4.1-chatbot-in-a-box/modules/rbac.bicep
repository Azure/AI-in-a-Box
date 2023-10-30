//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param prefix string

param openaiAccountName string
param searchAccountName string
param cosmosAccountName string

//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3)
var appServiceName = '${prefix}-app-${uniqueSuffix}'

resource appService 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appServiceName
}

resource openaiUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
}
resource searchIndexDataReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
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
  name: guid(resourceGroup().id, appService.name, searchIndexDataReader.id)
  scope: searchAccount
  properties: {
    roleDefinitionId: searchIndexDataReader.id
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
