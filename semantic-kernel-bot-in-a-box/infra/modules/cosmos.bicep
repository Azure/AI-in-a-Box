param resourceLocation string
param prefix string
param tags object = {}

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var cosmosAccountName = '${prefix}-cosmos-${uniqueSuffix}'


resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' =  {
  name: cosmosAccountName
  location: resourceLocation
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    locations: [
      {
        locationName: resourceLocation
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }

  resource db 'sqlDatabases' = {
    name: 'SKBot'
    properties: {
      resource: {
        id: 'SKBot'
      }
    }
  }
}

output cosmosAccountID string = cosmosAccount.id
