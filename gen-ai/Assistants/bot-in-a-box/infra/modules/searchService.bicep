param location string
param searchName string
param tags object = {}
param msiPrincipalID string
param publicNetworkAccess string

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
  properties: {
    authOptions: {
      aadOrApiKey: {}
    }
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: publicNetworkAccess
  }
}

resource searchContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
}

resource searchIndexContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
}

resource searchUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
}

resource appAccess1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(search.id, msiPrincipalID, searchContributor.id)
  scope: search
  properties: {
    roleDefinitionId: searchContributor.id
    principalId: msiPrincipalID
    principalType: 'ServicePrincipal'
  }
}

resource appAccess12'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(search.id, msiPrincipalID, searchIndexContributor.id)
  scope: search
  properties: {
    roleDefinitionId: searchIndexContributor.id
    principalId: msiPrincipalID
    principalType: 'ServicePrincipal'
  }
}

resource appAccess3 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(search.id, msiPrincipalID, searchUser.id)
  scope: search
  properties: {
    roleDefinitionId: searchUser.id
    principalId: msiPrincipalID
    principalType: 'ServicePrincipal'
  }
}

output searchID string = search.id
output searchName string = search.name
output searchEndpoint string = 'https://${search.name}.search.windows.net'
