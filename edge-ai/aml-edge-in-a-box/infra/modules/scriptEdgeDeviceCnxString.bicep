/*region Header
      Module Steps 
      1 - Get Edge Device Connection String

      //https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep
      //https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param resourceGroupName string
param edgeDeviceName string
param iotHubName string
param uamiId string


//1. Get Edge Device Connection String
//https://github.com/Azure/azure-quickstart-templates/blob/master/modules/microsoft.resources/deploymentScripts/copyBlob/0.9/main.bicep
resource getDeviceCnxScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name:'getDeviceCnxScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    forceUpdateTag: '1'
    azPowerShellVersion: '7.2.4' // or azCliVersion: '2.28.0'
    cleanupPreference: 'OnSuccess'
    scriptContent: loadTextContent('../../scripts/IoTEdgeDeviceCnxString.ps1')
    retentionInterval: 'PT1H'
    supportingScriptUris: []
    timeout: 'PT30M'
    arguments: '-resourceGroupName ${resourceGroupName} -location ${location} -iotHubName ${iotHubName } -edgeDeviceName ${edgeDeviceName}'
    environmentVariables: [
      {
        name: 'resourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'location'
        value: location
      }
      {
        name: 'iotHubName'
        value: iotHubName
      }
      {
        name: 'edgedeviceName'
        value: edgeDeviceName
      }
    ]
  }
}

output result string = getDeviceCnxScript.properties.outputs.text
