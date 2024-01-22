/*region Header
      Module Steps 
      1 - Get Key Vault Reference
      2 - Create Logic App API Cnx
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param connectionName string
param storageAccountName string
@secure()
param paramAdlsPrimaryKey string

//https://learn.microsoft.com/en-us/azure/templates/microsoft.web/connections
//Set up an active connection
resource apiCnxADLS 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: resourceLocation
  properties: {
    displayName: connectionName
    api: {
      name: 'azureblob'
      displayName: 'Azure Blob Storage'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceLocation, 'azureblob')
      type: 'Microsoft.Web/locations/managedApis'
    }
    parameterValues: {
      accountName: storageAccountName
      accessKey: paramAdlsPrimaryKey
    }
  }
}

output adlsConnectionId string = apiCnxADLS.id
