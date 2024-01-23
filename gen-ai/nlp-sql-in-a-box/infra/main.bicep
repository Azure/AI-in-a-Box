/*region Header
      =========================================================================================================
      Created by:       Author: Your Name | your.name@azurestream.io 
      Description:      AOAI in-a-box - Deploy AOAI NLP to SQL Accelerator
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
        1. Create Resource Group
        2. Deploy UAMI
        3. Deploy OpenAI
        4. Deploy Speech Service
        5. Deploy SQL Server
        6. Deploy SQL Database
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

//UAMI Module Parameters
param msiName string = ''

//OpenAI Module Parameters
param openaiName string = ''
@allowed(['gpt-35-turbo'])
param gptModel string
@allowed(['0301'])
param gptVersion string
param deployDalle3 bool = false

//SQL Module Parameters
@description('Deploy SQL Database? (required for SQL Plugin demo)')
param deploySQL bool = true
param sqlServerName string = ''
param sqlDatabaseName string = ''
@description('Set the administrator login for the SQL Server')
@secure()
param administratorLogin string
@description('Set the administrator login password for the SQL Server')
@secure()
param administratorLoginPassword string

//Speech Module Parameters
param speechServiceName string = ''
@description('Deploy Azure AI Speech service? (required for Text to Speech and Speech to Text Plugin demo)')
param deploySpeechService bool = true

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'


//====================================================================================
// Create Resource Group 
//====================================================================================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

//2. Deploy UAMI
module m_msi 'modules/msi.bicep' = {
  name: 'deploy_msi'
  scope: resourceGroup
  params: {
    location: location
    msiName: !empty(msiName) ? msiName : '${abbrs.managedIdentityUserAssignedIdentities}${environmentName}-${uniqueSuffix}'
    tags: tags
  }
}

//3. Deploy OpenAI
module m_openai 'modules/openai.bicep' = {
  name: 'deploy_openai'
  scope: resourceGroup
  params: {
    location: location
    openaiName: !empty(openaiName) ? openaiName : '${abbrs.cognitiveServicesOpenAI}${environmentName}-${uniqueSuffix}'
    gptModel: gptModel
    gptVersion: gptVersion
    msiPrincipalID: m_msi.outputs.msiPrincipalID
    publicNetworkAccess: publicNetworkAccess
    deployDalle3: deployDalle3
    tags: tags
  }
}

//4. Deploy Speech Service
module m_speech 'modules/speech.bicep' = if (deploySpeechService) {
  name: 'deploy_speech'
  scope: resourceGroup
  params: {
    location: location
    speechServiceName: !empty(speechServiceName) ? speechServiceName : '${abbrs.cognitiveServicesSpeech}${environmentName}-${uniqueSuffix}'
    tags: tags
  }
}

//5. Deploy SQL Server/SQL Database
module m_sql 'modules/sql.bicep' = {
  name: 'deploy_sql'
  scope: resourceGroup
  params: {
    location: location
    sqlServerName: !empty(sqlServerName) ? sqlServerName : '${abbrs.sqlServers}${environmentName}-${uniqueSuffix}'
    sqlDatabaseName: !empty(sqlDatabaseName) ? sqlDatabaseName : '${abbrs.sqlServersDatabases}${environmentName}-${uniqueSuffix}'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
