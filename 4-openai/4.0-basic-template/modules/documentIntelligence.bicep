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
var docintelAccountName = '${prefix}-docintel-${uniqueSuffix}'

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//2. Create Azure Document Intelligence
// https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
resource docintelAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: docintelAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: docintelAccountName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${docintelAccountName}-pe'
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
