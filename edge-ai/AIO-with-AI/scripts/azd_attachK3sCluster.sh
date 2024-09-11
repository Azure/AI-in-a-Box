#!/bin/bash

az extension add -n ml
az extension add -n connectedk8s


#############################
# Script Params
# Attach a Kubernetes Cluster to Azure Machine Learning Workspace
# ./azd_attachK3sCluster.sh aiobx-aioedgeai-rg mlw-aiobx-hev aiobmcluster1 /subscriptions/22c140ff-ca30-4d58-9223-08a6041970ab/resourceGroups/aiobx-aioedgeai-rg/providers/Microsoft.Kubernetes/connectedClusters/aiobmcluster1 /subscriptions/22c140ff-ca30-4d58-9223-08a6041970ab/resourcegroups/aiobx-aioedgeai-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aiobx-hev 22c140ff-ca30-4d58-9223-08a6041970ab
#############################

# $1 = Azure Resource Group Name
# $2 = Azure Machine Learning Workspace Name
# $3 = Azure Arc for Kubernetes Cluster name
# $4 = Azure Arc for Kubernetes Resource Id
# $5 = Azure VM UserAssignedIdentity Resource Id
# $6 = Subscription ID

#  1   ${resourceGroup().name}
#  2   ${amlworkspaceName}
#  3   ${arcK8sClusterName}
#  4   ${arcK8sClusterId}
#  5   ${vmUserAssignedIdentityID}
#  6   ${subscription().subscriptionId}

# To disable the path conversion. You can set environment variable MSYS_NO_PATHCONV=1 or set it temporarily when a running command:
export MSYS_NO_PATHCONV=1

echo "Attach a Kubernetes Cluster to Azure Machine Learning Workspace";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    amlworkspaceName=$2
    arcK8sClusterName=$3
    arcK8sClusterId=$4
    vmUserAssignedIdentityID=$5
    subscriptionId=$6

    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Machine Learning Workspace Name: $amlworkspaceName"
echo "   Arc Kubernetes Cluster Name: $arcK8sClusterName"
echo "   Arc Kubernetes Cluster Resource Id: $arcK8sClusterId"
echo "   User Assigned Identity Resource Id: $vmUserAssignedIdentityID"

#workspaceId=$(az ml workspace show --name $amlworkspaceName --resource-group $resourceGroupName --query "id" --output tsv)
#arcK8sClusterId=$(az connectedk8s show --name $arcK8sClusterName --resource-group $resourceGroupName --query "id" --output tsv)
#arcK8sClusterId=$(az connectedk8s show --name aiobmcluster1 --resource-group aiobx-aioedgeai-rg --query "id" --output tsv)

echo "";
echo "Get Azure ML Workspace";
echo "   Workspace Id: $workspaceId"
echo "Get K3s Cluster";
echo "   Cluster Id: $arcK8sClusterId"

# python "Attach_K3s.py" -g $resourceGroupName -w $amlworkspaceName -c $arcK8sClusterId -u $vmUserAssignedIdentityID -s $subscriptionId

# Attach a Kubernetes cluster to Azure Machine Learning workspace
# https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-to-workspace
# https://learn.microsoft.com/en-us/cli/azure/ml/compute
# Set the namespace to azureml-workloads so that all model deployments are created in this namespace from Azure ML Studio: kubectl get onlineEndpoint -n azureml-workloads
# The namespace was created in the installK3s1.sh script

az ml compute attach \
     --resource-group $resourceGroupName \
     --workspace-name $amlworkspaceName \
     --resource-id $arcK8sClusterId \
     --user-assigned-identities $vmUserAssignedIdentityID \
     --identity-type UserAssigned \
     --type Kubernetes \
     --namespace azureml-workloads \ 
     --name k3s-cluster