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
@secure()
param outlookEmailId string 
@secure()
param outlookEmailPassword string
param outlookConnectionName string 


// created an connection that needs to be set up manually to work 
resource outlookconnection 'Microsoft.Web/connections@2016-06-01' = {
  name: outlookConnectionName
  location: location
  properties: {
    displayName:outlookConnectionName
    parameterValues: { 
    }
    customParameterValues: {
      accountEmail:outlookEmailId      // need to research on the api spec. 
      accessKey:outlookEmailPassword   // need to research on the api spec
    }
    api: {
      name: outlookConnectionName
      displayName: outlookConnectionName
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/outlook'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

output outlookConnectionId string = outlookconnection.id
