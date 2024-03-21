targetScope = 'resourceGroup'

param resourceGroupName string 
param resourceLocation string // as of 2024-01-23, GPT4V is only available in westus in the US, storage account must be in the same region as OpenAI resource
param resourceLocationCV string  // as of 2024-01-23, CV with image analysis 4.0 is only available in eastus in the US
@description('Your Object ID')
param spObjectId string   //This is your own users Object ID
param prefix string 
param suffix string 

var gpt4vDeploymentName = 'gpt-4v'
var gpt4vModelName = 'gpt-4'
var gptVersion = 'vision-preview'

var vprefix = toLower('${prefix}')
var vsuffix = toLower('${suffix}')

var uamiResourceName = toLower('${vprefix}uami${vsuffix}')

//Key Vault Module Parameters
var keyVaultName = '${vprefix}-kv-${vsuffix}'

//CosmosDB Module Parameters
var cosmosAccountName = '${vprefix}-cosmos-${vsuffix}'
var cosmosDbName = 'gpt4vresults-db' // preset for solution
var cosmosDbContainerName = 'gptoutput' // preset for solution

//Storage Module Parameters
var storageAccountName = '${vprefix}storage${vsuffix}'

var containers = [
  'videosin'
  'videosprocessed'
]

var computerVisionName = '${vprefix}-cv-${vsuffix}'

var factoryName = '${vprefix}-adf-${vsuffix}'

var openaiName = '${vprefix}-openai-${vsuffix}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: resourceGroupName
  scope: subscription()
}

// Deploy UAMI
module m_uaManagedIdentity 'modules/uami.bicep' = {
  name: 'deploy_UAMI'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    uamiResourceName: uamiResourceName
  }
}

// Deploy Key Vault
module m_keyvault 'modules/keyvault.bicep' = {
  name: 'deploy_keyvault'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    keyVaultName: keyVaultName
    principalId: m_uaManagedIdentity.outputs.uamiPrincipleId
    spObjectId: spObjectId
 }
 dependsOn: [
  m_uaManagedIdentity
]
}

module m_storage 'modules/storage.bicep' = {
  name: 'deploy_storage'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    storageAccountName: storageAccountName
    containerList: containers
    keyVaultName: keyVaultName
    uamiId: m_uaManagedIdentity.outputs.uamiId
    principalId: m_uaManagedIdentity.outputs.uamiPrincipleId
  }
  dependsOn: [
    m_keyvault
  ]
}

module m_cosmosdb 'modules/cosmosdb.bicep' = {
  name: 'deploy_cosmosdb'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    cosmosAccountName: cosmosAccountName
    cosmosDbName: cosmosDbName
    cosmosDbContainerName: cosmosDbContainerName
    uamid: m_uaManagedIdentity.outputs.uamiId
    principalId: m_uaManagedIdentity.outputs.uamiPrincipleId
  }
  dependsOn: [
    m_keyvault
  ]
}

module m_computervision 'modules/computervision.bicep' = {
  name: 'deploy_computervision'
  scope: resourceGroup
  params: {
    cvLocation: resourceLocationCV
    keyVaultName: keyVaultName
    cvName: computerVisionName
    uamiId:  m_uaManagedIdentity.outputs.uamiId
  }
  dependsOn: [
    m_keyvault
  ]
}
 module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    keyVaultName: keyVaultName
    openaiName: openaiName
    gptDeploymentName: gpt4vDeploymentName
    gptModelName: gpt4vModelName
    gptModelVersion: gptVersion
    principalId: m_uaManagedIdentity.outputs.uamiPrincipleId
    publicNetworkAccess: 'Enabled'
    uamiId: m_uaManagedIdentity.outputs.uamiId
  }
  dependsOn: [
    m_keyvault
    m_storage
  ]
} 

module m_datafactory 'modules/datafactory.bicep' = {
  name: 'deploy_datafactory'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    dataFactoryName: factoryName
    uamiId: m_uaManagedIdentity.outputs.uamiId
    
  }
  dependsOn: [
    m_keyvault
    m_storage
    m_cosmosdb
    m_computervision
    m_openai
  ]
}

module m_adfpipelines 'modules/adfpipelines.bicep' = {
  name: 'deploy_adfpipelines'
  scope: resourceGroup
  params: {
    factoryName: factoryName
    cosmosDBEndpoint: m_cosmosdb.outputs.cosmosDBEndpoint
    cosmosdb:cosmosDbName
    cosmoscontainer: cosmosDbContainerName
    keyvaulturl: m_keyvault.outputs.keyvaulturl
    storageaccounturl: m_storage.outputs.storageaccounturl
    storageaccountcontainer: containers[0]
    opeanaibasiurl: m_openai.outputs.openaiBaseUrl
    uamiID: m_uaManagedIdentity.outputs.uamiId
    gpt4vdeploymentname: gpt4vDeploymentName

  }
  dependsOn: [
    m_keyvault
    m_storage
    m_cosmosdb
    m_computervision
    m_openai
    m_datafactory
  ] 
}
