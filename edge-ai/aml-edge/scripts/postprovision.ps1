./loadenv.ps1

Write-Output "Creating Azure IoT Edge VM"

$resourceGroupName = $env:AZURE_RESOURCE_GROUP
$environmentName = $env:AZURE_ENV_NAME
$iotHubName = $env:AZURE_IOTHUB_NAME
$dnsLabelPrefix = $env:AZURE_DNS_LABEL_PREFIX
$authenticationType = $env:AZURE_AUTHENTICATION_TYPE
$adminUsername = $env:AZURE_ADMIN_USERNAME
$adminPasswordOrKey = $env:AZURE_ADMIN_PASSWORD
$edgedevice = @('EdgeDevice1','EdgeDevice2','EdgeDevice3')
$edgedeviceName = $edgedevice[0]
$BicepJson = "https://raw.githubusercontent.com/AndresPad/AI-in-a-Box/main/edge-ai-in-a-box/iotedge-ai-in-a-box/infra/edge/edgeDeploy.json"
$BicepJsonOrg = "https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/1.4/edgeDeploy.json"

$deployEdgeVm = $env:deployEdgeVM
Write-Host "Deploy Edge VM: " $deployEdgeVm
#------------------------------------------------------------------------------------------------------
# Deploy IoT Edge VM
Write-Host "Check if VM Exists"
$edgevm = $(az vm list --resource-group $resourceGroupName --query '[0].name' --output tsv) 
$vmExists = $edgevm.Length -gt 5

if (!$vmExists) {
    if(!$deployEdgeVm){
        Write-Host "Edge VM not set to deploy"
        Exit 0
    }
    else{
        Write-Host "Creating Edge VMa"
        #az bicep build --file $BicepFile

        #https://learn.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge-ubuntuvm-bicep?view=iotedge-1.4
        #https://learn.microsoft.com/en-us/azure/iot-edge/quickstart-linux
        #https://github.com/Azure/iotedge-vm-deploy/tree/master
        az deployment group create --name "deploy_edgeVm" --resource-group $resourceGroupName --template-uri $BicepJson `
        --parameters environmentName="$environmentName" --parameters dnsLabelPrefix="$dnsLabelPrefix" `
        --parameters authenticationType="$authenticationType" --parameters adminUsername="$adminUsername" --parameters adminPasswordOrKey="$adminPasswordOrKey" `
        --parameters deviceConnectionString=$(az iot hub device-identity connection-string show --device-id $edgedevice[0] --hub-name $iotHubName -o tsv)

        $edgevm = $(az vm list --resource-group $resourceGroupName --query '[0].name' --output tsv) 
        
        #if you dont have the ability to open up port 22, you can change the port to 2222
        #uncomment the below lines to change the port to 2222
        #please note that you will have to create an inbound security rule in the NSG to allow port 2222
        # az vm open-port --resource-group $resourceGroupName --name $edgevm--port '2222'
        # az vm run-command invoke --resource-group $resourceGroupName --name $edgevm --command-id RunShellScript --scripts "sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config; systemctl restart sshd" 
        
        #Once the VM is deployed you can ssh into the VM using the below command
        #ssh NodeVMAdmin@edgevm1.eastus.cloudapp.azure.com -p 2222 
    }
}
else{
    Write-Host "Edge VM already exists"
}