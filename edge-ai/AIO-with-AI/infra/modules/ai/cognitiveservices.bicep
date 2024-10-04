metadata description = 'Creates an Azure Cognitive Services instance.'
param aiServicesName string
param location string = resourceGroup().location
param deployments array = []
param kind string = 'AIServices' // or 'OpenAI' or AIServices
param tags object = {}

param authMode string = 'accessKey' // or 'managedIdentity'
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'
param allowedIpRules array = []
param networkAcls object = empty(allowedIpRules) ? {
  defaultAction: 'Allow'
} : {
  ipRules: allowedIpRules
  defaultAction: 'Deny'
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: kind
  properties: {
    disableLocalAuth: authMode == 'accessKey' ? false : true
    customSubDomainName: aiServicesName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls
  }
  sku: {
    name: 'S0'
  }
  tags: tags
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/deployments
@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: aiServices
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: deployment.?raiPolicyName ?? null
  }
  sku: deployment.?sku ?? {
    name: 'Standard'
    capacity: 10
  }
}]

output endpoint string = aiServices.properties.endpoint
output endpoints object = aiServices.properties.endpoints
output id string = aiServices.id
output name string = aiServices.name
output skuName string = aiServices.sku.name
