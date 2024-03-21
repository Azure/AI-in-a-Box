/*region Header
      Module Steps 
      1 - Assign Storage Blob Data Contributor Role to a User, Group, Service Principal, or Managed Identity
      
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param storageAccountName string
param principalId string
param principalType string

// Reference: Azure built-in roles
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

// principalType: User, Group, ServicePrincipal, Unknown, 
// DirectoryRoleTemplate, Application, MSI, DirectoryObjectOrGroup, Everyone

var roleIDStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
//var azureRBACOwnerRoleID = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Owner: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner
var storageRoleAssignmentId = guid('blobcontributor-${uniqueString(principalId)}')

//Reference existing resources for permission assignment scope
resource adls 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments
//1. Assign Storage Blob Data Contributor Role to a User, Group, Service Principal, or Managed Identity
resource assignStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: storageRoleAssignmentId
  dependsOn: [
    adls
  ]
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleIDStorageBlobDataContributor)
    principalType: principalType
  }
}
