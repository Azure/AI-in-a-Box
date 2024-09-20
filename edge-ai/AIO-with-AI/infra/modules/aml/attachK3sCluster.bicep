/*region Header
      Module Steps 
      1 - Attach a Kubernetes Cluster to Azure Machine Learning Workspace

      //https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-to-workspace
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param resourceGroupName string
param amlworkspaceName string
param arcK8sClusterName string
param vmUserAssignedIdentityID string


resource k3scluster 'Microsoft.Kubernetes/connectedClusters@2022-10-01-preview' existing = {
  name: arcK8sClusterName
}

//Using Azure CLI
//https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts
resource attachK3sCluster 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'attachK3sCluster'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${vmUserAssignedIdentityID}': {}
    }
  }
  properties: {
    azCliVersion: '2.64.0'
    scriptContent: loadTextContent('../../../scripts/azd_attachK3sCluster.sh')
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    timeout: 'PT1H'
    forceUpdateTag: 'v1'
    environmentVariables: [
      {
        name: 'resourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'amlworkspaceName'
        value: amlworkspaceName
      }
      {
        name: 'arcK8sClusterName'
        value: arcK8sClusterName
      }
      {
        name: 'arcK8sClusterId'
        value: k3scluster.id
      }
      {
        name: 'vmUserAssignedIdentityID'
        value: vmUserAssignedIdentityID
      }
      {
        name: 'subscription'
        value: subscription().subscriptionId
      }
    ]
  }
}

