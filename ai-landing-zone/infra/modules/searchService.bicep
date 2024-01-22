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
param searchName string
param subnetID string
param privateDnsZoneId string
param tags object = {}


//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 

//Create Resources----------------------------------------------------------------------------------------------------------------------------

// 1. Create Azure Search Instance
// https://learn.microsoft.com/en-us/azure/templates/microsoft.search/searchservices
resource searchAccount 'Microsoft.Search/searchServices@2020-08-01' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
  properties: {
    publicNetworkAccess: 'disabled'
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${searchName}-pe'
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
          privateLinkServiceId: searchAccount.id
          groupIds: ['searchService']
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


output searchAccountID string = searchAccount.id
