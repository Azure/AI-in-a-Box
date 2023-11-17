# Cognitive Services Landing Zone in-a-box
![Banner](./readme_assets/banner.png)

## Solution Architecture

The solution architecture is described in the diagram below.

![Solution Architecture](./readme_assets/architecture.png)

## Pre-requisites
1. Install Azure CLI (Make sure you are running the latest version of Azure CLI)  
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
1. Install bicep (Make sure you are running the latest version of Bicep CLI)  
https://aka.ms/bicep-install
1. Ensure Microsoft.CognitiveServices Resource Provider is registered within Azure  
[Register a Resource Provider](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
1. Ensure your subscription is enabled for Azure OpenAI
1. Clone repository / copy files locally
1. Edit the parameter file 'main.bicepparam'

## Deploy to Azure

```
az login
```

```
az deployment sub create -f main.bicep --parameters main.bicepparam
```
If this step causes you any errors, try updating your Azure CLI.