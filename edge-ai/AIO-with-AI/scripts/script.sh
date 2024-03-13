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

mkdir -p /home/$4/.kube
echo "
export KUBECONFIG=~/.kube/config
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
" >> /home/$4/.bashrc

USERKUBECONFIG=/home/$4/.kube/config
sudo k3s kubectl config view --raw > "$USERKUBECONFIG"
chmod 600 "$USERKUBECONFIG"
chown $4:$4 "$USERKUBECONFIG"

# Set KUBECONFIG for root - Current session
KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

#############################
#Install Helm
#############################
echo "#############################"
echo "Installing Helm"
echo "#############################"
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo "source <(helm completion bash)" >> /home/$4/.bashrc

#############################
#Install Azure CLI
#############################
echo "#############################"
echo "Installing Azure CLI"
echo "#############################"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#############################
#Arc for Kubernetes setup
#############################
echo "#############################"
echo "Connecting K3s cluster to Arc for K8s"
echo "#############################"
az login --identity --username $5
az extension add --name connectedk8s
# az provider register --namespace Microsoft.Kubernetes
# az provider register --namespace Microsoft.KubernetesConfiguration
# az provider register --namespace Microsoft.ExtendedLocation

# Need to grab the resource group name of the VM
az connectedk8s connect --resource-group $1 --name $2 --location $3 --kube-config /etc/rancher/k3s/k3s.yaml

#############################
#Arc for Kubernetes GitOps
#############################
echo "#############################"
echo "Configuring Arc for Kubernetes GitOps"
echo "#############################"
az extension add -n k8s-configuration
az extension add -n k8s-extension

# Sleep for 60 seconds to allow the cluster to be fully connected
#sleep 60

# Deploy Extension
# Need to be updated for Ai-In-A-Box Iot Operations Repo
az k8s-extension create \
    -g $1 \
    -c $2 \
    -n gitops \
    --cluster-type connectedClusters \
    --extension-type=microsoft.flux

# Front-End
# Need to be updated for Ai-In-A-Box Iot Operations Repo
# az k8s-configuration flux create \
#     -g $1 \
#     -c $2 \
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

# This needs to be run by elevated user.
sudo apt install nfs-common

echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

az extension add --upgrade --name azure-iot-ops

# Creating keyvault which is required for IoT Operations
# this step will be done in Bicep
# command reference only
#az keyvault create --enable-rbac-authorization false  --name "<KeyVault Name>" --resource-group $1 --location "EastUS" ## This was created using portal shell.
# Example: az keyvault create --enable-rbac-authorization false  --name "nab-r7v26nydafn7c-kv" --resource-group $1 --location "EastUS" ## This was created using portal shell.

# The Object ID: bc313c14-388c-4e7d-a58e-70017303ee3b is Custom Locations RP
# The Service Principal for this Object ID is created during the resource provider registration for Custom Locations
# By default Managed Identities doesn't have access to query MS Graph and this step of quering the Object ID of the Service Principal is required to be executed a Pre-Step and passed as parameter
# Command for reference only
#export OBJECT_ID = $(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)

az connectedk8s enable-features -n $2 -g $1 --custom-locations-oid $6 --features cluster-connect custom-locations

# Need to review with Nabeel if we should use the additional parameters --dp-instance, --simulate-plc, --mq-instance --mq-mode
# reference: https://learn.microsoft.com/en-us/azure/iot-operations/get-started/quickstart-deploy?tabs=linux
az iot ops init --cluster $2 -g $1 --kv-id $7