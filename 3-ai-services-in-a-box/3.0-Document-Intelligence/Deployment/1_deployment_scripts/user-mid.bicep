// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

param midName string
param location string

resource userAssignedMid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: midName
  location: location
  tags: {
    SA : 'Azure Safety Form Processing Automation'
  }
}

output midId string = userAssignedMid.id
output midClientid string = userAssignedMid.properties.clientId
output midPrincipleId string = userAssignedMid.properties.principalId
