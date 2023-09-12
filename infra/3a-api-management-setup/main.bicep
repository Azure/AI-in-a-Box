@description('The name of the API Management service instance')
param apiManagementServiceName string = 'apiservice${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  1
  2
])
param skuCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}



resource primarybackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'primary'
  parent: apiManagementService
  properties: {
    description: 'Primary LLM deployment endpoint'
    protocol: 'http'
    url: 'string'
  }
}

resource secondarybackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'secondary'
  parent: apiManagementService
  properties: {
    description: 'Secondary LLM deployment endpoint'
    protocol: 'http'
    url: 'string'
  }
}


resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  name: 'GPT-3.5'
  parent: apiManagementService
  properties: {
    format: 'openapi'
    value: loadTextContent('openapi.json')
  }
}


resource policy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'xml'
    value: loadTextContent('policy.xml')
  }
}