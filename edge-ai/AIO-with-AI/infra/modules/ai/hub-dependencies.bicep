/*region Header
      Module Steps 
      1 - Creates Azure dependent resources for Azure AI studio
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('AI services name')
param aiServicesName string

@description('Array of OpenAI model deployments')
param openAiModelDeployments array = []

module aiServices '../ai/cognitiveservices.bicep' = {
  name: 'cognitiveServices'
  params: {
    location: location
    aiServicesName: aiServicesName
    kind: 'AIServices'
    deployments: openAiModelDeployments
    authMode: 'accessKey'
  }
}

output openAiId string = aiServices.outputs.id
output openAiName string = aiServices.outputs.name
output openAiEndpoint string = aiServices.outputs.endpoint
output openAiEndpoints string = aiServices.outputs.endpoints['OpenAI Language Model Instance API']
