# Solution Accelerator Configurations
The default document intelligence composite model id in the solution deployment is `contoso-safety-forms`. If you gave the composite model a different name, follow the instructions below:

1. From the the [Azure Portal](https://portal.azure.com), open the resource group you deployed this solution to.
1. Find the Azure Functions App, click the resource and get to its overview page.
1. On left panel, under section **Settings**, click **Environment variables**.  Under the **App**, locate **CUSTOM_BUILT_MODEL_ID** click it and replace the default value with your composite model id.
1. click **OK** and then **Save**. After this, your Azure Functions app will work with this document intelligence extraction model.![ModelID](../Images/AF-Set-Configuration-Model-ID.png)