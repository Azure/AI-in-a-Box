# Create Azure AI Document Intelligence Machine Learning Model 

Follow the steps below to train a Azure AI Document Intelligence custom extraction machine learning (ML) model. 

## Step 1: Locate the Sample Data Files

After deploying the Azure Resources, your Document intelligence source will be ready for you to start creating a new Document Intelligence ML model. From your cloned repository, navigate to the project root directory then to [Data/samples/train](../Data/samples/train/)

You will see two folders that contain sample training forms, as illustrated below.

![FR Deployment Data Samples](../Images/FR-Deployment-Data-Folders.png)

## Step 2: Upload Sample Forms to Azure Data Lake Storage

1. Go to the [Azure Portal](https://portal.azure.com) and select the Azure Data Lake Storage Account that was created by deployment script. The name of this account should be <your-prefix>adls<your-suffix>.
2. On the left side of the menu pane, select `Data storage`, then `Containers` and go to the `samples` container. 
3. Create a new folder and name it `train`.  
4. In the `train` folder, create two folders. One named `contoso_set_1` and the other named `contoso_set_2`.  
5. Upload the sample labeling files in [Data/samples/train/contoso_set_1](../Data/samples/train/contoso_set_1) and [Data/samples/train/contoso_set_2](../Data/samples/train/contoso_set_2)  into the corresponding folders. You now have two full sets of pre-labeled data to create the machine learning models.

## Step 3: Train and Merge Document Intelligence ML Models

In this step, you will train custom Azure AI Document intelligence customer extraction models and merge them into a composite model. For more information, please refer to Azure online document [Compose Custom Models](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/how-to-guides/compose-custom-models?view=doc-intel-4.0.0&tabs=studio).

1. Go to [Document Intelligence Studio](https://documentintelligence.ai.azure.com/studio), scroll down to  `Custom Extraction Model` and select `Create new`, as illustrated below.

    ![FR Create Custom Model](../Images/FR-Create-Custom-Model.png)

1. Select `+Create a project` to create a project.
1. Enter a project name. For example `SafetyFormProject-Set-1` or any other project name of your choice.
1. Enter a project description. For example `Custom document intelligence model with samples contoso_set_1` and click `Continue`.
1. Select your Subscription, Resource Group and the Document Intelligence resource.
1. Select the latest, non-preview API Version.
1. Now you will be prompted to enter the training data source, as illustrated below. Select your subscription. Select Resource Group, and Azure storage created by the deployment scripts. Enter `samples` in the Blob container field. Enter `train/contoso_set_1` in the Folder path field. Click `Continue`.

    ![FR Training Data Set](../Images/FR-Training-Data-Set.png)

1. Review Information and click `Create Project`. This step connects the form recognizer studio to Azure data lake storage/container resource in your subscription to access the training data. 
1. After the project is created, forms with OCR, field key and value pair will appear as illustrated below. Click '`Train`' on upper right corner.

    ![FR Label Data and Train](../Images/FR-Label-Data-and-Train.png)

1. Fill in information as below, and select the dropdown "Build Mode" to `Template`, and then click `Train`.

    ![FR Train New Model](../Images/FR-Train-New-Model.png)

1. Once the training for `contoso_set_1` samples is done, the model will be located in `Models` tab with confidence score of each field, as illustrated below.

    ![FR Field Confidence](../Images/FR-Field-Confidence.png)

1. Train a second model with files stored in `train/contoso_set_2`, using above steps to create a new project and model. Name your second model as `consoto-set-2` or choice of your own.
1. Click 'Models' from your project. You will see a list of models already created. You can now merge individual models into a composite model. Select `contoso-set-1` and `contoso-set-2`, then click `Compose`. The system will prompt you for a new model name and description. Name it `contoso-safety-forms` and provide a description. Click `Compose`.

    ![FR Merge Models](../Images/FR-Merge-Models.png)

    ![FR Compose Model](../Images/FR-Compose-Model-Contoso-Safety.png)

1. Now your model id `contoso-safety-forms` will appear in the Model ID list, as illustrated below. 

    ![FR List of Models](../Images/FR-List-of-Models.png "Project-and-Model-ID")

1. If you called your composite model `contoso-safety-forms`, you can move on to [3_solution_testing](..\3_solution_testing\README.md)
1. If you did NOT call your composite model `contoso-safety-forms`, follow the instructions below:
    1. From the the [Azure Portal](https://portal.azure.com), open the resource group you deployed this solution to.
    1. Find the Azure Functions App, click the resource and get to its overview page.
    1. On left panel, under section **Settings**, click **Environment variables**.  Under the **App**, locate **CUSTOM_BUILT_MODEL_ID** click it and replace the default value with your composite model id.
    1. click **OK** and then **Save**. After this, your Azure Functions app will work with this document intelligence extraction model.![ModelID](../Images/AF-Set-Configuration-Model-ID.png)