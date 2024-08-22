#!/bin/bash

az extension add --name ml --yes
az extension add --name connectedk8s --yes

#############################
# Script Params
# Attach a Kubernetes Cluster to Azure Machine Learning Workspace
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

resourceGroupName=$1
amlworkspaceName=$2
arcK8sClusterName=$3
vmUserAssignedIdentityID=$4
subscriptionId=$5

echo "Attach a Kubernetes Cluster to Azure Machine Learning Workspace";
 
if [[ -n "$1" ]]; then
    resourceGroupName=$1
    amlworkspaceName=$2
    arcK8sClusterName=$3

    echo "Executing from command line";
else
    echo "Executing from azd up";
fi

echo "";
echo "Paramaters:";
echo "   Resource Group Name: $resourceGroupName";
echo "   Machine Learning Workspace Name: $amlworkspaceName"
echo "   Arc Kubernetes Cluster Name: $arcK8sClusterName"
echo "   VM User Assigned Identity Resource Id: $vmUserAssignedIdentityID"

#workspace=$(az ml workspace show --resource-group $rg --name $amlworkspaceName)
arcK3sClusterId="$(az connectedk8s show --resource-group $resourceGroupName --name $arcK8sClusterName --query id --output tsv)"
echo "";
echo arcK3sClusterId: $arcK3sClusterId
echo ""
echo "Attaching K3s Cluster to Azure Machine Learning Workspace";

# Attach a Kubernetes cluster to Azure Machine Learning workspace
#https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-to-workspace
#https://learn.microsoft.com/en-us/cli/azure/ml/compute
# To disable the path conversion. You can set environment variable MSYS_NO_PATHCONV=1 or set it temporarily when a running command:
MSYS_NO_PATHCONV=1 az ml compute attach \
     --resource-group $resourceGroupName \
     --workspace-name $amlworkspaceName \
     --resource-id $arcK3sClusterId \
     --user-assigned-identities $vmUserAssignedIdentityID \
     --identity-type UserAssigned \
     --type Kubernetes \
     --name k3s-compute

echo ""
echo "K3s Cluster Attached Azure Machine Learning Workspace";