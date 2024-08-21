#!/bin/bash

az extension add --name ml --yes
az extension add --name connectedk8s --yes

#############################
# Script Params
#############################
# $1 = Azure Resource Group Name
# $2 = Azure Machine Learning Workspace Name
# $3 = Azure Arc for Kubernetes cluster name
# $4 = Azure Arc for Kubernetes Resource Id
# $5 = Azure VM UserAssignedIdentity Resource Id
# $5 = Subscription ID

#  1   ${resourceGroup().name}
#  2   ${amlworkspaceName}
#  3   ${arcK3sClusterName}
#  4   ${arcK3sClusterId}
#  5   ${vmUserAssignedIdentityID}
#  5   ${subscription().subscriptionId}

rg=$1
amlworkspaceName=$2
arcK8sClusterName=$3
vmUserAssignedIdentityID=$4
subscriptionId=$5


echo "Attach a Kubernetes cluster to Azure Machine Learning workspace";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    amlworkspaceName=$2

    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Machine Learning Workspace Name: $amlworkspaceName"
echo "   Arc Kubernetes Cluster Name: $arcK8sClusterName"
# echo "   Arc Kubernetes Cluster Id: $arcK8sClusterId"
echo "   VM User Assigned Identity Resource Id: $vmUserAssignedIdentityID"
echo "   Subscription ID: $subscriptionId"

#workspace=$(az ml workspace show --resource-group $rg --name $amlworkspaceName)
arcK3sClusterId=$(az connectedk8s show --resource-group $rg --name $arcK8sClusterName --query id --output tsv)

echo "";
echo "Attach a Kubernetes cluster to Azure Machine Learning workspace";
echo ""

# Attach a Kubernetes cluster to Azure Machine Learning workspace
#https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-to-workspace
#https://learn.microsoft.com/en-us/cli/azure/ml/compute
az ml compute attach --resource-group $rg --workspace-name $amlworkspaceName --type Kubernetes --name k3s-compute --resource-id $arcK3sClusterId --identity-type UserAssigned --user-assigned-identities $vmUserAssignedIdentityID

#az ml compute attach --resource-group aiobx-aioedgeai-rg --workspace-name mlw-aiobx-hev --type Kubernetes --name k3s-compute --resource-id "/subscriptions/22c140ff-ca30-4d58-9223-08a6041970ab/resourceGroups/aiobx-aioedgeai-rg/providers/Microsoft.Kubernetes/connectedClusters/aiobmcluster1" --identity-type UserAssigned --user-assigned-identities "/subscriptions/22c140ff-ca30-4d58-9223-08a6041970ab/resourceGroups/aiobx-aioedgeai-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aiobx-hev"
# az ml workspace show --resource-group aiobx-aioedgeai-rg --name mlw-aiobx-hev
# az connectedk8s show --resource-group aiobx-aioedgeai-rg --name aiobmcluster1 --query id --output tsv