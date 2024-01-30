/*region Header
      Module Steps 
      1 - Create Edge Devices

      //https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep
      //https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param resourceGroupName string
param uamiId string


//1. Create IoT Edge Devices
//https://github.com/Azure/azure-quickstart-templates/blob/master/modules/microsoft.resources/deploymentScripts/copyBlob/0.9/main.bicep
resource deployEdgeDevices 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployEdgeDevices'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    azCliVersion: '2.54.0'
    //arguments: '\'${resourceGroupName}\' \'${location}\''
    scriptContent: loadTextContent('../../scripts/IoTRegisterEdgeDevices.script.sh') 
    retentionInterval: 'PT1H'
    cleanupPreference: 'Always'
    timeout: 'PT30M'
    forceUpdateTag: 'v1'
    environmentVariables: [
      {
        name: 'resourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'location'
        value: location
      }
    ]
  }
}
