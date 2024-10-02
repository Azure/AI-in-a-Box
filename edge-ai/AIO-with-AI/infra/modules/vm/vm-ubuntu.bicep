/*region Header
      Module Steps
      1 - Create NIC
      2 - Create VM
      3 - Assign Role to VM
      4 - Create VM Extension
      5 - Output NIC IP
      6 - Output Untrusted NIC Profile ID
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string = resourceGroup().location
param virtualMachineSize string
param virtualMachineName string
param arcK8sClusterName string
param adminUsername string
#disable-next-line secure-secrets-in-params
@secure()
param adminPasswordOrKey string
param authenticationType string = 'password'
param vmUserAssignedIdentityID string
param vmUserAssignedIdentityPrincipalID string

param subnetId string
param publicIPId string = ''
param nsgId string = ''
param keyVaultId string
param keyVaultName string

param spAppId string
#disable-next-line secure-secrets-in-params
@secure()
param spSecret string
param spObjectId string
param spAppObjectId string

param scriptURI string
param ShellScriptName string

param customLocationRPSPID string

var osDiskType = 'Premium_LRS'

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

var nicName = '${virtualMachineName}-nic'

module nic '../vnet/nic.bicep' = {
  name: 'deployVMNic'
  params:{
    location: location
    nicName: nicName
    subnetId: subnetId
    publicIPId: publicIPId
    nsgId: nsgId
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/2023-07-01/virtualmachines?pivots=deployment-language-bicep
resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: virtualMachineName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${vmUserAssignedIdentityID}':{}
    }
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
        caching: 'ReadWrite'
        createOption: 'FromImage'
        osType: 'Linux'
        diskSizeGB: 80
        managedDisk: {
          storageAccountType: osDiskType
        }
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

module roleArcAdminRole '../identity/role.bicep' = {
  name: 'deployVMRole_AzureArcClusterAdminRole'
  scope: resourceGroup()
  params:{
    principalId: vmUserAssignedIdentityPrincipalID
    roleGuid: '8393591c-06b9-48a2-a542-1bd6b377f6a2' // Kubernetes Cluster - Azure Kubernetes Service Arc Cluster Admin Role - Lets you manage all resources in the cluster.
  }
}

module roleOnboarding '../identity/role.bicep' = {
  name: 'deployVMRole_AzureArcOnboarding'
  scope: resourceGroup()
  params:{
    principalId: vmUserAssignedIdentityPrincipalID
    roleGuid: '34e09817-6cbe-4d01-b1a2-e0eac5743d41' // Kubernetes Cluster - Azure Arc Onboarding
  }
}

module roleAcrPull '../identity/role.bicep' = {
  name: 'deployVMRole_AcrPull'
  scope: resourceGroup()
  params:{
    principalId: vmUserAssignedIdentityPrincipalID
    roleGuid: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // Acro Pull
  }
}

module roleK8sExtensionContributor '../identity/role.bicep' = {
  name: 'deployVMRole_K8sExtensionContributor'
  scope: resourceGroup()
  params:{
    principalId: vmUserAssignedIdentityPrincipalID
    roleGuid: '85cb6faf-e071-4c9b-8136-154b5a04f717' // Kubernetes Extension Contributor
  }
}

module roleContributor '../identity/role.bicep' = {
  name: 'deployVMRole_Contributor'
  scope: resourceGroup()
  params:{
    principalId: vmUserAssignedIdentityPrincipalID
    roleGuid: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
}

module roleOwner '../identity/role.bicep' = {
  name: 'deployVMRole_Owner'
  scope: resourceGroup()
  params:{
    principalId: vmUserAssignedIdentityPrincipalID
    roleGuid: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  }
}

resource vmext 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'installscript_k3s'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings:{
      fileUris: [
        '${scriptURI}${ShellScriptName}'
      ]
      commandToExecute: 'sh ${ShellScriptName} ${resourceGroup().name} ${arcK8sClusterName} ${location} ${adminUsername} ${vmUserAssignedIdentityPrincipalID} ${customLocationRPSPID} ${keyVaultId} ${keyVaultName} ${subscription().subscriptionId} ${spAppId} ${spSecret} ${subscription().tenantId} ${spObjectId} ${spAppObjectId}'
    }
  }
  dependsOn: [
    roleOnboarding
    roleK8sExtensionContributor
    roleContributor
    roleOwner
    roleAcrPull
  ]
}

output nicIP string = nic.outputs.nicIP
output untrustedNicProfileId string = nic.outputs.nicIpConfigurationId
//output virtualMachinePrincipalId string = vm.identity.principalId
