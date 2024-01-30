/*region Header
      Module Steps 
      1 - Upload Notebooks to Azure ML Studio

      //https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep
      //https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template
*/

//Declare Parameters--------------------------------------------------------------------------------------------------------------------------
param location string
param resourceGroupName string
param amlworkspaceName string
param storageAccountName string
param uamiId string

// Change the URL below with that of your notebook
var urlNotebookAutoML= 'https://raw.githubusercontent.com/AndresPad/AI-in-a-Box/main/edge-ai/aml-edge-in-a-box/notebooks/1-AutoML-ObjectDetection.ipynb'
var urlNotebookOnnx= 'https://raw.githubusercontent.com/AndresPad/AI-in-a-Box/main/edge-ai/aml-edge-in-a-box/notebooks/2-Onnx-HandwrittenDigitClassification.ipynb'
var urlOnnxTrainingScript= 'https://raw.githubusercontent.com/AndresPad/AI-in-a-Box/main/edge-ai/aml-edge-in-a-box/notebooks/mnist.py'
var urlNotebookOpenVino= 'https://raw.githubusercontent.com/AndresPad/AI-in-a-Box/main/edge-ai/aml-edge-in-a-box/notebooks/3-OpenVino.ipynb'
var dataStoreName = 'workspaceworkingdirectory' // Note: name auto-created by ML Workspace, DO NOT CHANGE

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

//Using Azure CLI
resource notebooksUploadScriptCLI 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'notebooksUploadScriptCLI'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  properties: {
    azCliVersion: '2.52.0'
    scriptContent: loadTextContent('../../scripts/uploadNotebooks.script.sh')
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    timeout: 'PT1H'
    forceUpdateTag: 'v1'
    environmentVariables: [
      {
        name: 'resourceGroupName'
        value: resourceGroupName
      }
      {
        name: 'amlworkspaceName'
        value: amlworkspaceName
      }
      {
        name: 'dataStoreName'
        value: dataStoreName
      }
      {
        name: 'storageAccountName'
        value: storageAccount.name
      }
      {
        name: 'storageAccountKey'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'urlNotebookAutoML'
        value: urlNotebookAutoML
      }
      {
        name: 'urlNotebookOnnx'
        value: urlNotebookOnnx
      }
      {
        name: 'urlOnnxTrainingScript'
        value: urlOnnxTrainingScript
      }
    ]
  }
}

// resource notebooksUploadScriptInline 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
//   name: 'notebooksUploadScriptInline'
//   location: location
//   kind: 'AzureCLI'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${uamiId}': {}
//     }
//   }
//   properties: {
//     azCliVersion: '2.52.0'
//     scriptContent: '''
//       az extension add -n ml

//       echo "Uploading Notebooks to Azure ML Studio via Inline Script";
//       echo "";
//       echo "Paramaters:";
//       echo "   Resource Group Name: $resourceGroupName";
//       echo "   Machine Learning Service Name: $amlworkspaceName"
//       echo "   Datastore Name: $dataStoreName"
//       echo "   Storage Account Name: $storageAccountName"
//       #echo "   Storage Account Key: $storageAccountKey"
//       echo "   URL Notebook: $urlNotebook"

//       workspace=$(az ml workspace show --name $amlworkspaceName --resource-group $resourceGroupName)
//       shareName=$(az ml datastore show --name workspaceworkingdirectory --resource-group $resourceGroupName --workspace-name $amlworkspaceName --query "file_share_name" -otsv)

//       echo "";
//       echo "Get Azure ML File Share Name";
//       echo "   File Share Name: $shareName"

//       # Create a new directory in the Fileshare to hold the Notebooks
//       az storage directory create --share-name "$shareName" --name "edgeai" --account-name $storageAccountName --account-key $storageAccountKey --output none

//       # Download Notebook Files
//       echo "URL Notebook: $urlNotebook"
//       wget "$urlNotebook"
//       echo "$PWD"
  
//       for entry in "$PWD"/*
//       do
//         echo "$entry"
//       done

//       filepath="$PWD/train-classification-model.ipynb"
//       echo "File Path: $filepath"

//       # Upload Notebooks to File Shares in the "Notebooks" folder
//       #az storage file upload -s $shareName --source train-classification-model.ipynb --path edgeai/train-classification-model.ipynb --account-key $storageAccountKey --account-name $storageAccountName

//     '''
//     retentionInterval: 'PT1H'
//     cleanupPreference: 'Always'
//     timeout: 'PT30M'
//     forceUpdateTag: 'v1'
//     environmentVariables: [
//       {
//         name: 'resourceGroupName'
//         value: resourceGroupName
//       }
//       {
//         name: 'amlworkspaceName'
//         value: amlworkspaceName
//       }
//       {
//         name: 'dataStoreName'
//         value: dataStoreName
//       }
//       {
//         name: 'storageAccountName'
//         value: storageAccount.name
//       }
//       {
//         name: 'storageAccountKey'
//         secureValue: storageAccount.listKeys().keys[0].value
//       }
//       {
//         name: 'urlNotebook'
//         value: urlNotebook
//       }
//     ]
//   }
// }
