/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - (optional) Create Azure Document Intelligence Instance
      3 - (optional) Create Azure Search Instance
      4 - Create Storage Account
      5 - Create CosmosDB Account
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param prefix string
param subnetID string
param privateDnsZoneId string
param tags object = {}


//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var cosmosAccountName = '${prefix}-cosmos-${uniqueSuffix}'

//Create Resources----------------------------------------------------------------------------------------------------------------------------

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' =  {
  name: cosmosAccountName
  location: resourceLocation
  kind: 'GlobalDocumentDB'
  properties: {
    locations: [
      {
        locationName: resourceLocation
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${cosmosAccountName}-pe'
  location: resourceLocation
  tags: tags
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'private-endpoint-connection'
        properties: {
          privateLinkServiceId: cosmosAccount.id
          groupIds: ['Sql']
        }
      }
    ]
  }
  
  resource privateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'default'
          properties: {
            privateDnsZoneId: privateDnsZoneId
          }
        }
      ]
    }
  }
}


output searchAccountID string = cosmosAccount.id
