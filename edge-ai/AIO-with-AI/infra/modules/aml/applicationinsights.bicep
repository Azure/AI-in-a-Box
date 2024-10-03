/*region Header
      Module Steps 
      1 - Create App Insights
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
metadata description = 'Creates an Application Insights instance based on an existing Log Analytics workspace.'
param applicationInsightsName string
param location string = resourceGroup().location
param logAnalyticsWorkspaceId string
param tags object = {}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output connectionString string = applicationInsights.properties.ConnectionString
output applicationInsightId string = applicationInsights.id
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output applicationInsightsName string = applicationInsights.name
