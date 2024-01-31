/*region Header
      Module Steps 
      1. Create Public IP Address
      2. Create Network Security Group
      3. Create Virtual Network
      4. Create Network Interface
      5. Get Edge Device Connection String
      5. Create Virtual Machine
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param environmentName string
param resourceGroupName string
param iotHubName string
param edgeDeviceName string
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

@description('VM size')
param vmSize string = 'Standard_DS1_v2'

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param ubuntuOSVersion string = '20_04-lts'

@description('Allow SSH traffic through the firewall')
param allowSsh bool = true


var uniqueSuffix = substring(uniqueString(dnsLabelPrefix), 1, 3)

var imagePublisher = 'Canonical'
var imageOffer = '0001-com-ubuntu-server-focal'
var nicName = 'nic-${environmentName}-${uniqueSuffix}'
var vmName = 'vm-${environmentName}-${uniqueSuffix}'
var vnetName = 'vnet-${environmentName}-${uniqueSuffix}'
var pipName = 'ip-${dnsLabelPrefix}'
var addressPrefix = '10.0.0.0/16'
var subnet1Name = 'subnet-${environmentName}-${uniqueSuffix}'
var subnet1Prefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'
var vnetID = vnet.id
var subnet1Ref = '${vnetID}/subnets/${subnet1Name}'
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

var networkSecurityGroupName = 'nsg-${environmentName}-${uniqueSuffix}'
var sshRule = [
  {
    name: 'default-allow-22'
    properties: {
      priority: 1000
      access: 'Allow'
      direction: 'Inbound'
      destinationPortRange: '22'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  }
]
var noRule = []

//1. Create Public IP Address
resource pip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: publicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

//2. Create Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: (allowSsh ? sshRule : noRule)
  }
}

//3. Create Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

//4. Create Network Interface
//https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networkinterfaces
resource nic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnet1Ref
          }
        }
      }
    ]
  }
}

//5. Get Edge Device Connection String
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

var dcs = getDeviceCnxScript.properties.outputs.Result

//6. Create Edge Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      customData: base64('#cloud-config\n\napt:\n  preserve_sources_list: true\n  sources:\n    msft.list:\n      source: "deb https://packages.microsoft.com/ubuntu/20.04/prod focal main"\n      key: |\n        -----BEGIN PGP PUBLIC KEY BLOCK-----\n        Version: GnuPG v1.4.7 (GNU/Linux)\n\n        mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT\n        LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV\n        7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag\n        OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j\n        H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr\n        M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs\n        ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATUEEwEC\n        AB8FAlYxWIwCGwMGCwkIBwMCBBUCCAMDFgIBAh4BAheAAAoJEOs+lK2+EinPGpsH\n        /32vKy29Hg51H9dfFJMx0/a/F+5vKeCeVqimvyTM04C+XENNuSbYZ3eRPHGHFLqe\n        MNGxsfb7C7ZxEeW7J/vSzRgHxm7ZvESisUYRFq2sgkJ+HFERNrqfci45bdhmrUsy\n        7SWw9ybxdFOkuQoyKD3tBmiGfONQMlBaOMWdAsic965rvJsd5zYaZZFI1UwTkFXV\n        KJt3bp3Ngn1vEYXwijGTa+FXz6GLHueJwF0I7ug34DgUkAFvAs8Hacr2DRYxL5RJ\n        XdNgj4Jd2/g6T9InmWT0hASljur+dJnzNiNCkbn9KbX7J/qK1IbR8y560yRmFsU+\n        NdCFTW7wY0Fb1fWJ+/KTsC4=\n        =J6gs\n        -----END PGP PUBLIC KEY BLOCK----- \npackages:\n  - moby-cli\n  - moby-engine\nruncmd:\n  - dcs="${dcs}"\n  - |\n      set -x\n      (\n\n        # Wait for docker daemon to start\n        while [ $(ps -ef | grep -v grep | grep docker | wc -l) -le 0 ]; do \n          sleep 3\n        done\n\n        apt install -y aziot-edge\n\n        if [ ! -z $dcs ]; then\n          mkdir /etc/aziot\n          wget https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/master/config.toml -O /etc/aziot/config.toml\n          sed -i "s#\\(connection_string = \\).*#\\1\\"$dcs\\"#g" /etc/aziot/config.toml\n          iotedge config apply -c /etc/aziot/config.toml\n        fi\n\n      ) &\n')
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  dependsOn:[
    // Remove unnecessary dependsOn entry 'edgedevicecnxscript'
    getDeviceCnxScript
  ]
}


output exists bool = length(getDeviceCnxScript.properties.outputs.Result) > 0
output Public_SSH string = 'ssh ${vm.properties.osProfile.adminUsername}@${pip.properties.dnsSettings.fqdn}'
