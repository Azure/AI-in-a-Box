param location string
param speechName string
param tags object = {}
param msiPrincipalID string
param publicNetworkAccess string

resource speech 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: speechName
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'SpeechServices'
  properties: {
    customSubDomainName: speechName
    apiProperties: {
      statisticsEnabled: false
    }
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: publicNetworkAccess
  }
}

output speechID string = speech.id
output speechName string = speech.name
output speechEndpoint string = speech.properties.endpoint
