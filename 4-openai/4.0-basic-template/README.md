# <img src ='https://airsblobstorage.blob.core.windows.net/airstream/bicep.png' alt="[WIP] Pattern 4. Azure OpenAI Landing Zone" width="50px" style="float: left; margin-right:10px;"> [WIP] Pattern 4. Azure OpenAI Landing Zone

## Use case scenario

This is the basic setup for any Azure OpenAI use case. It will deploy an Application Landing Zone that can support multiple use cases.

## Solution Architecture
## <img src="/Assets/images/Pattern4.A.png" alt="Pattern 4. Azure OpenAI Landing Zone" style="float: left; margin-right:10px;" />

## Preparation
1. Install Azure CLI  (Make sure you are running the latest version of Azure CLI))
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
1. Install bicep (Make sure you are running the latest version of Azure CLI)  
https://aka.ms/bicep-install
1. Ensure Microsoft.CognitiveServices Resource Provider is registered within Azure  
[Register a Resource Provider](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
1. Ensure your subscription is enabled for Azure OpenAI
4. Clone repository / copy files locally

5. Edit the parameter file 'main.bicepparam'

    - spObjectId: Your Service Principal ID from Azure AD. Make sure your Service Principal has Ownership role on the subscription. (Format should be xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
## Deployment

**Step 1**: 

**Step 2**: 

## Results
