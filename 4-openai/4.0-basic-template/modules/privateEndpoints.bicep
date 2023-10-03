/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param subnetID string
param serviceId string
param groupIds string[]
param privateDnsZoneId string


param tags object = {}

// // Variables
// var services = [
//   {id: openaiAccountID, groupIds: ['account'], privateDnsZone: filter(privateDnsZoneIds, id => endsWith(id, 'privatelink.openai.azure.com'))[0]}
//   {id: searchAccountID, groupIds: ['searchService'], privateDnsZone: filter(privateDnsZoneIds, id => endsWith(id, 'privatelink.search.azure.com'))[0]}
//   {id: docIntelAccountID, groupIds: ['account'], privateDnsZone: filter(privateDnsZoneIds, id => endsWith(id, 'privatelink.cognitiveservices.azure.com'))[0]}
//   {id: storageAccountID, groupIds: ['blob'], privateDnsZone: filter(privateDnsZoneIds, id => endsWith(id, 'privatelink.blob.${environment().suffixes.storage}'))[0]}
//   {id: cosmosAccountID, groupIds: ['Sql'], privateDnsZone: filter(privateDnsZoneIds, id => endsWith(id, 'privatelink.documents.azure.com'))[0]}
// ]

//Create Resources----------------------------------------------------------------------------------------------------------------------------
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${last(split(serviceId, '/'))}-pe'
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
          privateLinkServiceId: serviceId
          groupIds: groupIds
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
}]


