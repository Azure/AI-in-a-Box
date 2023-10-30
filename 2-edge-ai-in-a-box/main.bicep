/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Created on:       09/13/2023
      Description:      Pattern 4 OpenAI
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Create 
      2 - Create Storage Accounts
      3 - Create ML Workspace
      4 - Create Cog Services
      5 - Create OpenAI instance
      4 - Create Key Vault
      5 - Create Access Policy to get into Key Vault
      6 - Apply necessary RBAC
      7 - Create Synapse Workspace Assets (Linkd Services, Datasets, Pipelines, Notebooks, Triggers, etc. )
*/

//targetScope = 'subscription'

//********************************************************
// Workload Deployment Control Parameters
//********************************************************
param ctrlDeploySampleArtifacts bool = true         //Controls the creation of sample artifcats 

//********************************************************
// Global Parameters
//********************************************************
param utcValue string = utcNow()

@description('Unique Prefix')
param prefix string = 'aitoolkit'

@description('Unique Suffix')
//param uniqueSuffix string = substring(uniqueString(resourceGroup().id),0,3)
param uniqueSuffix string = substring(toLower(replace(uniqueString(subscription().id, resourceGroup().id, utcValue), '-', '')), 1, 3) 

@description('Resource Location')
param resourceLocation string = resourceGroup().location

@allowed([
  'OpenDatasets'
])
param sampleArtifactCollectionName string = 'OpenDatasets'

@allowed([
  'default'
  'vNet'
])
@description('Network Isolation Mode')
param networkIsolationMode string = 'default'

param env string = 'Dev'

param tags object = {
  Owner: 'aitoolkit'
  Project: 'aitoolkit'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}

//********************************************************
// Resource Config Parameters
//********************************************************

//Storage Account Module Parameters - Data Lake Storage Account for Synapse Workspace
@description('Storage Account Type')
param storageAccountType string
var storageAccountName = '${prefix}adls${uniqueSuffix}'

//----------------------------------------------------------------------

//Key Vault Module Parameters
@description('Key Vault Account Name')
param keyVaultName string = '${prefix}-keyvault-${uniqueSuffix}' 

@description('Your Service Principal Object ID')
param spObjectId string //This is your Service Principal Object ID


//********************************************************
// Variables
//********************************************************

var deploymentScriptUAMIName = toLower('${prefix}-uami')



//********************************************************
// RBAC Role Assignments
//********************************************************


//********************************************************
// Post Deployment Scripts
//********************************************************

