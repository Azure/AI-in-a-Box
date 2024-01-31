/*region Header
      Module Steps 
      1 - Create IoT Hub Instance
      2 - Create Consumer Group
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param iotHubName string
param tags object = {}

@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'

@description('The number of IoT Hub units.')
param skuUnits int = 1

@description('Define the name of the storage account.')
param storageAccountName  string 

@description('Define the id of the storage account.')
param storageAccountID  string 

@description('Define the name of the container.')
param storageContainerName string

// --- Variables
var storageEndpoint = '${storageAccountName}StorageEndpont'

param consumergroupeNames array = [
  'adx-cg'
  'databricks-cg'
  'dotnet-cg'
  'fabric-cg'
  'iotexplorer-cg'
  'realtime-cg'
  'servicebusexplorer-cg'
  'streaminganalytics-cg'
  'vscode-cg'
]

// Create a Log Analytics Workspace
// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: 'iot-hub-log-analytics'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

//1. Create IoT Hub Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.devices/iothubs
resource iotHub 'Microsoft.Devices/IotHubs@2022-04-30-preview' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  tags: tags
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
    routing: {
      endpoints: {
        storageContainers: [
          {
            connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountID, '2022-09-01').keys[0].value}'
            containerName: storageContainerName
            fileNameFormat: '{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}'
            batchFrequencyInSeconds: 100
            maxChunkSizeInBytes: 104857600
            encoding: 'JSON'
            name: storageEndpoint
          }
        ]
      }
      routes: [
        {
          name: 'ContosoStorageRoute'
          source: 'DeviceMessages'
          condition: 'level="storage"'
          endpointNames: [
            storageEndpoint
          ]
          isEnabled: true
        }
      ]
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    minTlsVersion: '1.2'
  }
}

//2. Create Consumer Group
resource consumerGroup 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2022-04-30-preview' = [for name in consumergroupeNames: {
  name: '${iotHubName}/events/${name}'
  properties: {
        name: '${name}'
      }
      dependsOn: [
        iotHub
      ]
}]


//Enable all logs and metrics
//Create a diagnostic setting to send IoT Hub logs and metrics to log analytics workspace
resource iotHubDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Diag-iot-hub'
  scope: iotHub
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output iotHubName string = iotHub.name
