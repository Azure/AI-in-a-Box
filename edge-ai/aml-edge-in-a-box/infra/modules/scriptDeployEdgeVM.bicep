/*region Header
      Module Steps 
      1 - Deploy Edge VM

      //https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep
      //https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param environmentName string
param resourceGroupName string
param edgeDeviceName string
param iotHubName string
param uamiId string

@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param dnsLabelPrefix string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('User name for the Edge Virtual Machine.')
param adminUsername string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

//1. Get Edge Device Connection String
//https://github.com/Azure/azure-quickstart-templates/blob/master/modules/microsoft.resources/deploymentScripts/copyBlob/0.9/main.bicep

//Using Azure CLI
resource deployEdgeVMScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployEdgeVMScript'
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
    // arguments: '\'${resourceGroupName}\' \'${location}\' \'${environmentName}\' \'${iotHubName}\' \'${edgeDeviceName}\' \'${dnsLabelPrefix}\' \'${authenticationType}\' \'${adminUsername}\' \'${adminPasswordOrKey}\''
    scriptContent: loadTextContent('../../scripts/IoTEdgeDeployVM.script.sh') 
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
      {
        name: 'environmentName'
        value: environmentName
      }
      {
        name: 'iotHubName'
        value: iotHubName
      }
      {
        name: 'edgeDeviceName'
        value: edgeDeviceName
      }
      {
        name: 'dnsLabelPrefix'
        value: dnsLabelPrefix
      }
      {
        name: 'authenticationType'
        value: authenticationType
      }
      {
        name: 'adminUsername'
        value: adminUsername
      }
      {
        name: 'adminPasswordOrKey'
        secureValue: adminPasswordOrKey
      }
    ]
  }
}

//Using PowerShell
// resource deployEdgeVMScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
//   name:'deployEdgeVMScript'
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${uamiId}': {}
//     }
//   }
//   properties: {
//     forceUpdateTag: '1'
//     azPowerShellVersion: '7.2.4' // or azCliVersion: '2.28.0'
//     cleanupPreference: 'OnSuccess'
//     scriptContent: loadTextContent('../../scripts/IoTEdgeDeployVM.ps1')
//     retentionInterval: 'PT1H'
//     supportingScriptUris: []
//     timeout: 'PT30M'
//     arguments: '-resourceGroupName ${resourceGroupName} -location ${location} -AZURE_ENV_NAME ${environmentName} -iotHubName ${iotHubName } -edgeDeviceName ${edgeDeviceName} -dnsLabelPrefix ${dnsLabelPrefix} -authenticationType ${authenticationType} -adminUsername ${adminUsername} -adminPasswordOrKey ${adminPasswordOrKey} -deployEdgeVM ${deployEdgeVM}'
//     environmentVariables: [
//       {
//         name: 'resourceGroupName'
//         value: resourceGroupName
//       }
//       {
//         name: 'location'
//         value: location
//       }
//       {
//         name: 'iotHubName'
//         value: iotHubName
//       }
//       {
//         name: 'edgedeviceName'
//         value: edgeDeviceName
//       }
//       {
//         name: 'adminPasswordOrKey'
//         secureValue: adminPasswordOrKey
//       }
//     ]
//   }
// }

