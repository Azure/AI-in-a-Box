/*region Header
      Module Steps 
      1 - Get Key Vault Reference
      2 - Create Logic App API Cnx
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param connectionName string
param cosmosAccountName string
@secure()
param paramCosmosAccountKey string

//https://learn.microsoft.com/en-us/azure/templates/microsoft.web/connections
//Set up an active connection
resource apiCnxCosmosDB 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: resourceLocation
  properties: {
    displayName: connectionName
    api: {
      name: 'cosmosdb'
      displayName: 'CosmosDB'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceLocation, 'documentdb')
      type: 'Microsoft.Web/locations/managedApis'
    }
    parameterValues: {
      databaseAccount: cosmosAccountName
      accessKey: paramCosmosAccountKey
    }
  }
}

output cosmosDbConnectionId string = apiCnxCosmosDB.id
