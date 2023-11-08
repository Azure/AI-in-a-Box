# Deploy with Azure CLI and Bicep
The **1_deployment_scripts** folder contains the main **PowerShell** deployment script file: [main-deploy.ps1](./main-deploy.ps1). This PowerShell scripts executes a series of  **Azure CLI** commands which executes **bicep** scripts to fully deploy the resources needed into a selected Azure subscription. To start deployment, open either the desktop app or PowerShell Terminal in Visual Studio Code and navigate to this folder:

```
cd PDF-Form-Automation\Deployment\1_deployment_scripts
```

You can run the PowerShell deployment script in the PowerShell App command line,

```
powershell.exe -file main-deploy.ps1
```

Or run the PowerShell deployment script in PowerShell Terminal in Visual Studio Code:

```
.\main-deploy.ps1
```

You will prompted for the followings:

1. `subscriptionId` (Azure Subscription ID)
1. `location` (Azure Region)
1. `resourceGroupName` (Resource Group Name, new or existing)
1. `aadEmail` (Your Azure Active Directory Email)
1. `resourceNamePrefix` (This prefix will be added to the beginning of all the deployed resource names.) 

The PowerShell scripts also executes **Azure Functions Core Tools** command to deploy Python code to Azure Functions app. 

**Supporting technology required to run the deployment scripts**: Azure Command-Line Interface (CLI), Azure Functions Core Tools. 

When the deployment is finished, continue to the next step,  `2_machine_learning_model` : [Machine Learning Model Guide](../2_machine_learning_model/README.md).

## Function Code Redeployment 

If you updated any of the Azure Function Python Code, you can easily redeploy the function code by running this script: [deploy-updated-code.ps1](./deploy-updated-code.ps1).

```
powershell.exe -file deploy-updated-code.ps1
```

You will prompted for the followings:

1. `subscriptionId` (Azure Subscription ID)
2. `azureFunctionsAppName` (Name of the Azure Functions App you have deployed)

## Additional Information

In order to grant you the right permissions to create a key vault and use the key vault to securely save and retrieve sensitive information, the script needs your Azure Active Directory user Object ID, which is associated with your AAD email. If you have issue deploying the key vault and receiving error on policy, please check your azure active directory (AAD) `Object ID` associated with your AAD email. To find your AAD Object ID, go to Azure Portal, on left pane, click `Azure Active Directory`, then on left pane, under `Manage`, click `users`. Search for user and click the user, you will find the user AAD Object ID. Copy the value of `Object ID` .

In [main-deploy.ps1](./main-deploy.ps1), replace this line "`$objectId = az ad user show --id $aadEmail --query id`" with "`$objectId ='your-aad-object-id'`", where `your-aad-object-id` needs to be the Object ID value you copied above. 

## Azure CLI

The Azure Command-Line Interface (CLI) is a cross-platform command-line tool to connect to Azure and execute administrative commands on Azure resources. To learn more, please follow this online doc: [What is the Azure CLI? | Microsoft Docs](https://docs.microsoft.com/en-us/cli/azure/what-is-azure-cli).

To install Azure CLI, follow these online instructions: [How to install the Azure CLI | Microsoft Docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?MT.wc_id=M365-MVP-21083). Check the version by running `az version`, or upgrade to the latest version by running `az upgrade`. 

## Bicep

Bicep is a domain-specific language (DSL) that uses declarative syntax to deploy Azure resources. To learn more, follow this online documentation: [Bicep language for deploying Azure resources - Azure Resource Manager | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)

**Bicep is provided as an extension to Azure CLI**. 

Check if you’ve already installed Bicep by running `az bicep version`. You can upgrade existing version by running `az bicep upgrade`. If it’s not installed, install it by running `az bicep install` in console.  For more information, please follow this online documentation: [Set up Bicep development and deployment environments - Azure Resource Manager | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

## Azure Functions Core Tools 

Azure Functions Core Tools lets you develop and test your functions on your local computer from the command prompt or terminal. To learn more, please follow this online doc: [Work with Azure Functions Core Tools | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash)

To install Azure Functions Core Tools, please follow these online instructions: [Install Azure Functions Core Tools | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash#v2).

## PowerShell

If not already installed, you can install PowerShell by following this online documentation:

[Install PowerShell on Windows, Linux, and macOS - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.2)

