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
param docIntelName string
param subnetID string
param privateDnsZoneId string
param tags object = {}

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//2. Create Azure Document Intelligence
// https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
resource docintelAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: docIntelName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: docIntelName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${docIntelName}-pe'
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
          privateLinkServiceId: docintelAccount.id
          groupIds: ['account']
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

output openaiAccountID string = docintelAccount.id
