/*region Header
      =========================================================================================================
      Created by:       Author: Marco Cardoso | macardoso@microsoft.com 
      Created on:       09/13/2023
      Description:      Pattern 4 OpenAI
      =========================================================================================================

      Dependencies:
        Install Azure CLI
        https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest 

        Install Latest version of Bicep
        https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

      SCRIPT STEPS 
      1 - Create or connect to VNet and subnet for Private Endpoints
      2 - Create OpenAI instance
      3 - Create Cognitive Search
      4 - Create Storage Account
      5 - Create Private Endpoints for all services
      6 - Apply necessary RBAC
      7 - Create OpenAI Deployments
*/

// targetScope = 'subscription'

//********************************************************
// Workload Deployment Control Parameters
//********************************************************
param ctrlDeployCognitiveSearch bool = true         // Controls whether to create a Cognitive Search instance

//********************************************************
// Global Parameters
//********************************************************
param utcValue string = utcNow()

@description('Unique Prefix')
param prefix string = 'aitoolkit'

@description('Unique Suffix')
param uniqueSuffix string = substring(toLower(replace(uniqueString(subscription().id, resourceGroup().id, utcValue), '-', '')), 1, 3) 

@description('Resource Location')
param resourceLocation string = resourceGroup().location

param env string = 'Dev'

param tags object = {
  Owner: 'aitoolkit'
  Project: 'aitoolkit'
  Environment: env
  Toolkit: 'bicep'
  Name: prefix
}


param vNetIPAddressPrefixes array

//********************************************************
// Resource Config Parameters
//********************************************************

//Storage Account Module Parameters - Data Lake Storage Account for Synapse Workspace
@description('Storage Account Type')
param storageAccountType string

//----------------------------------------------------------------------


//********************************************************
// Variables
//********************************************************
var vNetName = '${prefix}vnet${uniqueSuffix}'
var vNetSubnetName = '${prefix}subnet${uniqueSuffix}'
var openAiAccountName = '${prefix}openai${uniqueSuffix}'
var storageAccountName = '${prefix}stg${uniqueSuffix}'
var searchAccountName = '${prefix}search${uniqueSuffix}'

//********************************************************
// Deploy Core Platform Services 
//********************************************************
module m_vnet 'modules/deploy_1_vnet.bicep' = {
  name: 'deploy_vnet'
  params: {
    resourceLocation: resourceLocation
    vNetIPAddressPrefixes: vNetIPAddressPrefixes
    vNetName: vNetName
    vNetSubnetName: vNetSubnetName
  }
}


module m_openai 'modules/deploy_2_openai.bicep' = {
  name: 'deploy_openai'
  params: {
    resourceLocation: resourceLocation
    vnetID: m_vnet.outputs.vNetID
    subnetID: m_vnet.outputs.subnetID
    openAiAccountName: openAiAccountName
    tags: tags
  }
}


module m_storage 'modules/deploy_3_storage.bicep' = {
  name: 'deploy_storage'
  params: {
    resourceLocation: resourceLocation
    vnetID: m_vnet.outputs.vNetID
    subnetID: m_vnet.outputs.subnetID
    storageAccountName: storageAccountName
    tags: tags
  }
}


module m_search 'modules/deploy_4_search.bicep' = {
  name: 'deploy_search'
  params: {
    resourceLocation: resourceLocation
    vnetID: m_vnet.outputs.vNetID
    subnetID: m_vnet.outputs.subnetID
    searchAccountName: searchAccountName
    tags: tags
  }
}

//********************************************************
// RBAC Role Assignments
//********************************************************


//********************************************************
// Post Deployment Scripts
//********************************************************

