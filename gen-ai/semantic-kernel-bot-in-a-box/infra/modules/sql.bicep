param location string
param sqlServerName string
param sqlDBName string
param tags object = {}
param msiPrincipalID string
param msiClientID string
param publicNetworkAccess string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administrators: {
      azureADOnlyAuthentication: true
      principalType: 'Application'
      administratorType: 'ActiveDirectory'
      login: msiPrincipalID
      sid: msiPrincipalID
      tenantId: tenant().tenantId
    }
    publicNetworkAccess: publicNetworkAccess
  }

  resource fw 'firewallRules' = if (publicNetworkAccess == 'Enabled') {
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
  location: location
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
output sqlConnectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDB.name};Persist Security Info=False;Authentication=Active Directory MSI; User Id=${msiClientID};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
