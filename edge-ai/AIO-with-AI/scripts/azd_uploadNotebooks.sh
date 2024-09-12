#!/bin/bash

# resourceGroupName='aiobx-aioedgeai-rg'
# subscriptionId='00000000-0000-0000-0000-000000000000'
# uamiId='/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/aiobx-aioedgeai-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/YOURUANAME'
# amlworkspaceName='mlw-aiobx-hev'
# dataStoreName='workspaceworkingdirectory'
# storageAccountName='staiobxhev'
# storageAccountKey='storageAccountKey'
# urlNotebookImgML='1-Img-Classification-Training.ipynb'
# urlImgTrainingScript='train.py'
# urlImgUtilScript='utils.py'
# urlImgConda='conda.yaml'
# urlNotebookAutoML='2-AutoML-ObjectDetection.ipynb'
# urlImgSKClSampleReq='sample-request.json'
# urlImgSKClScore='score.py'
# urlImgSKClModel='sklearn_mnist_model.pkl'
# urlImgSKRgSampleReq='sample-request.json'
# urlImgSKRgScore='score.py'
# urlImgSKRgModel='sklearn_regression_model.pkl'

echo "Uploading Notebooks to Azure ML Studio via CLI Script";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    subscriptionId=2
    uamiId=$3
    amlworkspaceName=$4
    dataStoreName=$5
    storageAccountName=$6
    storageAccountKey=$7
    urlNotebookImgML=$8
    urlImgTrainingScript=$9
    urlImgUtilScript=${10}
    urlImgConda=${11}
    urlNotebookAutoML=${12}
    urlImgSKClSampleReq=${13}
    urlImgSKClScore=${14}
    urlImgSKClModel=${15}
    urlImgSKRgSampleReq=${16}
    urlImgSKRgScore=${17}
    urlImgSKRgModel=${18}
    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

# Determine the Fileshare name in Azure Storage Account
echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Subscription Id: $subscriptionId"
echo "   uamiId: $uamiId"
echo "   Machine Learning Service Name: $amlworkspaceName"
echo "   Datastore Name: $dataStoreName"
echo "   Storage Account Name: $storageAccountName"
#echo "   Storage Account Key: $storageAccountKey"
echo "   URL Notebook: $urlNotebookImgML"
echo "   URL Notebook: $urlImgTrainingScript"
echo "   URL Notebook: $urlImgUtilScript"
echo "   URL Notebook: $urlImgConda"
echo "   URL Notebook: $urlNotebookAutoML"
echo "   URL Notebook: $urlImgSKClSampleReq"
echo "   URL Notebook: $urlImgSKClScore"
echo "   URL Notebook: $urlImgSKClModel"
echo "   URL Notebook: $urlImgSKRgSampleReq"
echo "   URL Notebook: $urlImgSKRgScore"
echo "   URL Notebook: $urlImgSKRgModel"

az extension add -n ml
az account set -s $subscriptionId

echo "Active Azure account:"
az account show

workspace=$(az ml workspace show --name $amlworkspaceName --resource-group $resourceGroupName)
shareName=$(az ml datastore show --name $dataStoreName --resource-group $resourceGroupName --workspace-name $amlworkspaceName --query "file_share_name" -otsv)

echo "Get Azure ML File Share Name";
echo "   File Share Name: $shareName"

# Create a new directory in the Fileshare to hold the Notebooks
echo "Creating necessary directories..."
az storage directory create --share-name "$shareName" --name "edgeai" --account-name $storageAccountName --account-key $storageAccountKey --output none
az storage directory create --share-name "$shareName" --name "edgeai/sklearn-model" --account-name $storageAccountName --account-key $storageAccountKey --output none
az storage directory create --share-name "$shareName" --name "edgeai/sklearn-model/environment" --account-name $storageAccountName --account-key $storageAccountKey --output none
az storage directory create --share-name "$shareName" --name "edgeai/sklearn-model/onlinescoringclassification" --account-name $storageAccountName --account-key $storageAccountKey --output none
az storage directory create --share-name "$shareName" --name "edgeai/sklearn-model/onlinescoringregression" --account-name $storageAccountName --account-key $storageAccountKey --output none


# Download Notebook Files
wget "$urlNotebookImgML"
wget "$urlImgTrainingScript"
wget "$urlImgUtilScript"
wget "$urlImgConda"
wget "$urlNotebookAutoML"
wget "$urlImgSKClSampleReq"
wget "$urlImgSKClScore" 
wget "$urlImgSKClModel"

echo "PWD Path";
echo "$PWD"
  
# for entry in "$PWD"/*
# do
# echo "$entry"
# done

filepath1="$PWD/1-Img-Classification-Training.ipynb"
filepath2="$PWD/train.py"
filepath3="$PWD/utils.py"
filepath4="$PWD/conda.yaml"
filepath5="$PWD/2-AutoML-ObjectDetection.ipynb"
filepath6="$PWD/sample-request.json"
filepath7="$PWD/score.py"
filepath8="$PWD/sklearn_mnist_model.pkl"


# echo "File Path: $filepath1"
# echo "File Path: $filepath2"
# echo "File Path: $filepath3"
# echo "File Path: $filepath4"
# echo "File Path: $filepath5"
# echo "File Path: $filepath6"
# echo "File Path: $filepath7"
# echo "File Path: $filepath8"


# Upload Notebooks to File Shares in the "Notebooks" folder
az storage file upload -s $shareName --source $filepath1 --path edgeai/1-Img-Classification-Training.ipynb --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath2 --path edgeai/train.py --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath3 --path edgeai/utils.py --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath4 --path edgeai/sklearn-model/environment/conda.yaml --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath5 --path edgeai/2-AutoML-ObjectDetection.ipynb --account-key $storageAccountKey --account-name $storageAccountName

az storage file upload -s $shareName --source $filepath6 --path edgeai/sklearn-model/onlinescoringclassification/sample-request.json --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath7 --path edgeai/sklearn-model/onlinescoringclassification/score.py --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath8 --path edgeai/sklearn-model/onlinescoringclassification/sklearn_mnist_model.pkl --account-key $storageAccountKey --account-name $storageAccountName

mkdir -p onlinescoringregression  # Create directory if it doesn't exist
wget "$urlImgSKRgSampleReq" -P onlinescoringregression/
wget "$urlImgSKRgScore" -P onlinescoringregression/
wget "$urlImgSKRgModel" 

filepath9="$PWD/onlinescoringregression/sample-request.json"
filepath10="$PWD/onlinescoringregression/score.py"
filepath11="$PWD/sklearn_regression_model.pkl"

echo "File Path: $filepath9"
echo "File Path: $filepath10"
echo "File Path: $filepath11"


az storage file upload -s $shareName --source $filepath9 --path edgeai/sklearn-model/onlinescoringregression/sample-request.json --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath10 --path edgeai/sklearn-model/onlinescoringregression/score.py --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath11 --path edgeai/sklearn-model/onlinescoringregression/sklearn_regression_model.pkl --account-key $storageAccountKey --account-name $storageAccountName
