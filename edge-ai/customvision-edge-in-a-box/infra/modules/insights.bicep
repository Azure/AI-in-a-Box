/*region Header
      Module Steps 
      1 - Create App Insights
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param applicationInsightsName string
param location string

resource aisn 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
output applicationInsightId string = aisn.id
