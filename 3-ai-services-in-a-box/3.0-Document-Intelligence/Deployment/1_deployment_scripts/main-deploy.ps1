# ============================================================================================
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
# ============================================================================================
#
# Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
# August 2022
#
# ============================================================================================
# Azure resource naming rules can be found here: 
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
#
# quick cheat sheet: scope, length, naming rules 
# azure key vault:         global, len 3-24, Alphanumerics and hyphens, start with letter
# azure storage account:   global, len 3-24, Lowercase letters and numbers.
# azure cosmos db account: global, len 3-44, Lowercase letters, numbers, and hyphens, 
#                                      stars with lowercase letter or number
# azure logic app workflow:        len 1-43   Alphanumerics, hyphens, underscores, periods, 
#                                             and parenthesis.
# azure functions app web sites (azure functions app name): 
#                                  len 2-60, Alphanumeric, hyphens and Unicode characters 
#                                            that can be mapped to Punycode. 
#                                             Can't start or end with hyphen.
#
# ============================================================================================
#
################################################################################################
# Get user input 
################################################################################################
param(
    [Parameter(Mandatory= $True, HelpMessage='Enter the Azure subscription ID to deploy your resources')]
    [string]
    $subscriptionId = '',

    [Parameter(Mandatory= $True, HelpMessage='Enter the Azure Data Center Region to deploy your resources')]
    [string]
    $location = '',
	
	[Parameter(Mandatory= $True, HelpMessage='Enter the Resource Group Name')]
    [string]
    $resourceGroupName = '',

    [Parameter(Mandatory= $True, HelpMessage='Enter Your Azure Active Directory Email ')]
    [string]
    $aadEmail = '',

	[Parameter(Mandatory= $True,HelpMessage='Enter the Prefix for Resource Names - Alphanumerics 2-5 length')]
    [string]
    $resourceNamePrefix = ''
)

$ProgramStartTime = (Get-Date)

################################################################################################
# Login and specify the azure subscription to deploy resources to 
################################################################################################
Write-Host "Log in to Azure.....`r`n" -ForegroundColor Yellow
az login 

# get list of subscriptions in tabular format
# az account list -o table

# Set current active subscription
az account set --subscription $subscriptionId 
Write-Host "Switched subscription to '$subscriptionId' `r`n" -ForegroundColor Yellow
# To see result:
# az account show 

################################################################################################
# Set up azure resource naming structure with resource name prefix received from user
# Do not need to modify below naming structure unless you run into conflicts.
# To avoid that situation, provide a better $resourceNamePrefix value in previous section
################################################################################################
# 
$keyVaultName =  $resourceNamePrefix + 'fa-kv'
$midName = $resourceNamePrefix + '_fa_MID' 
$storageAccountName = $resourceNamePrefix + 'formrepository' 
$formRecognierName = $resourceNamePrefix + 'formrecognizer' 
$cosmosAccountName = $resourceNamePrefix + 'cosmosdb' 
$azureFunctionsAppName = $resourceNamePrefix + 'funcapp'
$logicAppOutlookName = $resourceNamePrefix + 'lapp-outlook'
$logicAppFormProcName = $resourceNamePrefix + 'lapp-formproc'


# Create resource group if it does not exist
Write-Host "Create or reuse resource group '$resourcegroupName' `r`n" -ForegroundColor Yellow
$resourceGroup = az group exists -n $resourcegroupName
if ($resourceGroup -eq $false) {
    #create resource group
    az group create `
    --location $location `
    --name $resourceGroupName `
    --subscription $subscriptionId
}
# Create resource group if it does not exist - bash example
# if [ $(az group exists --name $resourceGroupName) = false ]; then
#   az group create --name $resourceGroupName --location $location
# fi

################################################################################################
# Step 1: Create or Reuse Key Vault 
#         It will use your AAD email to get AAD objectId to grant you Key vault permission
################################################################################################
Write-Host "Execute deploy-key-vault.bicep `r`n" -ForegroundColor Yellow
Write-Host "Create Key Vault '$keyVaultName' `r`n" -ForegroundColor Yellow
$objectId = az ad user show --id $aadEmail --query id  
# Optionally you can use below line with your actual AAD object ID:
# $objectId ='your-aad-object-id'

az deployment group create --resource-group $resourceGroupName `
    --parameters location=$location `
    --parameters resourceGroupName=$resourceGroupName `
    --parameters objectId=$objectId `
    --parameters keyVaultName=$keyVaultName `
    --parameters @params-kv.json `
    --template-file .\deploy-key-vault.bicep `
    --name deploy-kv `
    --query properties.outputs

# to examine the results: 
# az keyvault show --name $keyVaultName --query id --output tsv

################################################################################################
# Step 2: Create resources, assign privileges and save secrets into key vault 
#         A: create a group of resources: 
#            resource level managed identity
#            azure data lake storage
#            azure cosmos db
#            azure form recognizer
#         B: assign the right permissions for the above resources. 
#         C: save various keys and form recognizer end point into key vault 
################################################################################################
Write-Host "Execute deploy-resources.bicep `r`n" -ForegroundColor Yellow
Write-Host "Create and set up managed identity, data lake storage, cosmos db, form recognizer `r`n" -ForegroundColor Yellow
az deployment group create --resource-group $resourceGroupName `
    --parameters location=$location `
    --parameters resourceGroupName=$resourceGroupName `
    --parameters keyVaultName=$keyVaultName `
    --parameters midName=$midName `
    --parameters storageAccountName=$storageAccountName `
    --parameters formRecognierName=$formRecognierName `
    --parameters cosmosAccountName=$cosmosAccountName `
    --template-file .\deploy-resources.bicep `
    --name deploy-resources `
    --query properties.outputs
   
################################################################################################
# Step 3: Create and set up azure functions and deploy  python code 
#         Create Azure Functions App with its own storage and enable App Insight for monitoring 
# Note: Code is not deployed yet until Step 5
################################################################################################
# 
Write-Host "Execute deploy-functionsapp.bicep `r`n" -ForegroundColor Yellow
Write-Host "Create Infrastructure for Azure Functions App '$azureFunctionsAppName' `r`n" -ForegroundColor Yellow
az deployment group create --resource-group $resourceGroupName `
    --parameters location=$location `
    --parameters resourceGroupName=$resourceGroupName `
    --parameters keyVaultName=$keyVaultName `
    --parameters midName=$midName `
    --parameters azureFunctionsAppName=$azureFunctionsAppName `
    --template-file .\deploy-functionsapp.bicep `
    --name deploy-functionsapp `
    --query properties.outputs


################################################################################################
# Step 4: Deploy Logic Apps with valid api connections to azire storage, cosmos db, and outlook 
################################################################################################
Write-Host "Execute deploy-logicapps-hostkey.bicep `r`n" -ForegroundColor Yellow
Write-Host "Create and Deploy Azure Logic Apps: '$logicAppOutlookName' and '$logicAppFormProcName' `r`n" -ForegroundColor Yellow
az deployment group create --resource-group $resourceGroupName `
    --parameters location=$location `
    --parameters resourceGroupName=$resourceGroupName `
    --parameters keyVaultName=$keyVaultName `
    --parameters resourceNamePrefix=$resourceNamePrefix `
    --parameters azureFunctionsAppName=$azureFunctionsAppName `
    --parameters midName=$midName `
    --parameters storageAccountName=$storageAccountName `
    --parameters cosmosAccountName=$cosmosAccountName `
    --parameters logicAppOutlookName=$logicAppOutlookName `
    --parameters logicAppFormProcName=$logicAppFormProcName `
    --template-file .\deploy-logicapps-hostkey.bicep `
    --name deploy-logicapps `

Write-Host "'$logicAppOutlookName' and '$logicAppFormProcName' are deployed. `r`n" -ForegroundColor Yellow

    
################################################################################################
# Step 5: Deploy Python Code to the Azure Functions Infrastructure created by 3 
################################################################################################
# go to the location where code resides (cd ..\code)
Write-Host "Deploy Code for Azure Functions App '$azureFunctionsAppName' `r`n" -ForegroundColor Yellow
$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$parentPath = Split-Path -parent $scriptPath
$codePath = Join-Path -Path $parentPath -ChildPath 'code'
Set-Location -Path $codePath
# Publish code to Azure Functions App from the code folder
func azure functionapp publish $azureFunctionsAppName --python 
# back to the directory 1_deployment_scripts to continue next deployment step (cd ..\1_deployment_scripts)
Set-Location -Path $scriptPath 


################################################################################################
# After Deployment:
# You need to authorize the outlookConnection with valid outlook email id and password. 
# Find this api resource in azure portal and authorize it. Additional information
# can be found in the deployment guide - solution configuration section
################################################################################################

$ProgramFinishTime = (Get-Date)
Write-Host "Deployment is done. Congratulations! `r`n " -ForegroundColor Yellow
Write-Host " Started at '$ProgramStartTime'. `r`n Finished at '$ProgramFinishTime'. `r`n" -ForegroundColor Yellow

$Duration = (New-TimeSpan -Start $ProgramStartTime -End $ProgramFinishTime)
#$Days = [math]::floor($Duration.Days)
#$Hrs = [math]::floor($Duration.Hours) 
$Mins = [math]::floor($Duration.Minutes)
$Secs = [math]::floor($Duration.Seconds)
$MSecs = [math]::floor($Duration.Milliseconds)

Write-Host "Deployment Time: $Mins minutes $Secs seconds $MSecs milliseconds `r`n" -ForegroundColor Yellow