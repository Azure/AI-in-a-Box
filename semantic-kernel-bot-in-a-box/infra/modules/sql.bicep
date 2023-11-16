param resourceLocation string
param prefix string
param tags object = {}
param sqlAdminLogin string
@secure()
param sqlAdminPassword string

var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup().id), 1, 3) 
var sqlServerName = '${prefix}-sql-${uniqueSuffix}'
var sqlDBName = '${prefix}-db-${uniqueSuffix}'


resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: resourceLocation
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
  }

  resource fw 'firewallRules' = {
    name: 'default-fw'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDBName
  location: resourceLocation
  properties: {
    sampleName: 'AdventureWorksLT'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

output sqlServer string = sqlServer.id
output sqlDB string = sqlDB.id
