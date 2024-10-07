# Deployment of AIO in a box


## Prerequisites
The following prerequisites are needed for a succesfull deployment of this accelator from your own PC. 

1. A Microsoft [Azure subscription](https://azure.microsoft.com/en-us/free/)
2. Install or upgrade [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
3. Enable the Following [Resource Providers](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)

* Microsoft.AlertsManagement
* Microsoft.Compute
* Microsoft.ContainerInstance
* Microsoft.ContainerService
* Microsoft.DeviceRegistry
* Microsoft.ExtendedLocation
* Microsoft.IoTOperationsDataProcessor
* Microsoft.IoTOperationsMQ
* Microsoft.IoTOperationsOrchestrator
* Microsoft.KeyVault
* Microsoft.Kubernetes
* Microsoft.KubernetesConfiguration
* Microsoft.ManagedIdentity
* Microsoft.Network
* Microsoft.Relay

4. Install the following [Azure CLI Extensions](https://learn.microsoft.com/en-us/cli/azure/azure-cli-extensions-list): 
    * az extension add -n [azure-iot-ops](https://github.com/azure/azure-iot-ops-cli-extension) --allow-preview true 
    * az extension add -n [connectedk8s](https://github.com/Azure/azure-cli-extensions/tree/main/src/connectedk8s) 
    * az extension add -n [k8s-configuration](https://github.com/Azure/azure-cli-extensions/tree/master/src/k8sconfiguration) 
    * az extension add -n [k8s-extension](https://github.com/Azure/azure-cli-extensions/tree/main/src/k8s-extension) 
    * az extension add -n [ml](https://github.com/Azure/azureml-examples)

5. Install latest version of [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) 
6. Install latest PowerShell version (7.x): Check your current version with $PSVersionTable and then install the latest via "Winget install microsoft.azd"
7. Ownerships rights on the Microsoft Azure subscription
8. Install Visual Studio Code on your machine

## Deployment flow

Below you can find the full deployment flow of the application:

Step 1. Clone the Edge-AIO-in-a-Box Repository

Step 2. Create Azure Resources (User Assigned Managed Identity, VNET, Key Vault, Ubuntu VM, Azure ML Workspace, Container Registry)

Step 2. Configure Ubuntu VM

Step 3. Buld ML model into docker image

Step 4. Push model to Azure Container Registry

Step 5. Deploy model to the Edge via Azure IoT Operations

## Installation steps

1. Clone the repo to your machine. ``` git clone https://github.com/Azure-Samples/edge-aio-in-a-box
cd edge-ai/AIO-with-AI ```
2. Open the repo in Visual Studio code and open the terminal
3. Login with azd: ```azd auth login ```
4. Login to your Azure subscription: ``` az login --use-device-code ```
5. Start the process with ``` azd up ```
6. You get a screen to enter information
    * Name your environment, for example: ``` aiobx```
    * Shell Script name: ```installK3s1Vic.sh```
    * Type a username for your Arc: ``` ArcAdmin ```
    * Type a name of your Kubernetes cluster: ``` aiobmcluster ```
    * Select ``` password``` as authentication type
    * Use a strong password that you want to use 
    * Select your location of deployement, use the following: ```eastus``` 
    * Enter the following for the ScriptURI: ```https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/scripts/```
    * Give your virtualmachine a name: ``` aiobmclsuterVM ```
    * Select the size of your machine, for example: ```Standard_D16s_v4 ```
<br><br>
Start the installation proces and wait around 20 minutes. You can watch your deployement VSCode or in the Azure Portal in your newly created resource group. 

## Know issues
1. When you do a redeployment of the whole solution under the same name - it can take till seven days to remove the KeyVault. Use a different environment name for deployment if you need to deploy faster.