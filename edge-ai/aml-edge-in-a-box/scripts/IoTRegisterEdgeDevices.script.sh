#!/bin/bash

#=========================================================================================================
#Created by:       Author: EdgeAI-in-a-Box Team
#Created on:       02/13/2024
#=========================================================================================================

#DESCRIPTION
#You can run the script in a bash command prompt by using the following command:
#1. cd edge-ai-in-a-box/iotedge-ai-in-a-box/scripts
#2. Using Inline Parameters copy the below command and run in bash terminal: 
#   ./IoTRegisterEdgeDevices.script.sh aibx-iotedge-rg eastus 
    
#------------------------------------------------------------------------------------------------------
# Download the Azure CLI IoT extension
az extension add -n azure-iot

#resourceGroupName='aibx-iotedge-rg'
#location='eastus'
#iotHubName='iot-aibx-a2n'

 echo "Registering Edge Devices with Azure IoT Hub";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    location=$2

    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Location: $location";

edgedevice=("EdgeDevice1" "EdgeDevice2" "EdgeDevice3")
edgedeviceName=${edgedevice[0]}
#------------------------------------------------------------------------------------------------------
# Deploy IoT Edge Device(s)

# Check if IoT Hub Exists
echo "";
echo "Check if IoT Hub Exists";
iotHubName=$(az iot hub list --resource-group $resourceGroupName --query '[0].name' --output tsv)

if [ -z "$iotHubName" ]
then
      echo "   No IoT Hub was found - skipping Edge Device creation";
      exit 0
else
      echo "   Azure IoT Hub Name: $iotHubName";
fi

# Check if IoT Edge Device(s) Exist(s)
echo "";
echo "Check if IoT Edge Device(s) Exist(s)"
echo "   Edge Device Name: $edgedeviceName"
# deviceCheck=$(az iot hub device-identity list --hub-name $iotHubName --query "[?deviceId=='$edgedeviceName']")
deviceCheck=$(az iot hub device-identity show --resource-group $resourceGroupName --hub-name $iotHubName --device-id $edgedeviceName --query 'deviceId' --output tsv)

echo "   Device Check: $deviceCheck"

deviceCount=$(echo -n "$deviceCheck" | wc -c)
deviceExists=false

if [ "$deviceCount" -gt 3 ]; then
    deviceExists=true
fi

echo "   Device exists: $deviceExists"

if [ "$deviceExists" == false ]; then

    echo "";
    echo "Creating Device"
    for device in "${edgedevice[@]}"
    do
        # Create the current device
        echo "$device"
        echo "";
        az iot hub device-identity create --device-id "$device" --hub-name "$iotHubName" --edge-enabled --output none
        az iot hub device-twin update --device-id "$device" --hub-name "$iotHubName" --set tags='{"environment":"e2e-edgeai"}'
    done

    echo "   Devices were registered successfully in IoT Hub"
    
else
    echo "   Device already exists. Exiting..."
fi