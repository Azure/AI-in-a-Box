//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

param location string
param storageAccountName string
param adlsConnectionWithKey string
@secure()
param paramAdlsPrimaryKey string

// this one sets up an active connection
resource adlsconnectionkey 'Microsoft.Web/connections@2016-06-01' = {
  name: adlsConnectionWithKey
  location: location
  properties: {
    displayName: adlsConnectionWithKey
    parameterValues: {
      accountName:storageAccountName
      accessKey:paramAdlsPrimaryKey
    }
    api: {
      name: 'azureblob'
      displayName: 'Azure Blob Storage'
      id:'/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
      type:'Microsoft.Web/locations/managedApis'
    }
  }
}

output adlsConnectionId string = adlsconnectionkey.id








