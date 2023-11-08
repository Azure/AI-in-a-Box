
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT licens

@description('create resource with solution accelerator tag ID')
resource resourceId 'Microsoft.Resources/deployments@2020-10-01' = {
  name: 'pid-1b1b8df6-e4d2-5a68-bd35-8d842a935d5c' 
  properties:{
    mode: 'Incremental'
    template:{
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}
