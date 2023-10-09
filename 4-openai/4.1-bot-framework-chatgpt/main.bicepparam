using 'main.bicep'

param resourceLocation = 'eastus'
param prefix = 'aitoolkit'

param spokeNetworkResourceGroup = '${prefix}-spoke-nw-rg'
param appResourceGroup = '${prefix}-app-rg'

param tags = {
  Owner: 'AI Team'
  Project: 'GPTBot'
  Environment: 'Dev'
  Toolkit: 'Bicep'
}

param msaAppId = 'YOUR_APP_ID'
param msaAppPassword = 'YOUR_APP_SECRET'
