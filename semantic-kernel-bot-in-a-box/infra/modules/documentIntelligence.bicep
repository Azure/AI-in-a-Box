param resourceLocation string
param prefix string
param tags object = {}

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3)
var documentIntelligenceAccountName = '${prefix}-docs-${uniqueSuffix}'


resource documentIntelligenceAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: documentIntelligenceAccountName
  location: resourceLocation
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: documentIntelligenceAccountName
    apiProperties: {
      statisticsEnabled: false
    }
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

output documentIntelligenceAccountID string = documentIntelligenceAccount.id
