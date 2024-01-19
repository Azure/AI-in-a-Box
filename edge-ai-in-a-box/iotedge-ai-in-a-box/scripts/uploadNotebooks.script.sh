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
    urlNotebook=$6

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
echo "   URL Notebook: $urlNotebook"

workspace=$(az ml workspace show --name $amlworkspaceName --resource-group $resourceGroupName)
shareName=$(az ml datastore show --name $dataStoreName --resource-group $resourceGroupName --workspace-name $amlworkspaceName --query "file_share_name" -otsv)

echo "";
echo "Get Azure ML File Share Name";
echo "   File Share Name: $shareName"

# Create a new directory in the Fileshare to hold the Notebooks
az storage directory create --share-name "$shareName" --name "edgeai" --account-name $storageAccountName --account-key $storageAccountKey --output none

# Download Notebook Files
echo "URL Notebook: $urlNotebook"
wget "$urlNotebook"
echo "$PWD"
  
for entry in "$PWD"/*
do
echo "$entry"
done

filepath="$PWD/train-classification-model.ipynb"
echo "File Path: $filepath"

# Upload Notebooks to File Shares in the "Notebooks" folder
az storage file upload -s $shareName --source train-classification-model.ipynb --path edgeai/train-classification-model.ipynb --account-key $storageAccountKey --account-name $storageAccountName