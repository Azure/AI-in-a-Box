#!/bin/bash

#############################
# Script Params
#############################
# $1 = Azure Resource Group Name
# $2 = Azure Arc for Kubernetes cluster name
# $3 = Azure Arc for Kubernetes cluster location
# $4 = Azure VM User Name
# $5 = Azure VM UserAssignedIdentity PrincipalId
# $6 = Object ID of the Service Principal for Custom Locations RP
# $7 = Azure KeyVault ID
# $8 = Azure KeyVault Name
# $9 = Subscription ID
# $10 = Azure Service Principal App ID
# $11 = Azure Service Principal Secret
# $12 = Azure Service Principal Tenant ID
# $13 = Azure Service Principal Object ID

#  1   ${resourceGroup().name}
#  2   ${arcK8sClusterName}
#  3   ${location}
#  4   ${adminUsername}
#  5   ${vmUserAssignedIdentityPrincipalID}
#  6   ${customLocationRPSPID}
#  7   ${keyVaultId}
#  8   ${keyVaultName}
#  9   ${subscription().subscriptionId}
#  10  ${spAppId}
#  11  ${spSecret}
#  12  ${subscription().tenantId}'
#  13  ${spObjectId}

rg=$1
arcK8sClusterName=$2
location=$3
adminUsername=$4
vmUserAssignedIdentityPrincipalID=$5
customLocationRPSPID=$6
keyVaultId=$7
keyVaultName=$8
subscriptionId=$9
spAppId=${10}
spSecret=${11}
tenantId=${12}
spObjectId=${13}

#############################
# Script Definition
#############################
logpath=/var/log/deploymentscriptlog

#############################
#Install K3s
#############################
echo "#############################"
echo "Installing K3s CLI"
echo "#############################"
curl -sfL https://get.k3s.io | sh -

mkdir -p /home/$adminUsername/.kube
echo "
export KUBECONFIG=~/.kube/config
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
" >> /home/$adminUsername/.bashrc

USERKUBECONFIG=/home/$adminUsername/.kube/config
sudo k3s kubectl config view --raw > "$USERKUBECONFIG"
chmod 600 "$USERKUBECONFIG"
chown $adminUsername:$adminUsername "$USERKUBECONFIG"

# Set KUBECONFIG for root - Current session
KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Sleep for 60 seconds to allow the cluster to be fully connected
#sleep 60

#############################
#Install Helm
#############################
echo "#############################"
echo "Installing Helm"
echo "#############################"
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update -y
sudo apt-get install helm -y
echo "source <(helm completion bash)" >> /home/$adminUsername/.bashrc

# Sleep for 60 seconds to allow the cluster to be fully connected
#sleep 60

#############################
#Install Azure CLI
#############################
echo "#############################"
echo "Installing Azure CLI"
echo "#############################"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#curl -L https://aka.ms/InstallAzureCLIDeb | sudo bash

# Sleep for 60 seconds to allow the cluster to be fully connected
#sleep 60

#############################
#Arc for Kubernetes setup
#############################
echo "#############################"
echo "Connecting K3s cluster to Arc for K8s"
echo "#############################"
#We might need to login with a user that has more permissions than the Azure VM UserAssignedIdentity
az login --identity --username $vmUserAssignedIdentityPrincipalID
#az login --service-principal -u ${10} -p ${11} --tenant ${12}
#az account set -s $subscriptionId

az config set extension.use_dynamic_install=yes_without_prompt

az extension add --name connectedk8s --yes
# Use the az connectedk8s connect command to Arc-enable your Kubernetes cluster and manage it as part of your Azure resource group
az connectedk8s connect --resource-group $rg --name $arcK8sClusterName --location $location --kube-config /etc/rancher/k3s/k3s.yaml

# Sleep for 60 seconds to allow the cluster to be fully connected
#sleep 60

#############################
#Arc for Kubernetes GitOps
#############################
echo "#############################"
echo "Configuring Arc for Kubernetes GitOps"
echo "#############################"
az extension add -n k8s-configuration --yes
az extension add -n k8s-extension --yes

sudo apt-get update -y
sudo apt-get upgrade -y

# Sleep for 60 seconds to allow the cluster to be fully connected
sleep 60

# Deploy Extension
# Need to be updated for Ai-In-A-Box Iot Operations Repo
az k8s-extension create \
    -g $rg \
    -c $arcK8sClusterName \
    -n gitops \
    --cluster-type connectedClusters \
    --extension-type=microsoft.flux

# Front-End
# Need to be updated for Ai-In-A-Box Iot Operations Repo
# az k8s-configuration flux create \
#     -g $rg \
#     -c $arcK8sClusterName \
#     -n gitops \
#     --namespace vws-app \
#     -t connectedClusters \
#     --scope cluster \
#     -u https://github.com/Welasco/testflux2.git \
#     --interval 2m \
#     --branch main \
#     --kustomization name=vws-app path=./vws-app prune=true sync_interval=2m


#############################
#Azure IoT Operations
#############################
# Starting off the post deployment steps. The following steps are to deploy Azure IoT Operations components
# Reference: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#create-a-cluster
echo "#############################"
echo "Deploy IoT Operations CCComponents"
echo "#############################"
az extension add --upgrade --name azure-iot-ops --allow-preview true --yes

echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p
##############################
# OBJECT_ID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
# echo "OBJECT_ID: $OBJECT_ID"
#az iot ops init --simulate-plc -g $rg --cluster $arcK8sClusterName --kv-id $kv_id
az connectedk8s enable-features -g $rg \
    -n $arcK8sClusterName \
    --custom-locations-oid $customLocationRPSPID \
    --features cluster-connect custom-locations

az iot ops init -g $rg \
    --cluster $arcK8sClusterName \
    --kv-id $keyVaultId \
    --sp-app-id  $spAppId \
    --sp-object-id $spObjectId \
    --sp-secret $spSecret
