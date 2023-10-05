using 'main.bicep'

param resourceLocation = 'eastus'
param prefix = 'aitoolkit'

param coreNetworkResourceGroup = '${prefix}-core-nw-rg'
param spokeNetworkResourceGroup = '${prefix}-spoke-nw-rg'
param appResourceGroup = '${prefix}-app-rg'

param coreNetworkingTags = {
  Owner: 'Core Networking Team'
  Project: 'Enterprise Landing Zone'
  Environment: 'Core'
  Toolkit: 'Bicep'
}
param spokeNetworkingTags = {
  Owner: 'Core Networking Team'
  Project: 'AI Core'
  Environment: 'Dev'
  Toolkit: 'Bicep'
}
param projectTags = {
  Owner: 'AI Team'
  Project: 'AI Project 1'
  Environment: 'Dev'
  Toolkit: 'Bicep'
}

param existingHubName = ''
