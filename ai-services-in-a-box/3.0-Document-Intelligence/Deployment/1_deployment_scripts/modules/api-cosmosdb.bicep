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
param cosmosAccountName string
param cosmosDbConnectionWithKey string
@secure()
param paramCosmosAccountKey string

// this one sets up an active connection
resource cosmosdbconnectionkey 'Microsoft.Web/connections@2016-06-01' = {
  name: cosmosDbConnectionWithKey
  location: location
  properties: {
    displayName: cosmosDbConnectionWithKey
    parameterValues: {
      databaseAccount:cosmosAccountName
      accessKey:paramCosmosAccountKey
    }
    customParameterValues:{
    }
    api: {
      name: 'documentdb'
      displayName: cosmosDbConnectionWithKey
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/documentdb'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

output cosmosDbConnectionId string = cosmosdbconnectionkey.id







