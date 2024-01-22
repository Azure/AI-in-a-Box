# AI Edge in-a-box
![Banner](./readme_assets/banner-edgeai-in-a-box.png)

## Use Case
End-to-end operationalization of ML model through Azure ML and IoT Edge Device, leveraging IoT Hub, Iot Edge, Azure ML, GitHub actions and Azure ML CLI V2

## Solution Architecture
<img src="./readme_assets/edgai-iotedge-architecture.png" />


## Prerequisites
* An [Azure subscription](https://azure.microsoft.com/en-us/free/).
* Install latest version of [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest)
* Install [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
* Install [Azure IoT Extension](https://github.com/Azure/azure-iot-cli-extension) for Azure CLI
    * az extension add --name azure-cli-iot-ext
* Install latest version of [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
* Prepare your Linux virtual machine or physical device for [IoT Edge](https://learn.microsoft.com/en-us/azure/iot-edge/how-to-provision-single-device-linux-symmetric)

## Deployment Flow
**Step 1.** Create Azure Resources 
* IoT Hub, Azure Machine Learning, Azure Container Registry

**Step 2.** Configure Edge Device and Create Edge VM if you would like

**Step 3.** Buld ML model into docker image

**Step 4.** Deploy ML model on IoT Edge

**Step 5.** Test ML Module

## Deploy to Azure

1. Log into your Azure subscription: 
    ```
    azd auth login
    ```

1. Clone this repository locally: 

    ```
    git clone https://github.com/Azure/AI-in-a-Box
    cd edge-ai-in-a-box/iotedge-ai-in-a-box
    ```

2. Deploy resources:
    ```
    azd up
    ```

    You will be prompted for a subcription, and region.


## Post Deployment
* Once the VM is deployed or your physical device is setup you can ssh into the VM/device using the below command   
    * ssh NodeVMAdmin@edgevm1.eastus.cloudapp.azure.com -p 2222 
* Once connected to your virtual machine, [verify](https://learn.microsoft.com/en-us/azure/iot-edge/quickstart-linux) that the runtime was successfully installed and configured on your IoT Edge device.
    * sudo iotedge system status
    * sudo iotedge list
    * sudo iotedge check