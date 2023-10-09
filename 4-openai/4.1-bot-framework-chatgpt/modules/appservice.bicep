//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param prefix string
param appSubnetId string
param msaAppId string
param sku string = 'S1'
@secure()
param msaAppPassword string
param tags object = {}

param openaiAccountName string

//Variables--------------------------------------------------------------------------------------------------------------------------
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3)
var appServicePlanName = '${prefix}-plan-${uniqueSuffix}'
var appServiceName = '${prefix}-app-${uniqueSuffix}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: resourceLocation
  tags: tags
  sku: {
    name: sku
  }
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: resourceLocation
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: appSubnetId
    httpsOnly: true
    siteConfig: {
      vnetRouteAllEnabled: true
      http20Enabled: true
      appSettings: [
        {
          name: 'MicrosoftAppType'
          value: 'MultiTenant'
        }
        {
          name: 'MicrosoftAppId'
          value: msaAppId
        }
        {
          name: 'MicrosoftAppPassword'
          value: msaAppPassword
        }
        {
          name: 'AOAI_API_ENDPOINT'
          value: openaiAccount.properties.endpoint
        }
        {
          name: 'AOAI_MODEL'
          value: openaiAccount::gpt35deployment.name
        }
      ]
    }
  }
}

resource openaiAccount 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: openaiAccountName
  resource gpt35deployment 'deployments' existing = {
    name: 'gpt-35-turbo'
  }
  resource gpt4deployment 'deployments' existing = {
    name: 'gpt-4'
  }
}

output hostName string = appService.properties.defaultHostName
