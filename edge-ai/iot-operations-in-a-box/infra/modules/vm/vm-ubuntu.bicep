param subnetId string
param publicIPId string = ''
param virtualMachineName string
param arcK8sClusterName string
param adminUsername string
#disable-next-line secure-secrets-in-params
param adminPasswordOrKey string
param virtualMachineSize string
param scriptURI string
param ShellScriptName string
param nsgId string = ''
param Location string = resourceGroup().location
param authenticationType string = 'password'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var nicName = '${virtualMachineName}-NIC'

module nic '../vnet/nic.bicep' = {
  name: nicName
  params:{
    Location: Location
    nicName: nicName
    subnetId: subnetId
    publicIPId: publicIPId
    nsgId: nsgId
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: virtualMachineName
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        osType: 'Linux'
        diskSizeGB: 80
      }
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.outputs.nicId
          properties:{
            primary: true
          }
        }
      ]
    }
  }
}

module roleOnboarding '../identity/role.bicep' = {
  name: 'virtualMachineName-roleOnboarding'
  scope: resourceGroup()
  params:{
    principalId: vm.identity.principalId
    roleGuid: '34e09817-6cbe-4d01-b1a2-e0eac5743d41' // Kubernetes Cluster - Azure Arc Onboarding
  }
}

module roleK8sExtensionContributor '../identity/role.bicep' = {
  name: 'virtualMachineName-roleK8sExtensionContributor'
  scope: resourceGroup()
  params:{
    principalId: vm.identity.principalId
    roleGuid: '85cb6faf-e071-4c9b-8136-154b5a04f717' // Kubernetes Extension Contributor
  }
}

// resource vmext 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
//   parent: vm
//   name: 'CustomScript'
//   location: Location
//   properties: {
//     publisher: 'Microsoft.OSTCExtensions'
//     type: 'CustomScriptForLinux'
//     typeHandlerVersion: '1.5'
//     autoUpgradeMinorVersion: false
//     settings:{
//       fileUris: [
//         '${scriptURI}${ShellScriptName}'
//       ]
//       commandToExecute: 'sh ${ShellScriptName} ${resourceGroup().name} ${arcK8sClusterName} ${Location}'
//     }
//   }
//   dependsOn: [
//     roleOnboarding
//     roleK8sExtensionContributor
//   ]
// }

resource vmext 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'CustomScript'
  location: Location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings:{
      fileUris: [
        '${scriptURI}${ShellScriptName}'
      ]
      commandToExecute: 'sh ${ShellScriptName} ${resourceGroup().name} ${arcK8sClusterName} ${Location}'
    }
  }
  dependsOn: [
    roleOnboarding
    roleK8sExtensionContributor
  ]
}

output nicIP string = nic.outputs.nicIP
output untrustedNicProfileId string = nic.outputs.nicIpConfigurationId
output virtualMachinePrincipalId string = vm.identity.principalId
