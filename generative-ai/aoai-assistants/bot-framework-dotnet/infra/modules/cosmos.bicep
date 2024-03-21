param location string
param cosmosName string
param tags object = {}
param msiPrincipalID string
param publicNetworkAccess string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' =  {
  name: cosmosName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: publicNetworkAccess
  }

  resource db 'sqlDatabases' = {
    name: 'AssistantBot'
    properties: {
      resource: {
        id: 'AssistantBot'
      }
    }



  resource col 'containers' = {
    name: 'Conversations'
    properties: {
      resource: {
        id: 'Conversations'
        partitionKey: {
          paths: ['/id']
          kind: 'Hash'
        }
      }
    }
  }
  }
}

resource cosmosDataReader 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-10-15' existing = {
  name: '00000000-0000-0000-0000-000000000001'
  parent: cosmos
}

resource cosmosDataContributor 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-10-15' existing = {
  name: '00000000-0000-0000-0000-000000000002'
  parent: cosmos
}

resource appReadAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(cosmos.id, msiPrincipalID, cosmosDataReader.id)
  parent: cosmos
  properties: {
    roleDefinitionId: cosmosDataReader.id
    principalId: msiPrincipalID
    scope: cosmos.id
  }
}

resource appWriteAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(cosmos.id, msiPrincipalID, cosmosDataContributor.id)
  parent: cosmos
  properties: {
    roleDefinitionId: cosmosDataContributor.id
    principalId: msiPrincipalID
    scope: cosmos.id
  }
}



output cosmosID string = cosmos.id
output cosmosEndpoint string = cosmos.properties.documentEndpoint
