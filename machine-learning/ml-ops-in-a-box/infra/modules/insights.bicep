param applicationInsightsName string
param resourceLocation string = resourceGroup().location

resource aisn 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: (((resourceLocation == 'eastus2') || (resourceLocation == 'westcentralus')) ? 'southcentralus' : resourceLocation)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
output applicationInsightId string = aisn.id
