/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - (optional) Create Azure Document Intelligence Instance
      3 - (optional) Create Azure Search Instance
      4 - Create Storage Account
      5 - Create CosmosDB Account
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param prefix string
param existingSpokeName string = ''


//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var spokeName = !empty(existingSpokeName) ? existingSpokeName : '${prefix}-ai-vnet-${uniqueSuffix}'
var appSubnetName = '${prefix}-bot-subnet-${uniqueSuffix}'
var appSubnetPrefix = '10.1.1.0/28'


resource spoke 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: spokeName
  resource appSubnet 'subnets' = {
    name: appSubnetName
    properties: {
      addressPrefix: appSubnetPrefix
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverFarms'
          }
        }
      ]
    }
  }
}

output appSubnetId string = spoke::appSubnet.id
