//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param storageAccountName string
param principalId string
param principalType string


// Reference: Azure built-in roles
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

// principalType: User, Group, ServicePrincipal, Unknown, 
// DirectoryRoleTemplate, Application, MSI, DirectoryObjectOrGroup, Everyone

var roleIDStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageRoleAssignmentId = guid('blobcontributor-${uniqueString(principalId)}')

resource adls 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource assignStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name:storageRoleAssignmentId
  dependsOn:[
     adls
  ]
  properties:{
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',roleIDStorageBlobDataContributor)
    principalType:principalType
  }
 }


 