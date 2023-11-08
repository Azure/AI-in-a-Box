//====================================================================================
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//====================================================================================
//
// Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
// August 2022
//
//====================================================================================

//targetScope = 'subscription'
targetScope = 'resourceGroup'

param location string = 'eastus'
param resourceGroupName string  = 'Resource-Group-Name'
param resourceNamePrefix string = 'resourceNamePrefix'

var outlookConnectionName = '${resourceNamePrefix}OutlookConnectionTest'

//====================================================================================
// Reusing Resources already created
//====================================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
  scope:subscription()
}


module apioutlookdebug 'api-outlook.bicep' = {
  name: 'module-apioutlook2'
  scope: resourceGroup
  params: {
    location: location
    outlookEmailId:''
    outlookEmailPassword:''
    outlookConnectionName: outlookConnectionName
  }
}


output outlookConnection string = outlookConnectionName

//$resourceGroupName = 'Resource-Group-Name" 
//az deployment group create --resource-group $resourceGroupName --template-file _api_outlook_test.bicep 
