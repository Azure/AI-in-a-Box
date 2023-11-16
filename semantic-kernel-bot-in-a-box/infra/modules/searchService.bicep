param resourceLocation string
param prefix string
param tags object = {}

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var searchAccountName = '${prefix}-search-${uniqueSuffix}'


resource searchAccount 'Microsoft.Search/searchServices@2020-08-01' = {
  name: searchAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'standard'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

output searchAccountID string = searchAccount.id
