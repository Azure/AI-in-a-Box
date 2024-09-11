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
var urlNotebookImgML=      'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/1-Img-Classification-Training.ipynb'
var urlImgTrainingScript=  'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/train.py'
var urlImgUtilScript=      'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/utils.py'

var urlImgConda=           'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/environment/conda.yaml'

var urlImgSKClSampleReq=   'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/onlinescoringclassification/sample-request.json'
var urlImgSKClScore=       'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/onlinescoringclassification/score.py'
var urlImgSKClModel=       'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/onlinescoringclassification/sklearn_mnist_model.pkl'

var urlImgSKRgSampleReq=   'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/onlinescoringregression/sample-request.json'
var urlImgSKRgScore=       'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/onlinescoringregression/score.py'
var urlImgSKRgModel=       'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/sklearn-model/onlinescoringregression/sklearn_regression_model.pkl'

var urlNotebookAutoML=     'https://raw.githubusercontent.com/Azure/AI-in-a-Box/aio-with-ai/edge-ai/AIO-with-AI/notebooks/2-AutoML-ObjectDetection.ipynb'

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
    scriptContent: loadTextContent('../../../scripts/azd_uploadNotebooks.sh')
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
        name: 'urlNotebookImgML'
        value: urlNotebookImgML
      }
      {
        name: 'urlImgTrainingScript'
        value: urlImgTrainingScript
      }
      {
        name: 'urlImgUtilScript'
        value: urlImgUtilScript
      }
      {
        name: 'urlImgConda'
        value: urlImgConda
      }
      {
        name: 'urlNotebookAutoML'
        value: urlNotebookAutoML
      }
      {
        name: 'urlImgSKClSampleReq'
        value: urlImgSKClSampleReq
      }
      {
        name: 'urlImgSKClScore'
        value: urlImgSKClScore
      }
      {
        name: 'urlImgSKClModel'
        value: urlImgSKClModel
      }
      {
        name: 'urlImgSKRgSampleReq'
        value: urlImgSKRgSampleReq
      }
      {
        name: 'urlImgSKRgScore'
        value: urlImgSKRgScore
      }
      {
        name: 'urlImgSKRgModel'
        value: urlImgSKRgModel
      }
    ]
  }
}
