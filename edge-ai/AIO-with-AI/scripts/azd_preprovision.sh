 #!/bin/bash

########################################################################
# Connect to Azure
########################################################################
echo "Connecting to Azure..."
echo "Setting Azure context with subscription id $env:AZURE_SUBSCRIPTION_ID ..."
# echo "Setting az subscription..."
az account set --subscription $env:AZURE_SUBSCRIPTION_ID

########################################################################
# Registering resource providers
########################################################################
# Register providers
echo "Registering Azure providers..."

###################
# List of required azure providers
###################
azProviders=(
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
azProvidersNotRegistered=()
for provider in "${azProviders[@]}"
do
  registrationState=$(az provider show --namespace $provider --query "[registrationState]" --output tsv)
  if [ "$registrationState" != "Registered" ]; then
    #echo "Found an Azure Resource Provider not registred: $provider"
    azProvidersNotRegistered+=($provider)
    #echo "${azProvidersNotRegistered[@]}"
  fi
done

###################
# Registering all missing required Azure providers
###################
if (( ${#azProvidersNotRegistered[@]} > 0 )); then
  echo "Registering required Azure Providers"
  echo ""
  for provider in "${azProvidersNotRegistered[@]}"
  do
    echo "Registering Azure Provider: $provider"
    az provider register --namespace $provider
  done
fi
echo ""

###################
# Function to remove an element of an array
###################
remove_array_element_byname(){
    index=0
    name=$1[@]
    param2=$2
    fun_arr=("${!name}")

    for element in "${fun_arr[@]}"
    do
      if [[ $element == $param2 ]]; then
        foundindex=$index
      fi
      index=$(($index + 1))
    done
    unset fun_arr[$foundindex]
    ret_val=("${fun_arr[@]}")
}

###################
# Checking the status of missing Azure Providers
###################
if (( ${#azProvidersNotRegistered[@]} > 0 )); then
  copy_azProvidersNotRegistered=("${azProvidersNotRegistered[@]}")
  while (( ${#copy_azProvidersNotRegistered[@]} > 0 ))
  do
    elementcount=0
    for provider in "${azProvidersNotRegistered[@]}"
    do
      registrationState=$(az provider show --namespace $provider --query "[registrationState]" --output tsv)
      if [ "$registrationState" != "Registered" ]; then
        echo "Waiting for Azure provider $provider ..."
      else
        echo "Azure provider $provider registered!"
        remove_array_element_byname copy_azProvidersNotRegistered $provider
        ret_remove_array_element_byname=("${ret_val[@]}")
        copy_azProvidersNotRegistered=("${ret_remove_array_element_byname[@]}")
      fi
    done
    azProvidersNotRegistered=("${copy_azProvidersNotRegistered[@]}")
    echo ""

    echo "Amount of providers waiting to be registered: ${#azProvidersNotRegistered[@]}"
    echo "Waiting 10 seconds to check the missing providers again"
    echo "############################################################"
    sleep 10
    clear
  done
  echo "Done registering required Azure Providers"
fi

###################
# Retrieving the custom RP SP ID
# Get the objectId of the Microsoft Entra ID application that the Azure Arc service uses and save it as an environment variable.
###################
# bc313c14-388c-4e7d-a58e-70017303ee3b is Custom Locations RP
echo "Setting Subscription Context"
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
echo "Retrieving the Custom Location RP ObjectID from SP ID bc313c14-388c-4e7d-a58e-70017303ee3b"
# Make sure that the command below is and/or pointing to the correct subscription and the MS Tenant
$customLocationRPSPID = $(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
echo "customLocationRPSPID: $customLocationRPSPID"
$customLocationRPSPID = "412d7898-47f2-46b4-9d60-b7e975ae0fde"
azd env set AZURE_ENV_CUSTOMLOCATIONRPSPID $customLocationRPSPID