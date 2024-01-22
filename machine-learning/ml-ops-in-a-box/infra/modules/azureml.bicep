param resourceLocation string = resourceGroup().location
param workspaceName string
param amlcomputename string
param storageAccountId string
param keyvaultId string
param aisnId string
param hbi_workspace bool = false

//4. Deploy Machine Learning Workspace
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
resource amlwn 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  name: workspaceName
  location: resourceLocation
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccountId
    keyVault: keyvaultId
    applicationInsights: aisnId
    hbiWorkspace: hbi_workspace
  }
}

//5. Deploy ML Workspace Compute Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces/computes?pivots=deployment-language-bicep
resource amlwcompute 'Microsoft.MachineLearningServices/workspaces/computes@2023-06-01-preview' = {
  parent: amlwn
  name: amlcomputename
  location: resourceLocation
  properties: {
    computeType: 'AmlCompute'
    properties: {
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 1
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
      vmPriority: 'Dedicated'
      vmSize: 'Standard_DS3_v2'
    }
  }
}
 output azuremlworkspaceId string = amlwn.id
