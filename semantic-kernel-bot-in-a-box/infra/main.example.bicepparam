using 'main.bicep'

param resourceLocation = 'eastus'
param prefix = 'aitoolkit'

param tags = {
  Owner: 'AI Team'
  Project: 'GPTBot'
  Environment: 'Dev'
  Toolkit: 'Bicep'
}

param deployDocIntel = true
param deploySearch = true
param deploySQL = true

param msaAppId = 'YOUR_APP_ID'
param msaAppPassword = 'YOUR_APP_SECRET'
