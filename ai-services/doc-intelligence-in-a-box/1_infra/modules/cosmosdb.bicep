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
param keyVaultName string
param cosmosAccountName string
param cosmosDbName string
param cosmosDbContainerName string

//Retrieve the name of the newly created key vault
resource kvRef 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.documentdb/databaseaccounts
//1. Create Cosmos DB Account
resource cosmosdbaccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: resourceLocation
  tags: {}
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxStalenessPrefix: 1
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

//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets
//4. Save CosmosDB key to key vault
resource CosmosDbKeyToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'CosmosDbPrimaryKey'
  parent: kvRef
  properties: {
    value: cosmosdbaccount.listKeys().primaryMasterKey
  }
}

//5. Save CosmosDB Cnx String to key vault
resource CosmosDbConnectionStringToKv 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'CosmosDbConnectionString'
  parent: kvRef
  properties: {
   value: cosmosdbaccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output cosmosAccountId string = cosmosdbaccount.id
output cosmosAccountName string = cosmosdbaccount.name
