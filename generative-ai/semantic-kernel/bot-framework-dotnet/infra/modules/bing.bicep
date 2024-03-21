param location string
param bingName string
param tags object = {}
param msiPrincipalID string

resource bing 'Microsoft.Bing/accounts@2020-06-10' = {
  name: bingName
  location: location
  tags: tags
  sku: {
    name: 'F1'
  }
  kind: 'Bing.Search.v7'
}

output bingID string = bing.id
output bingName string = bing.name
output bingApiEndpoint string = bing.properties.endpoint
