/*region Header
      Module Steps 
      1 - Create Azure storage Instance
      2 - Set up Private Endpoint
      3 - Create Private DNS Zone (TO DO: Move this to hub VNet)
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param resourceLocation string
param storageAccountName string
param storageAccountType string = 'Standard_LRS'
param vnetID string
param subnetID string
param tags object

//Create Resources----------------------------------------------------------------------------------------------------------------------------

//1. Create Azure Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: resourceLocation
  properties:{
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  sku: {
    name: storageAccountType
  }
  tags: {
    Type: 'Synapse Data Lake Storage'
  }
}

//2. Create your default/root folder structure
resource storageAccount_default 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}pe'
  location: resourceLocation
  properties: {
    subnet: {
      id: subnetID
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-private-endpoint'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: tags
  properties: {}
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'default'
  location: 'global'
  tags: tags
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetID
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'default'
  parent: storagePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}