//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param cosmosAccountName string
param cosmosDbName string
param cosmosDbContainerName string
param location string

param keyVaultName string // 


resource formKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


resource cosmosdbaccount 'Microsoft.DocumentDB/databaseAccounts@2019-12-12' = {
  name: cosmosAccountName
  location: location
  tags: {
  }
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxStalenessPrefix: 1
      maxIntervalInSeconds: 5
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}



resource cosmosdbaccountname_dbname 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosdbaccount
  name: cosmosDbName
  properties: {
    resource: {
      id: cosmosDbName
    }
  }
}

resource cosmosdbaccountname_dbname_container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-04-15' = {
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
        automatic:true
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
    options: {
    }
  }
}

resource CosmosDbKeyToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'CosmosDbPrimaryKey'
  parent: formKeyVault
  properties: {
    value: cosmosdbaccount.listKeys().primaryMasterKey
  }
}

resource CosmosDbConnectionStringToKv 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'CosmosDbConnectionString'
  parent: formKeyVault
  properties: {
   value:listConnectionStrings(cosmosdbaccount.id,cosmosdbaccount.apiVersion).connectionStrings[0].connectionString
  }

}

output cosmosAccountId string = cosmosdbaccount.id
output cosmosAccountName string =cosmosdbaccount.name
