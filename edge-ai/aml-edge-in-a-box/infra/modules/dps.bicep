/*region Header
      Module Steps 
      1 - Create IoT Hub Instance
      2 - Create Consumer Group
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param dpsName string
param iotHubName string
param tags object = {}

@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'

@description('The number of IoT Hub units.')
param skuUnits int = 1

var iotHubKey = 'iothubowner'

//Retrieve the name of the newly created key vault
resource iotRef 'Microsoft.Devices/IotHubs@2022-04-30-preview' existing = {
  name: iotHubName
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.devices/provisioningservices
//1. Create IoT Device Provisioning Service
resource provisioningService 'Microsoft.Devices/provisioningServices@2022-02-05' = {
  name: dpsName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    allocationPolicy: 'GeoLatency'
    iotHubs: [
      {
        connectionString: 'HostName=${iotRef.properties.hostName};SharedAccessKeyName=${iotHubKey};SharedAccessKey=${iotRef.listkeys().value[0].primaryKey}'
        location: location
      }
    ]
  }
  tags: tags
}
