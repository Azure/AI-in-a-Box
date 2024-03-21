/*region Header
      Module Steps 
      1 - Create Azure Container Registry
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param acrName string
param tags object = {}

@description('The SKU to use for the IoT Hub.')
param acrSku string = 'Standard'

//https://learn.microsoft.com/en-us/azure/templates/microsoft.containerregistry/2023-01-01-preview/registries
//https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-bicep
//1. Create Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
  tags: tags
}

@description('Output the login server property for later use')
output acrloginServer string = acr.properties.loginServer
output acrName string = acr.name
output acrId string = acr.id
