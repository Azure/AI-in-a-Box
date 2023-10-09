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
param endpoint string
param msaAppId string
param sku string = 'F0'
param kind string = 'azurebot'
param tags object = {}


//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var botServiceName = '${prefix}-bot-${uniqueSuffix}'

resource botservice 'Microsoft.BotService/botServices@2022-09-15' = {
  name: botServiceName
  location: resourceLocation
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    displayName: botServiceName
    endpoint: endpoint
    msaAppId: msaAppId
    msaAppType: 'Multitenant'
  }
}
