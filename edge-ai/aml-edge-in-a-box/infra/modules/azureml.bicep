/*region Header
      Module Steps 
      1 - Create ML Workspace
      2 - Create ML Workspace Compute Instance
      https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.machinelearningservices/machine-learning-end-to-end-secure/README.md
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param workspaceName string
param amlcompclustername string
param amlcompinstancename string
param storageAccountId string
param keyvaultId string
param aisnId string
param systemDatastoresAuthMode string = 'identity'
param hbi_workspace bool = false
param acrId string
param tags object = {}


//1. Deploy Machine Learning Workspace
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
resource amlwn 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' = {
  identity: {
    type: 'SystemAssigned'
  }
  name: workspaceName
  location: location
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccountId
    keyVault: keyvaultId
    applicationInsights: aisnId
    hbiWorkspace: hbi_workspace
    systemDatastoresAuthMode: systemDatastoresAuthMode
    containerRegistry: acrId
  }
  tags: tags
}

//2. Deploy ML Workspace Compute Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces/computes?pivots=deployment-language-bicep
resource amlcompcluster 'Microsoft.MachineLearningServices/workspaces/computes@2023-06-01-preview' = {
  parent: amlwn
  name: amlcompclustername
  location: location
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

//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces/computes?pivots=deployment-language-bicep
resource amlcompinstance 'Microsoft.MachineLearningServices/workspaces/computes@2023-06-01-preview' = {
  parent: amlwn
  name: amlcompinstancename
  location: location
  properties: {
    computeType: 'ComputeInstance'
    computeLocation: location
    description: 'Machine Learning compute instance 001'
    properties: {
      // schedules: {
      //   computeStartStop: [
      //     {
      //       action: 'Stop'
      //       // cron: {
      //       //   expression: '*/30 * * * *'
      //       //   startTime: 'string'
      //       //   timeZone: 'eastus'
      //       // }
      //       recurrence: {
      //         frequency: 'Week'
      //         interval: 1
      //         schedule: {
      //           hours: [
      //             6
      //           ]
      //           minutes: [
      //             30
      //           ]
      //           weekDays: [
      //             'Monday'
      //             'Tuesday'
      //             'Wednesday'
      //             'Thursday'
      //             'Friday'
      //           ]
      //         }
      //         startTime:  '2024-01-29T18:30:30'  
      //         timeZone: 'Eastern Standard Time'
      //       }
      //       status: 'Enabled'
      //       triggerType: 'Recurrence'
      //     }
      //   ]
      // }

      vmSize: 'Standard_DS3_v2'
    }
  }
}

// var azureRBACStorageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
// //var azureRBACOwnerRoleID = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Owner: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner

// //Reference existing resources for permission assignment scope
// resource stgRef 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
//   name: storageAccountName
// }

// //3. Assign Storage Blob Data Contributor Role to ML Workspace in the Raw Data Lake Account as per https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions#grant-the-managed-identity-permissions-to-adls-gen2-storage-account
// //Create and apply RBAC to your ML workspace managed identity to the storage account -ML Workspace Role Assignment as Blob Data Contributor Role in the Data Lake Storage Account
// resource r_eWorkspacetorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
//   name: guid(resourceId('Microsoft.Storage/storageAccounts', workspaceName), stgRef.name)
//   scope: stgRef
//   properties:{
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
//     principalId: amlwn.identity.principalId
//     principalType:'ServicePrincipal'
//   }
// }

output azuremlworkspaceId string = amlwn.id
output amlworkspaceName string = amlwn.name
