/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io
      Description:      Edge AI in-a-box - Deploy your AI Model on Edge Devices with Azure ML and IoT Edge
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
        az deployment group create --resource-group <your resource group name>  --template-file main.bicep --parameters main.paraeters.json --name AML-Edge-in-a-Box --query 'properties.outputs'

        SCRIPT STEPS
        1 - Create Resource Group
        2 - Create User Assigned Identity for VM
        3 - Create Key Vault
        4 - Create Required Storage Account(s)
        5 - Create IoT Hub
        6 - Create DPS
        7 - Create Application Insights
        8 - Create Azure Container Registry
        9 - Create Azure Machine Learning Workspace
        10 - Assign Role to UAMI
        11 - Upload Notebooks to Azure ML Studio
        12 - Create IoT Edge Devices inside of the IoT Hub with a Deployment Script
        13 - Deploy Edge VM (A) - Deploy with a Script
   
      //=====================================================================================

*/
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

//UAMI Module Parameters
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

//DPS Module Parameters
//param dpsName string = ''

//Application Insights
var applicationInsightsName = ''

//ACR Module Parameters
param acrName string = ''
@description('The SKU to use for the Azure Container Registry.')
param acrSku string = 'Standard'

//Azure ML
var workspaceName = ''
@description('Specifies the name of the Azure Machine Learning workspace Compute Name.')
param amlcompclustername string = 'aml-cluster'
@description('Specifies the name of the Azure Machine Learning workspace Compute Name.')
param amlcompinstancename string = ''
@description('Specifies whether to reduce telemetry collection and enable additional encryption.')
param hbi_workspace bool = false
@description('Identity type of storage account services for your azure ml workspace.')
param systemDatastoresAuthMode string = 'accessKey'

//Edge VM Module Parameters
@description('Deploy Document Intelligence service? (required for Upload Plugin demo)')
param deployEdgeVM bool = true
@description('EdgeDevice Name that you want to associate with your Edge VM')
param edgeDeviceName string = 'EdgeDevice1'
@description('Unique DNS Name for the Storage Account where the Virtual Machine\'s disks will be placed.')
param dnsLabelPrefix string = 'edgevm1'
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'
@description('User name for the Edge Virtual Machine.')
param adminUsername string = 'NodeVMAdmin'
@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string


//====================================================================================
// Create Resource Group
//====================================================================================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

//2. Create UAMI
module m_msi 'modules/msi.bicep' = {
  name: 'deploy_msi'
  scope: resourceGroup
  params: {
    location: location
    msiName: !empty(msiName) ? msiName : '${abbrs.managedIdentityUserAssignedIdentities}${environmentName}-${uniqueSuffix}'
    tags: tags
  }
}

//3. Create KeyVault
//https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults
module m_kvn 'modules/keyvault.bicep' = {
  name: 'deploy_keyvault'
  scope: resourceGroup
  params: {
    keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${environmentName}-${uniqueSuffix}'
    location: location
  }
}

//4. Deploy Required Storage Account(s)
//Deploy Storage Accounts (Create your Storage Account (ADLS Gen2 & HNS Enabled) for your ML Workspace)
//https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?tabs=bicep
module m_stg 'modules/storage.bicep' = {
  name: 'deploy_storageaccount'
  scope: resourceGroup
  params: {
    storageAccountName: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${environmentName}${uniqueSuffix}'
    location: location
  }
}

//5. Create IoTHub
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

//6. Create DPS
// module m_dps 'modules/dps.bicep' = {
//   name: 'deploy_dps'
//   scope: resourceGroup
//   params: {
//     location: location
//     dpsName: !empty(dpsName) ? dpsName : '${abbrs.devicesProvisioningServices}${environmentName}-${uniqueSuffix}'
//     iotHubName: m_iot.outputs.iotHubName
//     skuName: skuName
//     skuUnits: skuUnits
//     tags: tags
//   }
//   dependsOn: [
//     m_iot
//   ]
// }

//7. Create Application Insights Instance
//https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep
module m_aisn 'modules/insights.bicep' = {
  name: 'deploy_appinsights'
  scope: resourceGroup
  params: {
    location: location
    applicationInsightsName:  !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${environmentName}-${uniqueSuffix}'
  }
}

//8. Create Azure Container Registry
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

//9. Create Machine Learning Workspace
//https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?pivots=deployment-language-bicep
module m_aml './modules/azureml.bicep' = {
  name: 'deploy_azureml'
  scope: resourceGroup
  params: {
    location: location
    aisnId: m_aisn.outputs.applicationInsightId
    amlcompclustername: !empty(amlcompclustername) ? amlcompclustername : '${abbrs.machineLearningServicesCluster}${environmentName}-${uniqueSuffix}'
    amlcompinstancename: !empty(amlcompinstancename) ? amlcompinstancename : '${abbrs.machineLearningServicesComputeCPU}${environmentName}-${uniqueSuffix}'
    keyvaultId: m_kvn.outputs.keyVaultId
    storageAccountId: m_stg.outputs.stgId
    workspaceName: !empty(workspaceName) ? workspaceName : '${abbrs.machineLearningServicesWorkspaces}${environmentName}-${uniqueSuffix}'
    hbi_workspace: hbi_workspace
    acrId: m_acr.outputs.acrId
    systemDatastoresAuthMode: ((systemDatastoresAuthMode == 'accessKey') ? systemDatastoresAuthMode : 'identity')
    tags: tags
  }
}

//10. Assign Role to UAMI
module m_RBACRoleAssignment 'modules/rbac.bicep' = {
  name: 'deploy_RBAC'
  scope: resourceGroup
  params: {
    uamiPrincipalId: m_msi.outputs.msiPrincipalID
    uamiName: m_msi.outputs.msiName
  }
  dependsOn:[
    m_msi
    m_aml
  ]
}

//********************************************************
//Deployment Scripts
//********************************************************
//Upload Notebooks to Azure ML Studio
module script_UploadNotebooks './modules/scriptNotebookUpload.bicep' = {
  name: 'script_UploadNotebooks'
  scope: resourceGroup
  params: {
    location: location
    resourceGroupName: resourceGroup.name
    amlworkspaceName: m_aml.outputs.amlworkspaceName
    storageAccountName: m_stg.outputs.stgName

    uamiId: m_msi.outputs.msiID
  }
  dependsOn:[
    m_aml
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

//Deploy Edge VM (A) - Deploy with a Script
module script_DeployEdgeVM './modules/scriptDeployEdgeVM.bicep' = if (deployEdgeVM) {
  name: 'script_DeployEdgeVM'
  scope: resourceGroup
  params: {
    location: location
    environmentName: environmentName
    resourceGroupName: resourceGroup.name
    iotHubName: m_iot.outputs.iotHubName
    edgeDeviceName: edgeDeviceName
    dnsLabelPrefix: !empty(dnsLabelPrefix) ? '${dnsLabelPrefix}${uniqueSuffix}' : 'edgevm1${uniqueSuffix}'
    authenticationType: authenticationType
    adminUsername : adminUsername
    adminPasswordOrKey: adminPasswordOrKey

    uamiId: m_msi.outputs.msiID
  }
  dependsOn:[
    m_iot
    script_RegisterEdgeDevices
  ]
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_IOTHUB_NAME string = m_iot.outputs.iotHubName
output AZURE_ACR_NAME string = m_acr.outputs.acrName
output AZURE_ACR_LOGIN_SERVER string = m_acr.outputs.acrloginServer
output AZURE_ML_WORKSPACE string = m_aml.outputs.amlworkspaceName
output AZURE_DNS_LABEL_PREFIX string = dnsLabelPrefix
output AZURE_AUTHENTICATION_TYPE string = authenticationType
output AZURE_ADMIN_USERNAME string = adminUsername
output deployEdgeVM bool = deployEdgeVM
