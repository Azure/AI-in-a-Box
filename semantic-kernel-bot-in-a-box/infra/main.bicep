param resourceLocation string
param prefix string
param msaAppId string
@secure()
param msaAppPassword string
param tags object

param deploySQL bool = true
param deploySearch bool = true
param deployDocIntel bool = true

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var appServiceName = '${prefix}-app-${uniqueSuffix}'
var openaiAccountName = '${prefix}-openai-${uniqueSuffix}'
var documentIntelligenceAccountName = '${prefix}-docs-${uniqueSuffix}'
var searchAccountName = '${prefix}-search-${uniqueSuffix}'
var cosmosAccountName = '${prefix}-cosmos-${uniqueSuffix}'
var sqlServerName = '${prefix}-sql-${uniqueSuffix}'
var sqlDBName = '${prefix}-db-${uniqueSuffix}'


module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
  }
}

module m_docs 'modules/documentIntelligence.bicep' = if (deployDocIntel) {
  name: 'deploy_docs'
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
  }
}

module m_search 'modules/searchService.bicep' = if (deploySearch) {
  name: 'deploy_search'
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
  }
}

module m_sql 'modules/sql.bicep' = if (deploySQL) {
  name: 'deploy_sql'
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
    sqlAdminLogin: msaAppId
    sqlAdminPassword: msaAppPassword
  }
}

module m_cosmos 'modules/cosmos.bicep' = {
  name: 'deploy_cosmos'
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
  }
}

module m_app 'modules/appservice.bicep' = {
  name: 'deploy_app'
  params: {
    resourceLocation: resourceLocation
    prefix: prefix
    tags: tags
    msaAppId: msaAppId
    msaAppPassword: msaAppPassword
    openaiAccountName: openaiAccountName
    documentIntelligenceAccountName: documentIntelligenceAccountName
    searchAccountName: searchAccountName
    cosmosAccountName: cosmosAccountName
    sqlServerName: sqlServerName
    sqlDBName: sqlDBName
    deploySQL: deploySQL
    deploySearch: deploySearch
    deployDocIntel: deployDocIntel
  }
  dependsOn: [
    m_openai, m_docs, m_cosmos, m_search, m_sql
  ]
}

module m_bot 'modules/botservice.bicep' = {
  name: 'deploy_bot'
  params: {
    resourceLocation: 'global'
    prefix: prefix
    tags: tags
    endpoint: 'https://${m_app.outputs.hostName}/api/messages'
    msaAppId: msaAppId
  }
}

// module m_rbac 'modules/rbac.bicep' = {
//   name: 'deploy_rbac'
//   params: {
//     appServiceName: appServiceName
//     openaiAccountName: openaiAccountName
//     documentIntelligenceAccountName: documentIntelligenceAccountName
//     searchAccountName: searchAccountName
//     cosmosAccountName: cosmosAccountName
//   }
//   dependsOn: [
//     m_app, m_openai, m_docs, m_cosmos, m_search, m_sql
//   ]
// }
