param alertrulename string
param location string = 'global'
param azuremlworkspaceId string
param actionGroupId string
param azuremltargetResourceRegion string = resourceGroup().location

resource metricalert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertrulename
  location: location
  properties: {
    scopes: [
      azuremlworkspaceId
    ]
    severity: 3
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    autoMitigate: true
    targetResourceType: 'Microsoft.MachineLearningServices/workspaces'
    targetResourceRegion: azuremltargetResourceRegion
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    criteria: {
      allOf: [
        {
            threshold: 1
            name: 'Metric1'
            metricNamespace: 'Microsoft.MachineLearningServices/workspaces'
            metricName: 'Completed Runs'
            dimensions: [
               {
                name: 'ExperimentName'
                operator: 'Include'
                values: [
                  '*'
                ]
               }
            ]
            operator: 'GreaterThanOrEqual'
            timeAggregation: 'Total'
            skipMetricValidation: false
            criterionType: 'StaticThresholdCriterion'
        }
    ]
    'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
  }
}
