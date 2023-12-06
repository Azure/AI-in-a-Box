/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       11/16/2023
      Description:      AI Services in-a-box - Doc Intelligence in-a-box
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

        Copy above output to main.bicepparam; also add your resource group name and location to main.bicepparam and save

        az bicep build --file main.bicep
        az deployment group create --resource-group <your resource group name>  --template-file main.bicep --parameters main.bicepparam --name Doc-intelligence-in-a-Box --query 'properties.outputs' 

        After deployment, deploy code to function app (the name should be yourprefix-funcapp):
        func azure functionapp publish <your funcapp name> --python

      SCRIPT STEPS 
      1 - Create UAMI
      2 - Create Key Vault
      3 - Create Storage Account
      4 - Create CosmosDB
      5-  Create Form Recognizer
      6 - Assign Blob Contributor Role to UAMI
      7 - Assign Blob Contributor Role to Form Recognizer
      8 - Create Function App
      9 - Create KV Access Policies for Function App
      //=====================================================================================

*/

//********************************************************
// Global Parameters
//********************************************************
targetScope = 'resourceGroup'

param resourceGroupName string
param resourceLocation string
param prefix string
param uniqueSuffix string
@description('Your Object ID')
param spObjectId string //This is your own users Object ID

//UAMI Module Parameters
var deploymentScriptUAMIName = toLower('${prefix}-uami')

//Key Vault Module Parameters
var keyVaultName = '${prefix}-kv-${uniqueSuffix}'
param kvSecretPermissions array
param kvKeyPermissions array

//Storage Account Module Parameters - ADLS
var storageAccountName = '${prefix}adls${uniqueSuffix}'

//CosmosDB Module Parameters
var cosmosAccountName = '${prefix}-cosmos-${uniqueSuffix}'
var cosmosDbName = 'form-db' // preset for solution
var cosmosDbContainerName = 'form-docs' // preset for solution

//Form Recognizer Module Parameters
var formRecognizerName = '${prefix}-fr-${uniqueSuffix}'

//Function App Module Parameters
var funcAppName = '${prefix}-funcapp'
var funAppStorageName = '${prefix}funcapp${uniqueSuffix}'

//Logic App Module Parameters
var logicAppFormProcName = '${prefix}lapp-formproc${uniqueSuffix}'
var adlsConnectionName = '${prefix}ApiToAdlsWithKey'
var cosmosDbConnectionName = '${prefix}ApiToCosmosDbWithKey'

//====================================================================================
// Existing Resource Group 
//====================================================================================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: resourceGroupName
  scope: subscription()
}

//1. Deploy UAMI
module uaManagedIdentity 'modules/uami.bicep' = {
  name: 'deploy_UAMI'
  scope: resourceGroup
  params: {
    deploymentScriptUAMIName: deploymentScriptUAMIName
    resourceLocation: resourceLocation
  }
}

//2. Deploy Required Key Vault and UAMI
module keyvault 'modules/keyvault.bicep' = {
  name: 'deploy_keyvault'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    keyVaultName: keyVaultName
    principalId: uaManagedIdentity.outputs.uamiPrincipleId

    //Send in Service Principal and/or User Oject ID
    spObjectId: spObjectId

    kvSecretPermissions: kvSecretPermissions
    kvKeyPermissions: kvKeyPermissions
  }
}

//3. Deploy Storage Account
module datalake 'modules/datalake.bicep' = {
  name: 'deploy_datalake'
  scope: resourceGroup
  dependsOn: [
    keyvault
  ]
  params: {
    resourceLocation: resourceLocation
    storageAccountName: storageAccountName
    storageAccountType: 'Standard_LRS'
    containerList: [
      'files-1-input'
      'files-2-split'
      'files-3-recognized'
      'samples'
    ]
    keyVaultName: keyVaultName
    uami: uaManagedIdentity.outputs.uamiId
  }
}

//4. Deploy CosmosDB
module cosmosdb 'modules/cosmosdb.bicep' = {
  name: 'deploy_cosmosdb'
  scope: resourceGroup
  dependsOn: [
    keyvault
  ]
  params: {
    cosmosAccountName: cosmosAccountName
    cosmosDbName: cosmosDbName
    cosmosDbContainerName: cosmosDbContainerName
    resourceLocation: resourceLocation
    keyVaultName: keyVaultName
  }
}

//5. Create Form Recognizer (Document Intelligence)
module formrecognizer 'modules/form-recognizer.bicep' = {
  name: 'deploy_formrecognizer'
  scope: resourceGroup
  params: {
    formRecognizerName: formRecognizerName
    location: resourceLocation
    keyVaultName: keyVaultName
  }
  dependsOn: [
    keyvault
  ]
}

//6. Assign Blob Contributor Role to UAMI
module assignBlobContributorRoleToUAMI 'modules/assign-blobcontributor.bicep' = {
  name: 'deploy_assignBlobContributorRoleToUAMI'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    principalId: uaManagedIdentity.outputs.uamiPrincipleId
    principalType: 'ServicePrincipal'
  }
}

//7. Assign Blob Contributor Role to Form Recognizer
module assignBlobContributorRoleToFR 'modules/assign-blobcontributor.bicep' = {
  name: 'deploy_assignBlobContributorRoleToFR'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    principalId: formrecognizer.outputs.formRecognizerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

//8. Create Function App
module functionApp 'modules/functionapp.bicep' = {
  name: 'deploy_functionapp'
  scope: resourceGroup
  params: {
    resourceLocation: resourceLocation
    funcAppName: funcAppName
    funAppStorageName: funAppStorageName
    uamiId: uaManagedIdentity.outputs.uamiId
    uamiClientId: uaManagedIdentity.outputs.uamiClientid
    keyVaultName: keyVaultName
  }
  dependsOn: [
    uaManagedIdentity
    keyvault
  ]
}

//9. Create KV Access Policies for Function App
module keyvaultPolicy 'modules/keyvaultpolicy.bicep' = {
  dependsOn: [
    functionApp
  ]
  scope: resourceGroup
  name: 'deploy_kv_accessPolicies'
  params: {
    keyVaultResourceName: keyVaultName
    principalId: functionApp.outputs.principalId
  }
}

//====================================================================================
// Reusing Resources already created
//====================================================================================

resource keyvaultRef 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyvault.outputs.keyVaultName
  scope: resourceGroup
}

resource uaManagedIdentityRef 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: uaManagedIdentity.outputs.uamiName
  scope: resourceGroup
}

//====================================================================================
// Create Logic Apps with working API connections 
//====================================================================================
// Resources Created: 
//      API Connection to Azure Data Lake 
//      API Connection to Azure Cosmos DB 
//      Azure Logic App - Form Processing 
//=====================================================================================

module apiAdls 'modules/api-adls.bicep' = {
  name: 'module-apiAdls'
  scope: resourceGroup
  dependsOn: [
    keyvault
    datalake
  ]
  params: {
    location: resourceLocation
    storageAccountName: storageAccountName
    adlsConnectionWithKey: adlsConnectionName
    paramAdlsPrimaryKey: keyvaultRef.getSecret('AdlsPrimaryKey')
  }
}

module apiCosmosDb 'modules/api-cosmosdb.bicep' = {
  name: 'module-apiCosmosDb'
  scope: resourceGroup
  dependsOn: [
    keyvault
    cosmosdb
  ]
  params: {
    location: resourceLocation
    cosmosAccountName: cosmosAccountName
    cosmosDbConnectionWithKey: cosmosDbConnectionName
    paramCosmosAccountKey: keyvaultRef.getSecret('CosmosDbPrimaryKey')
  }
}

//*************************************************************************************
// Create form processing logic app that uses azure functions app's host key
//*************************************************************************************
module logicAppFormProc 'modules/logicapp-formproc-hostkey.bicep' = {
  name: 'module-logicAppFormProc'
  scope: resourceGroup
  dependsOn: [
    keyvault
    apiAdls
    apiCosmosDb
    functionApp
    uaManagedIdentity
    cosmosdb
    datalake
  ]
  params: {
    logicAppFormProcName: logicAppFormProcName
    azureFunctionsAppName: funcAppName
    location: resourceLocation
    mid: uaManagedIdentityRef.id
    storageAccountName: storageAccountName
    adlsConnectionName: adlsConnectionName
    adlsConnectionId: apiAdls.outputs.adlsConnectionId
    cosmosDbConnectionName: cosmosDbConnectionName
    cosmosDbConnectionId: apiCosmosDb.outputs.cosmosDbConnectionId
  }
}
