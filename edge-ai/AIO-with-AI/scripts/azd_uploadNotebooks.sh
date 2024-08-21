#!/bin/bash

az extension add -n ml

#resourceGroupName='aibx-iotedge-rg'
#amlworkspaceName='mlw-aibx-a2n'
#dataStoreName='workspaceworkingdirectory'
#storageAccountName='staibxa2n'
#storageAccountKey='storageAccountKey'
#urlNotebook='urlNotebook'

echo "Uploading Notebooks to Azure ML Studio via CLI Script";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    amlworkspaceName=$2
    dataStoreName=$3
    storageAccountName=$4
    storageAccountKey=$5
    urlNotebookAutoML=$6
    urlNotebookOnnx=$7
    urlOnnxTrainingScript=$8
    urlNotebookImgML=$9

    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

# Determine the Fileshare name in Azure Storage Account
echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Machine Learning Service Name: $amlworkspaceName"
echo "   Datastore Name: $dataStoreName"
echo "   Storage Account Name: $storageAccountName"
#echo "   Storage Account Key: $storageAccountKey"
echo "   URL Notebook: $urlNotebookAutoML"
echo "   URL Notebook: $urlNotebookOnnx"
echo "   URL Notebook: $urlOnnxTrainingScript"
echo "   URL Notebook: $urlNotebookImgML"

workspace=$(az ml workspace show --name $amlworkspaceName --resource-group $resourceGroupName)
shareName=$(az ml datastore show --name $dataStoreName --resource-group $resourceGroupName --workspace-name $amlworkspaceName --query "file_share_name" -otsv)

echo "";
echo "Get Azure ML File Share Name";
echo "   File Share Name: $shareName"

# Create a new directory in the Fileshare to hold the Notebooks
az storage directory create --share-name "$shareName" --name "edgeai" --account-name $storageAccountName --account-key $storageAccountKey --output none

# Download Notebook Files
echo "URL Notebook: $urlNotebook"
wget "$urlNotebookAutoML"
wget "$urlNotebookOnnx"
wget "$urlNotebookImgML"
wget "$urlOnnxTrainingScript"
echo "$PWD"
  
for entry in "$PWD"/*
do
echo "$entry"
done

file1="1-AutoML-ObjectDetection.ipynb"
file2="2-Onnx-HandwrittenDigitClassification.ipynb"
file3="mnist.py"  
file4="img-classification-training.ipynb"

filepath1="$PWD/1-AutoML-ObjectDetection.ipynb"
filepath2="$PWD/2-Onnx-HandwrittenDigitClassification.ipynb"
filepath3="$PWD/mnist.py"
filepath4="$PWD/img-classification-training.ipynb"

echo "File Path: $filepath1"
echo "File Path: $filepath2"
echo "File Path: $filepath3"
echo "File Path: $filepath4"

# Upload Notebooks to File Shares in the "Notebooks" folder
az storage file upload -s $shareName --source $filepath1 --path edgeai/1-AutoML-ObjectDetection.ipynb --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath2 --path edgeai/2-Onnx-HandwrittenDigitClassification.ipynb --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath3 --path edgeai/mnist.py --account-key $storageAccountKey --account-name $storageAccountName
az storage file upload -s $shareName --source $filepath4 --path edgeai/img-classification-training.ipynb --account-key $storageAccountKey --account-name $storageAccountName