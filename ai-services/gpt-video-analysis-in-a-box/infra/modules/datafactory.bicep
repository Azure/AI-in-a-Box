param dataFactoryName string
param resourceLocation string
param uamiId string

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: resourceLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}


