param functionname string
param location string = resourceGroup().location
param existingStorageAccountName string
param gitHub_FunctionDeploymentZip string
param gitHub_repoOwnerName string
param gitHub_repoName string
param gitHub_workflowId string
param gitHub_PAT string
param resource_group string
param aml_workspace string
param aml_flow_deployment_name string
param aml_endpoint_name string
param aml_model_name string

// This is the name of the function app that will be created by the Zip deployment, it's only available after the deployment
// This value is hardcoded from the code itself, so it's not possible to get it from the deployment
var functionAppName = 'AzureMLAlertHttpTrigger'

//Storage Account
resource discoveryStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: existingStorageAccountName
}

resource serverfarm 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${functionname}-farm'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functioapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}
resource azfunctionsite 'Microsoft.Web/sites@2021-03-01' = {
  name: functionname
  location: location
  kind: 'functionapp'
  properties: {
      enabled: true
      hostNameSslStates: [
          {
              name: '${functionname}.azurewebsites.net'
              sslState: 'Disabled'
              hostType: 'Standard'
          }
          {
              name: '${functionname}.azurewebsites.net'
              sslState: 'Disabled'
              hostType: 'Repository'
          }
      ]
      serverFarmId: serverfarm.id
      reserved: false
      isXenon: false
      hyperV: false
      siteConfig: {
          numberOfWorkers: 1
          acrUseManagedIdentityCreds: false
          alwaysOn: false
          ipSecurityRestrictions: [
              {
                  ipAddress: 'Any'
                  action: 'Allow'
                  priority: 1
                  name: 'Allow all'
                  description: 'Allow all access'
              }
          ]
          scmIpSecurityRestrictions: [
              {
                  ipAddress: 'Any'
                  action: 'Allow'
                  priority: 1
                  name: 'Allow all'
                  description: 'Allow all access'
              }
          ]
          http20Enabled: false
          functionAppScaleLimit: 200
          minimumElasticInstanceCount: 0
      }
      scmSiteAlsoStopped: false
      clientAffinityEnabled: false
      clientCertEnabled: false
      clientCertMode: 'Required'
      hostNamesDisabled: false
      containerSize: 1536
      dailyMemoryTimeQuota: 0
      httpsOnly: false
      redundancyMode: 'None'
      storageAccountRequired: false
  }
}

resource azfunctionsiteconfig 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'appsettings'
  parent: azfunctionsite
  properties: {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING:'DefaultEndpointsProtocol=https;AccountName=${discoveryStorage.name};AccountKey=${listKeys(discoveryStorage.id, discoveryStorage.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    AzureWebJobsStorage:'DefaultEndpointsProtocol=https;AccountName=${discoveryStorage.name};AccountKey=${listKeys(discoveryStorage.id, discoveryStorage.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    WEBSITE_CONTENTSHARE : discoveryStorage.name
    FUNCTIONS_WORKER_RUNTIME:'powershell'
    FUNCTIONS_EXTENSION_VERSION:'~4'
    gitHub_repoOwnerName: gitHub_repoOwnerName
    gitHub_repoName: gitHub_repoName
    gitHub_workflowId: gitHub_workflowId
    gitHub_PAT: gitHub_PAT
    resource_group: resource_group
    aml_workspace: aml_workspace
    aml_flow_deployment_name: aml_flow_deployment_name
    aml_endpoint_name: aml_endpoint_name
    aml_model_name: aml_model_name
  }
}

resource deployfunctions 'Microsoft.Web/sites/extensions@2022-09-01' = {
  parent: azfunctionsite
  dependsOn: [
    azfunctionsiteconfig
  ]
  name: 'ZipDeploy'
  properties: {
    //packageUri: '${discoveryStorage.properties.primaryEndpoints.blob}${discoveryContainerName}/${filename}?${(discoveryStorage.listAccountSAS(discoveryStorage.apiVersion, sasConfig).accountSasToken)}'
    // https://github.com/Azure/AI-in-a-Box/raw/main/ml-in-a-box/infra/PSAzureMLAlertWebhook/AzureMLAlertWebhook.zip
    packageUri: gitHub_FunctionDeploymentZip
  }
}

module functionAppRetrieveKeys './functionAppRetrieveKeys.bicep' = {
  name: 'functionAppRetrieveKeys'
  params: {
    functionname: functionname
    functionAppName: functionAppName
  }
  dependsOn: [
    deployfunctions
  ]
}

output functionAppId string = azfunctionsite.id
output functionAppUrl string = functionAppRetrieveKeys.outputs.functionAppUrl
