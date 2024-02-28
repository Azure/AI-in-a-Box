param principalId string
param roleGuid string

resource role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'role-assignment-${roleGuid}'
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
  }
}
