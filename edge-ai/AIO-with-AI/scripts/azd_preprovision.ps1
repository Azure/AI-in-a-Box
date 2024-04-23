########################################################################
# Connect to Azure
########################################################################
Write-Host "Connecting to Azure..."
Write-Host "Setting Azure context with subscription id $env:AZURE_SUBSCRIPTION_ID ..."
# Write-Host "Setting az subscription..."
az account set --subscription $env:AZURE_SUBSCRIPTION_ID

########################################################################
# Registering resource providers
########################################################################
# Register providers
Write-Host "Registering Azure providers..."
$resourceProviders = @(
    "Microsoft.Compute",
    "Microsoft.ContainerInstance",
    "Microsoft.ContainerService",
    "Microsoft.DeviceRegistry"
    "Microsoft.ExtendedLocation",
    "Microsoft.IoTOperationsDataProcessor",
    "Microsoft.IoTOperationsMQ",
    "Microsoft.IoTOperationsOrchestrator",
    "Microsoft.KeyVault",
    "Microsoft.Kubernetes",
    "Microsoft.KubernetesConfiguration",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network"
)

###################
# Checking if a required provider is not registered and save in array azProvidersNotRegistered
###################
$azProvidersNotRegistered = @()
foreach ($provider in $resourceProviders) {
    $registrationState = $(az provider show --namespace $provider --query "[registrationState]" --output tsv)
    if ($registrationState -ne "Registered") {
        Write-Host "Found an Azure Resource Provider not registred: $provider"
        $azProvidersNotRegistered += $provider
    }
}

###################
# Registering all missing required Azure providers
###################
if (![string]::IsNullOrEmpty($azProvidersNotRegistered)) {
    Write-Host "Registering required Azure Providers"
    Write-Host ""
    foreach ($provider in $azProvidersNotRegistered) {
        Write-Host "Registering Azure Provider: $provider"
        az provider register --namespace $provider
    }
}

###################
# Checking the status of missing Azure Providers
###################
if (![string]::IsNullOrEmpty($azProvidersNotRegistered)) {
    $copy_azProvidersNotRegistered = $azProvidersNotRegistered
    while ($copy_azProvidersNotRegistered.Count -gt 0) {
        foreach ($provider in $azProvidersNotRegistered) {
            $registrationState = $(az provider show --namespace $provider --query "[registrationState]" --output tsv)
            if ($registrationState -ne "Registered") {
                Write-Host "Waiting for Azure provider $provider ..."
            }
            else {
                Write-Host "Azure provider $provider registered!"
                $copy_azProvidersNotRegistered = $copy_azProvidersNotRegistered -ne $provider
            }
        }
        $azProvidersNotRegistered = $copy_azProvidersNotRegistered
        Write-Host ""
        Write-Host "Amount of providers waiting to be registered: $($azProvidersNotRegistered.Count)"
        Write-Host "Waiting 10 seconds to check the missing providers again"
        Write-Host "############################################################"
        Start-Sleep -Seconds 10
        Clear-Host
    }
    Write-Host "Done registering required Azure Providers"
}

###################
# Retrieving the custom RP SP ID
# Get the objectId of the Microsoft Entra ID application that the Azure Arc service uses and save it as an environment variable.
###################
# bc313c14-388c-4e7d-a58e-70017303ee3b is Custom Locations RP
Write-Host "Retrieving the Custom Location RP ObjectID from SP ID bc313c14-388c-4e7d-a58e-70017303ee3b"
# Make sure that the command below is and/or pointing to the correct subscription and the MS Tenant
az account set --subscription $AZURE_SUBSCRIPTION_ID
$customLocationRPSPID = $(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
$customLocationRPSPID = "412d7898-47f2-46b4-9d60-b7e975ae0fde"
azd env set AZURE_ENV_CUSTOMLOCATIONRPSPID $customLocationRPSPID