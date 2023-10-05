# <img src ='https://airsblobstorage.blob.core.windows.net/airstream/bicep.png' alt="[WIP] Pattern 3.A Azure AI Services (Document Intelligence) Landing Zone" width="50px" style="float: left; margin-right:10px;"> [WIP] Pattern 3.A Azure AI Services (Document Intelligence) Landing Zone

## Use case scenario

This is the basic setup for any Azure AI Services - Document Intelligence use case. It will deploy an Application Landing Zone that can support multiple use cases.

## Solution Architecture
## <img src="/Assets/images/Pattern3.A.1.png" alt="Pattern 3.A Azure AI Services (Document Intelligence)" style="float: left; margin-right:10px;" />
## <img src="/Assets/images/Pattern3.A.Landing.png" alt="Pattern 3.A Azure AI Services (Document Intelligence) Landing Zone" style="float: left; margin-right:10px;" />


## Preparation
1. Install Azure CLI  
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
1. Install bicep  
https://aka.ms/bicep-install
1. Ensure Microsoft.CognitiveServices Resource Provider is registered within Azure  
[Register a Resource Provider](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
1. Ensure your subscription is enabled for Azure OpenAI
4. Clone repository / copy files locally

5. Edit the parameter file 'main.parameters.json'

    - spObjectId: Your Service Principal ID from Azure AD. Make sure your Service Principal has Ownership role on the subscription. (Format should be xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
## Deployment

**Step 1**: 

**Step 2**: 

## Results
