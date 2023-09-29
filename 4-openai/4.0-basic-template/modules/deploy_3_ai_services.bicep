/*region Header
      Module Steps 
      1 - Create Azure OpenAI Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param openaiAccountName string
param searchAccountName string
param docIntelAccountName string

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//1. Create Azure OpenAI Instance
resource openaiAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: openaiAccountName
  location: resourceLocation
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openaiAccountName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

//2. Create Azure Search Instance
resource searchAccount 'Microsoft.Search/searchServices@2020-08-01' = {
  name: searchAccountName
  location: resourceLocation
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

//2. Create Azure Document Intelligence
resource docIntelAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: docIntelAccountName
  location: resourceLocation
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: docIntelAccountName
    publicNetworkAccess: 'Disabled'
    apiProperties: {
      statisticsEnabled: false
    }
  }
}


output openaiAccountID string = openaiAccount.id
output searchAccountID string = searchAccount.id
output docIntelAccountID string = docIntelAccount.id
