/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Description:      Custom Vision I in-a-box - Deploy your AI Model on Edge Devices with Custom Vision
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install
      
        To Run:
        az login
        az account set --subscription <subscription id>
        az group create --name <your resource group name> --location <your resource group location>
        az ad user show --id 'your email' --query id

        az bicep build --file main.bicep
        az deployment group create --resource-group <your resource group name>  --template-file main.bicep --parameters main.bicepparam --name Doc-intelligence-in-a-Box --query 'properties.outputs' 
      
        SCRIPT STEPS 
      1 - Create UAMI
      2 - Create Key Vault
      3 - Create Storage Account
      4 - Create IoT Hub
      5 - Create Azure Container Registry
      6 - Create Custom Vision
      7 - Assign Role to UAMI
      8 - Create IoT Edge Devices inside of the IoT Hub with a Deployment Script  
      
      //=====================================================================================

*/

//********************************************************
// Global Parameters
//********************************************************
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param resourceGroupName string = ''

var abbrs = loadJsonContent('abbreviations.json')
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroup.id), 1, 3) 
param tags object

// UAMI Module Parameters
param msiName string = ''

//Key Vault
var keyVaultName = ''

//Storage Account
var storageAccountName = ''
var storageContainerName = 'iot'

//IoT Hub Module Parameters
param iotHubName string = ''
@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'
@description('The number of IoT Hub units.')
param skuUnits int = 1

//ACR Module Parameters
param acrName string = ''
@description('The SKU to use for the Azure Container Registry.')
param acrSku string = 'Standard'

//Custom Vision Module Parameters
param customVisionName string = ''

//Function App Module Parameters
// var funcAppName = '${prefix}-funcapp'
// var funAppStorageName = '${prefix}funcapp${uniqueSuffix}'


//====================================================================================
// Create Resource Group 
//====================================================================================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

//1. Deploy UAMI
module m_msi 'modules/msi.bicep' = {
  name: 'deploy_msi'
  scope: resourceGroup
  params: {
    location: location
    msiName: !empty(msiName) ? msiName : '${abbrs.managedIdentityUserAssignedIdentities}${environmentName}-${uniqueSuffix}'
    tags: tags
  }
}

//2. Deploy Required Key Vault
//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
module m_kvn 'modules/keyvault.bicep' = {
  name: 'deploy_keyvault'
  scope: resourceGroup
  params: {
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}-${uniqueSuffix}'
    location: location
    principalId: m_msi.outputs.msiPrincipalID

    //Send in Service Principal and/or User Oject ID
    //spObjectId: spObjectId
  }
}

//3. Deploy Required Storage Account(s)
//Deploy Storage Accounts (Create your Storage Account (ADLS Gen2 & HNS Enabled))
//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?tabs=bicep
module m_stg 'modules/storage.bicep' = {
  name: 'deploy_storageaccount'
  scope: resourceGroup
  params: {
    storageAccountName: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${environmentName}${uniqueSuffix}'
    location: location
  }
}

//4. Deploy IoTHub
module m_iot 'modules/iothub.bicep' = {
  name: 'deploy_iothub'
  scope: resourceGroup
  params: {
    location: location
    iotHubName: !empty(iotHubName) ? iotHubName : '${abbrs.iotHubComponents}${environmentName}-${uniqueSuffix}'
    skuName: skuName
    skuUnits: skuUnits
    tags: tags

    storageAccountName: m_stg.outputs.stgName
    storageAccountID: m_stg.outputs.stgId
    storageContainerName: storageContainerName
  }
  dependsOn: [
    m_stg
  ]
}

//5. Deploy Azure Container Registry
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
module m_acr './modules/acr.bicep' = {
  name: 'deploy_acr'
  scope: resourceGroup
  params: {
    location: location
    acrName: !empty(acrName) ? acrName : '${abbrs.containerRegistryRegistries}${environmentName}${uniqueSuffix}'
    acrSku: acrSku
    tags: tags
  }
}

//6. Create Custom Vision
module m_customvision 'modules/customVision.bicep' = {
  name: 'deploy_customvision'
  scope: resourceGroup
  params: {
    location: location
    cognitiveServiceName: !empty(customVisionName) ? customVisionName : '${abbrs.cognitiveServicesCustomVision}${environmentName}-${uniqueSuffix}'
    sku: 'S0'
    keyVaultName: m_kvn.outputs.keyVaultName
  }
  dependsOn: [
    m_kvn
  ]
}

//7. Assign Role to UAMI
module m_RBACRoleAssignment 'modules/rbac.bicep' = {
  name: 'deploy_RBAC'
  scope: resourceGroup
  params: {
    uamiPrincipalId: m_msi.outputs.msiPrincipalID
    uamiName: m_msi.outputs.msiName
  }
  dependsOn:[
    m_msi
  ]
}

//Create IoT Edge Devices inside of the IoT Hub with a Deployment Script
//https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-develop
module script_RegisterEdgeDevices './modules/scriptRegisterEdgeDevices.bicep' = {
  name: 'script_RegisterEdgeDevices'
  scope: resourceGroup
  params: {
    location: location
    resourceGroupName: resourceGroup.name
    uamiId: m_msi.outputs.msiID
  }
  dependsOn:[
    m_iot
  ]
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_IOTHUB_NAME string = m_iot.outputs.iotHubName
output AZURE_ACR_NAME string = m_acr.outputs.acrName
output AZURE_ACR_LOGIN_SERVER string = m_acr.outputs.acrloginServer
