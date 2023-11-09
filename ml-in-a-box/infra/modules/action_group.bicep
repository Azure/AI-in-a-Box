param actiongroupname string
param resourceLocation string
param groupshortname string
param functionappname string
param functionappresourceid string
param httpTriggerUrl string

resource ag 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actiongroupname
  location: resourceLocation
  properties: {
    groupShortName: groupshortname
    enabled: true
    azureFunctionReceivers: [
      {
        name: functionappname
        functionAppResourceId: functionappresourceid
        functionName: functionappname
        httpTriggerUrl: httpTriggerUrl
      }
    ]
  }
}
output agGroupId string = ag.id
