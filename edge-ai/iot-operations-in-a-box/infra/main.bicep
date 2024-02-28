targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Parameters
@sys.description('VM size, please choose a size which have enough memory and CPU for K3s.')
param virtualMachineSize string = 'Standard_B4ms'

@sys.description('Ubuntu K3s Manchine Name')
param virtualMachineName string

@description('Username for the Virtual Machine.')
param adminUsername string = 'azureuser'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@sys.description('Arc for Kubernates Cluster Name')
param arcK8sClusterName string

@sys.description('Virtual Nework Name. This is a required parameter to build a new VNet or find an existing one.')
param virtualNetworkName string = 'IoT-Ops-VNET'

@sys.description('Virtual Network Address Space.')
param VNETAddress array = [
  '10.0.0.0/16'
]

@sys.description('IoT Ops Subnet Address Space.')
param subnetCIDR string = '10.0.0.0/24'

@sys.description('URI for Custom K3s VM Script and Config')
param scriptURI string = 'https://raw.githubusercontent.com/Azure/AI-in-a-Box/iot-operations-in-a-box/edge-ai/iot-operations-in-a-box/scripts/'

@sys.description('Shell Script to be executed')
param ShellScriptName string = 'script.sh'

// Variables
var subnetName = 'IoT-Ops-Subnet'
var publicIPAddressName = '${virtualMachineName}-PublicIP'
var networkSecurityGroupName = '${virtualMachineName}-NSG'

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var prefix = '${environmentName}-${resourceToken}'

// Resources

// Create resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
}

// Create NSG
module nsg 'modules/vnet/nsg.bicep' = {
  name: networkSecurityGroupName
  scope: resourceGroup
  params: {
    location: location
    nsgName:  replace('${take(prefix,19)}-${networkSecurityGroupName}', '--', '-')
    securityRules: [
      {
        name: 'In-SSH'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: '*'
          destinationPortRange: '22'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Create VNET
module vnet 'modules/vnet/vnet.bicep' = {
  name: virtualNetworkName
  scope: resourceGroup
  params: {
    location: location
    vnetAddressSpace: VNETAddress
    vnetName: replace('${take(prefix,19)}-${virtualNetworkName}', '--', '-')
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetCIDR
        }
      }
    ]
  }
}

// Build reference of existing subnets
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  scope: resourceGroup
  name: '${vnet.outputs.vnetName}${subnetName}'
}

// Create OPNsense Public IP
module publicip 'modules/vnet/publicip.bicep' = {
  name: publicIPAddressName
  scope: resourceGroup
  params: {
    location: location
    publicipName: replace('${take(prefix,19)}-${publicIPAddressName}', '--', '-')
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
    }
  }
}

// Create Ubuntu VM for K3s
module vm 'modules/vm/vm-ubuntu.bicep' = {
  name: virtualMachineName
  scope: resourceGroup
  params: {
    arcK8sClusterName: arcK8sClusterName
    Location: location
    scriptURI: scriptURI
    ShellScriptName: ShellScriptName
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    authenticationType: authenticationType
    subnetId: subnet.id
    virtualMachineName: replace('${take(prefix,19)}-${virtualMachineName}', '--', '-')
    virtualMachineSize: virtualMachineSize
    publicIPId: publicip.outputs.publicipId
    nsgId: nsg.outputs.nsgID
  }
  dependsOn: [
    vnet
    publicip
    nsg
  ]
}
