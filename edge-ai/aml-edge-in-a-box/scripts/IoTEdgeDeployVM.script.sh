#!/bin/bash

#=========================================================================================================
#Created by:       Author: EdgeAI-in-a-Box Team
#Created on:       02/13/2024
#=========================================================================================================

#DESCRIPTION
#You can run the script in a bash command prompt by using the following command:
#1. cd edge-ai-in-a-box/iotedge-ai-in-a-box/scripts
#2. Using Inline Parameters copy the below command and run in bash terminal: 
#    ./IoTEdgeDeployVM.script.sh aibx-iotedge-rg eastus aibx iot-aibx-a2n EdgeDevice1 edgevm1 password NodeVMAdmin NodeVMAZU^7^8^9
    
#------------------------------------------------------------------------------------------------------
# Download the Azure CLI IoT extension
az extension add -n azure-iot

#resourceGroupName='aibx-iotedge-rg'
#location='eastus'
#AZURE_ENV_NAME='aibx'
#iotHubName='iot-aibx-a2n'
#edgeDeviceName='EdgeDevice1'
#dnsLabelPrefix='edgevm1'
#authenticationType='password'
#adminUsername='youradmin'
#adminPasswordOrKey="yourpassword"

echo "Deploying IoT Edge Enabled Ubuntu VM";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    location=$2
    AZURE_ENV_NAME=$3
    iotHubName=$4
    edgeDeviceName=$5
    dnsLabelPrefix=$6
    authenticationType=$7
    adminUsername=$8
    adminPasswordOrKey=$9

    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Location: $location";
echo "   AZURE_ENV_NAME: $environmentName";
echo "   IoT Hub Name: $iotHubName";
echo "   Edge Device Name: $edgeDeviceName";
echo "   dnsLabelPrefix: $dnsLabelPrefix";
echo "   authenticationType: $authenticationType";
echo "   adminUsername: $adminUsername";
#echo "   adminPasswordOrKey: $adminPasswordOrKey";

edgedevice=("EdgeDevice1" "EdgeDevice2" "EdgeDevice3")
edgedeviceName=${edgedevice[0]}
BicepJson="https://raw.githubusercontent.com/Azure/AI-in-a-Box/main/edge-ai/aml-edge-in-a-box/infra/edge/edgeDeploy.json"
BicepJsonOrg="https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/1.4/edgeDeploy.json"
#------------------------------------------------------------------------------------------------------"
# Deploy IoT Edge VM

# Check if IoT Hub Exists
echo "";
echo "Check if IoT Hub Exists";
iotHubName=$(az iot hub list --resource-group $resourceGroupName --query '[0].name' --output tsv)

if [ -z "$iotHubName" ]
then
      echo "   No IoT Hub was found - skipping Edge VM Device creation";
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

if [ "$deviceExists" == true ]; then

    echo "";
    echo "Check if VM Already Exists";
    edgevm=$(az vm list --resource-group $resourceGroupName --query '[0].name' --output tsv) 
    vmExists=$(echo -n "$edgevm" | wc -c)
    
    echo "   Edge VM: $edgevm"
    echo "   VM exists: $vmExists"

    if [ ! "$vmExists" -gt 5 ]; then
        echo "   Edge VM does not exist so we are going to create it"
        echo "Creating Edge VM"
            
        # Replace the following variables with actual values
        # dnsLabelPrefix='edgevm1'
        # authenticationType='password'
        # adminUsername='<REPLACE_WITH_USERNAME>'
        # adminPasswordOrKey='<REPLACE_WITH_SECRET_PASSWORD>'
        
        # Retrieve device connection string
        deviceConnectionString=$(az iot hub device-identity connection-string show --device-id "${edgedevice[0]}" --hub-name $iotHubName -o tsv)
        #echo "   Device Connection String: $deviceConnectionString"
        
        # Uncomment the following lines to deploy the Edge VM
        az deployment group create --name "deploy_edgeVm" --resource-group $resourceGroupName --template-uri $BicepJson \
        --parameters environmentName=$environmentName --parameters dnsLabelPrefix=$dnsLabelPrefix \
        --parameters authenticationType=$authenticationType --parameters adminUsername=$adminUsername --parameters adminPasswordOrKey=$adminPasswordOrKey \
        --parameters deviceConnectionString=$deviceConnectionString
        
        # Uncomment the following lines to open port 2222 and restart SSH
        # az vm open-port --resource-group "$resourceGroupName" --name "$edgevm" --port '2222'
        # az vm run-command invoke --resource-group "$resourceGroupName" --name "$edgevm" --command-id RunShellScript --scripts "sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config; systemctl restart sshd"
        
        # Once the VM is deployed, you can SSH into the VM using the following command
        # ssh "$adminUsername@$dnsLabelPrefix.eastus.cloudapp.azure.com" -p 2222
    else
        echo "   Edge VM already exists. Exiting..."
    fi
else
    echo "   Edge Device Does Not Exist. Exiting..."
fi