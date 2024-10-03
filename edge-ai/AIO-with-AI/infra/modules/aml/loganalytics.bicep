/*region Header
      Module Steps 
      1 - Create Log Analytics workspace
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
metadata description = 'Creates a Log Analytics workspace.'
param location string = resourceGroup().location
param logAnalyticsName string
param tags object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

output id string = logAnalytics.id
output name string = logAnalytics.name
