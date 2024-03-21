/*region Header
      Module Steps 
      1 - Create CosmosDB Account
      2 - Create CosmosDB Database
      3 - Create CosmosDB Container
      4 - Save CosmosDB key to key vault
      5 - Save CosmosDB Cnx String to key vault
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param cosmosAccountName string
param cosmosDbName string
param cosmosDbContainerName string
param uamid string
param principalId string


//https://learn.microsoft.com/en-us/azure/templates/microsoft.documentdb/databaseaccounts
//1. Create Cosmos DB Account
resource cosmosdbaccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: resourceLocation
  tags: {}
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamid}': {}
    }
  }
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxStalenessPrefix: 100
      maxIntervalInSeconds: 5
    }
    locations: [
      {
        locationName: resourceLocation
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.documentdb/databaseaccounts/sqldatabases
//2. Create Cosmos DB Database
resource cosmosdbaccountname_dbname 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosdbaccount
  name: cosmosDbName
  properties: {
    resource: {
      id: cosmosDbName
    }
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.documentdb/databaseaccounts/sqldatabases/containers
//3. Create Cosmos DB Container
resource cosmosdbaccountname_dbname_container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosdbaccountname_dbname
  name: cosmosDbContainerName
  properties: {
    resource: {
      id: cosmosDbContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
            indexes: [
              {
                kind: 'Hash'
                dataType: 'String'
                precision: -1
              }
            ]
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
    options: {}
  }
}

resource cosmosDataReader 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-10-15' existing = {
  name: '00000000-0000-0000-0000-000000000001'
  parent: cosmosdbaccount
  
}

resource cosmosDataContributor 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-10-15' existing = {
  parent: cosmosdbaccount
  name: '00000000-0000-0000-0000-000000000002'
}

resource readAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  parent: cosmosdbaccount
  name: guid(cosmosdbaccount.id, principalId, cosmosDataReader.id)
  properties: {
    roleDefinitionId: cosmosDataReader.id
    principalId: principalId
    scope: cosmosdbaccount.id
  }
}

resource writeAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  parent: cosmosdbaccount
  name: guid(cosmosdbaccount.id, principalId, cosmosDataContributor.id)
  properties: {
    roleDefinitionId: cosmosDataContributor.id
    principalId: principalId
    scope: cosmosdbaccount.id
  }
}


output cosmosDBId string = cosmosdbaccount.id
output cosmosDBEndpoint string = cosmosdbaccount.properties.documentEndpoint
