# ============================================================================================
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
# ============================================================================================
#
# Developed by Dr. Gaiye "Gail" Zhou, Sr Architect @ Microsoft.  
# August 2022
#
# Use this scripts if you have updated your Python Code and need to deploy it to the existing
# Azure Functions App that already exists. 
#
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

    [Parameter(Mandatory= $True, HelpMessage='Enter the name of your actual azure functions app')]
    [string]
    $azureFunctionsAppName = ''
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
# Deploy Python Code to the Azure Functions Infrastructure created by 3 
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
$Days = [math]::floor($Duration.Days)
$Hrs = [math]::floor($Duration.Hours) 
$Mins = [math]::floor($Duration.Minutes)
$Secs = [math]::floor($Duration.Seconds)
$MSecs = [math]::floor($Duration.Milliseconds)

Write-Host "Deployment Time: $Days days $Hrs hours $Mins minutes $Secs seconds $MSecs milliseconds `r`n" -ForegroundColor Yellow