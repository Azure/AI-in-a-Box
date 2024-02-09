targetScope = 'subscription'

param location string
param environmentName string
param resourceGroupName string = ''

param tags object

param openaiName string = ''

@allowed(['gpt-4', 'gpt-4-32k'])
param gptModel string
@allowed(['0613', '1106-Preview'])
param gptVersion string

param msiName string = ''
param appServicePlanName string = ''
param appServiceName string = ''
param botServiceName string = ''
param cosmosName string = ''
param speechName string = ''

param storageName string = ''
param deployDalle3 bool = false
param deploySpeech bool
@description('Deploy Speech service?')

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string

var abbrs = loadJsonContent('abbreviations.json')

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup.id), 1, 3) 

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module m_msi 'modules/msi.bicep' = {
  name: 'deploy_msi'
  scope: resourceGroup
  params: {
    location: location
    msiName: !empty(msiName) ? msiName : '${abbrs.managedIdentityUserAssignedIdentities}${environmentName}-${uniqueSuffix}'
    tags: tags
  }
}

module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  scope: resourceGroup
  params: {
    location: location
    openaiName: !empty(openaiName) ? openaiName : '${abbrs.cognitiveServicesOpenAI}${environmentName}-${uniqueSuffix}'
    gptModel: gptModel
    gptVersion: gptVersion
    msiPrincipalID: m_msi.outputs.msiPrincipalID
    publicNetworkAccess: publicNetworkAccess
    deployDalle3: deployDalle3
    tags: tags
  }
}

module m_speech 'modules/speech.bicep' = if (deploySpeech) {
  name: 'deploy_speech'
  scope: resourceGroup
  params: {
    location: location
    speechName: !empty(speechName) ? speechName : '${abbrs.cognitiveServicesSpeech}${environmentName}-${uniqueSuffix}'
    msiPrincipalID: m_msi.outputs.msiPrincipalID
    publicNetworkAccess: publicNetworkAccess
    tags: tags
  }
}

module m_storage 'modules/storage.bicep' = {
  name: 'deploy_storage'
  scope: resourceGroup
  params: {
    location: location
    storageName: !empty(storageName) ? storageName : '${abbrs.storageStorageAccounts}${replace(replace(environmentName,'-',''),'_','')}${uniqueSuffix}'
    msiPrincipalID: m_msi.outputs.msiPrincipalID
    publicNetworkAccess: publicNetworkAccess
    tags: tags
  }
}

module m_cosmos 'modules/cosmos.bicep' = {
  name: 'deploy_cosmos'
  scope: resourceGroup
  params: {
    location: location
    cosmosName: !empty(cosmosName) ? cosmosName : '${abbrs.documentDBDatabaseAccounts}${environmentName}-${uniqueSuffix}'
    msiPrincipalID: m_msi.outputs.msiPrincipalID
    publicNetworkAccess: publicNetworkAccess
    tags: tags
  }
}

module m_app 'modules/appservice.bicep' = {
  name: 'deploy_app'
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${environmentName}-${uniqueSuffix}'
    appServiceName: !empty(appServiceName) ? appServiceName : '${abbrs.webSitesAppService}${environmentName}-${uniqueSuffix}'
    tags: tags
    msiID: m_msi.outputs.msiID
    msiClientID: m_msi.outputs.msiClientID
    openaiName: m_openai.outputs.openaiName
    openaiEndpoint: m_openai.outputs.openaiEndpoint
    openaiGPTModel: m_openai.outputs.openaiGPTModel
    openaiEmbeddingsModel: m_openai.outputs.openaiEmbeddingsModel
    speechName: deploySpeech ? m_speech.outputs.speechName : ''
    speechEndpoint: deploySpeech ? m_speech.outputs.speechEndpoint : ''
    cosmosEndpoint: m_cosmos.outputs.cosmosEndpoint
    storageName: m_storage.outputs.storageName
  }
}

module m_bot 'modules/botservice.bicep' = {
  name: 'deploy_bot'
  scope: resourceGroup
  params: {
    location: 'global'
    botServiceName: !empty(botServiceName) ? botServiceName : '${abbrs.cognitiveServicesBot}${environmentName}-${uniqueSuffix}'
    tags: tags
    endpoint: 'https://${m_app.outputs.hostName}/api/messages'
    msiClientID: m_msi.outputs.msiClientID
    msiID: m_msi.outputs.msiID
    publicNetworkAccess: publicNetworkAccess
  }
}

output AZURE_RESOURCE_GROUP_ID string = resourceGroup.id
output AZURE_RESOURCE_GROUP_NAME string = resourceGroup.name
