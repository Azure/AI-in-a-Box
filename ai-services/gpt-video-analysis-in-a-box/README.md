# Image and Video Analysis-Azure Open AI in-a-box
![banner](./readme-assets/banner-aoai-video-analysis-in-a-box.png)
This solution examines videos and image of vehicles for damage using Azure Open AI GPT-4 Turbo with Vision and Azure AI Vision Image Analysis 4.0. All orchestration is done with Azure Data Factory, allowing this solution to be easily customized for your own use cases.

Please note that as of this 4/4/2024, Azure Open AI GPT-4 Turbo with Vision and Azure AI Vision Image Analysis 4.0 are in Public Preview for limited regions.

- [Check here for available regions for Azure AI Vision Image Analysis 4.0.](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview-image-analysis?tabs=4-0#image-analysis-versions)
- [Check here for available regions for GPT-4 Turbo with Vision.](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#gpt-4-and-gpt-4-turbo-preview-model-availability)

## Solution Architecture

![solution-arch](./readme-assets/gpt4-adf-architecture.jpg)

1. Land images and/or videos in Azure Blob storage with Azure Event Grid, Azure Logic Apps, Azure Functions, other ADF pipelines or other applications.
1. The ADF pipeline retrieves the Azure AI API endpoints, keys and other configurations from Key Vault.
1. The blob storage URL for the image or video file is retrieved.
1. For videos, a video retrieval index is created for the file with Azure AI Vision and the video is ingested into the index. Depending on your use case, you could ingest multiple videos to the same index. Image analysis does not require an index.
1. Call GPT4-V deployment in Azure Open AI, passing in video or image URL, the video retrieval index for videos, the system message, the user prompt and other inputs.
1. Save the response to Azure Cosmos DB.
1. If the video processes successfully, move the video to the appropriate archive folder.

## Resources Deployed in this solution

![resources](./readme-assets/resources.jpg)

- User Assigned Managed Identity which has access to all resources
- Storage account and containers for input images and videos and processed images videos. Additionally, a SAS key is created which is required at this time for Azure AI Vision Image Analysis 4.0.
- Azure Key Vault for holding API keys, the storage SAS token, and deployment information.
- Azure AI Vision with Image Analysis 4.0 for video ingestion and/or image analysis. Note that at this time Image Analysis 4.0 is in Preview and in limited regions. [Check here for available regions.](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview-image-analysis?tabs=4-0#image-analysis-versions)
- Azure Open AI resource with a GPT-4 Vision Preview Deployment. [Check here for available regions.](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#gpt-4-and-gpt-4-turbo-preview-model-availability)

## Prerequisites for running locally

 1. Install latest version of [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest)
 1. Install latest version of [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
 1. Install latest version of [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)
 1. Install latest version [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-python#v2)

## Deploy to Azure

### Clone this repository locally

```bash
git clone https://github.com/Azure/AI-in-a-Box
```

### Deploy resources

```bash
cd gen-ai/a-services/gpt-video-analysis-in-a-box
azd auth login
azd up
```

You will be prompted for a subscription, a region for GPT-4V, a region for AI Vision, a resource group, a prefix and a suffix. The parameter called **location** must be a region that supports GPT-4V; the parameter called **CVlocation** must be a region that supports AI Vision Image Analysis 4.0.

### Post deployment:
Upload images and videos of vehicles to your new storage account's **videosin** container using [Azure Storage Explorer](https://learn.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer), [AzCopy](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-files#upload-the-contents-of-a-directory) or within [the Azure portal](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-portal#upload-a-block-blob). You can find some sample images and videos at the bottom of this blog, [Analyze Videos with Azure Open AI GPT-4 Turbo with Vision and Azure Data Factory](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/analyze-videos-with-azure-open-ai-gpt-4-turbo-with-vision-and/ba-p/4032778).

## Run the solution

1. In the Azure portal, go to your newly created Azure Data Factory Resource and click launch:
![launch](./readme-assets/launchadf.jpg)

1. Select the **orchestratorGetandAnalyzeVideos** pipeline, click **Debug**, and examine your preset pipeline parameter values. Then click OK to run.
![run](./readme-assets/run-from-adf.png)

1. After it runs successfully, go to your Azure Cosmos DB resource and examine the results in Data Explorer:
![cosmos](./readme-assets/cosmos-data-explorer.png)

1. At this time, GPT4-V does not support response_format={"type": "json_object"}. However, if we still specify the chat completion to return the results in Json, we can specify a Cosmos query to convert the string to a Json object:
![cosmos query](./readme-assets/cosmos-query.png)

```sql
SELECT gptoutput.filename, gptoutput.fileurl, gptoutput.shortdate, 
StringToObject(gptoutput.content) as results
FROM gptoutput 
```

## Enhance the solution in your environment for your own use cases

This solution is highly customizable due to the parameterization capabilities in Azure Data Factory. Below are the features you can parameterize out-of-the-box, or should I say, out-of-the-AI-in-Box (insert-nerdy-laugh-here.)

### Test prompts and other settings

When developing your solution, you can rerun it with different settings to get the best results from GPT-4V by tweaking the **sys-message**, **user_prompt**, **temperature**, and **top_p** values.

![parameters](./readme-assets/adf-parms.jpg)

### Change from batch to real-time

This solution is set to loop against a container of videos and images in batch, which is ideal for testing. However, when you move to production, you may want the video to be analyzed in real-time. To do this, you can set up a storage event trigger which will run when a file is landed in blob storage.
![triMovegger](./readme-assets/blob-event-trigger.jpg)
Move the If Activity inside the For Each loop to the main Orchestrator pipeline canvas and hen eliminate the Get Metadata and For Each activities.  Call the If activity after the variables are set and the parameters are retrieved from Key Vault. You can get the file name from the trigger metadata. [Read more about ADF Storage Event triggers here](https://learn.microsoft.com/en-us/azure/data-factory/how-to-create-event-trigger?tabs=data-factory).

### Use the same Data Factory for other image and/or video analysis use cases

You can set up multiple triggers over your Azure Data Factory and pass different parameter values for whatever analysis you need to do:
![triggers](./readme-assets/new-trigger-parm.png)

You can set up different storage accounts for landing the files, then adjust the **storageaccounturl** and **storageaccountcontainer** parameters to ingest and analyze the images and/or videos. You can have different prompts and other values sent to GPT-4V in the **sys_message**, **user_prompt**, **temperature**, and **top_p** values for different triggers. You can land the data in a different Cosmos Account, Database and/or Container when setting the **cosmosaccount**, and **cosmosdb**, and **cosmoscontainer** values.

### Only analyze images or videos
If you are only analyzing images OR videos, you can delete the pipeline that is not needed (childAnalyzeImage or childAnalyzeVideo), eliminate the If activity inside the ForEach File activity and specify the Execute Pipeline activity for just the pipeline you need. However, it doesn't hurt to leave the unneeded pipeline there in case you want to use it in the future.

For more details on this solution, check out this blog: [Analyze Videos with Azure Open AI GPT-4 Turbo with Vision and Azure Data Factory](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/analyze-videos-with-azure-open-ai-gpt-4-turbo-with-vision-and/ba-p/4032778)!
