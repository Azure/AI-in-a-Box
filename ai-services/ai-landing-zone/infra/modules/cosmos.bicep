/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - (optional) Create Azure Document Intelligence Instance
      3 - (optional) Create Azure Search Instance
      4 - Create Storage Account
      5 - Create CosmosDB Account
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param cosmosName string
param subnetID string
param privateDnsZoneId string
param tags object = {}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' =  {
  name: cosmosName
  location: location
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
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${cosmosName}-pe'
  location: location
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
