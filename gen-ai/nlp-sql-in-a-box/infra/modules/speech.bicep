/*region Header
      Module Steps 
      1 - Create Speech Service
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param speechServiceName string
param tags object = {}

// Create Speech Service resource
resource speechService 'Microsoft.CognitiveServices/accounts@2022-03-01' = {
  name: speechServiceName // Set the name of the Speech Service
  location: location // Set the location of the Speech Service
  kind: 'SpeechServices' // Set the kind of the Speech Service to SpeechServices
  sku: {
    name: 'S0' // Set the SKU name to S0
    tier: 'Standard' // Set the SKU tier to Standard
  }
  properties: {
    customSubDomainName: speechServiceName // Set the custom subdomain name for the Speech Service
  }
  tags: tags
  identity: {
    type: 'SystemAssigned' // Enable managed identity for the Speech Service
  }
}

output speechServiceID string = speechService.id
output speechServiceName string = speechService.name
output speechServiceEndpoint string = speechService.properties.endpoint
