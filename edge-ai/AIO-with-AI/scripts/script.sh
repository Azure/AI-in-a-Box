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
# $8 = Azure KeyVault ID
# $9 = Subscription ID

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
#We might need to login with a user that has more permissions than the Azure VM UserAssignedIdentity
az login --identity --username $5 
az account set -s $9

az extension add --name connectedk8s --yes
# Use the az connectedk8s connect command to Arc-enable your Kubernetes cluster and manage it as part of your Azure resource group
az connectedk8s connect --resource-group $1 --name $2 --location $3 --kube-config /etc/rancher/k3s/k3s.yaml


#############################
#Arc for Kubernetes GitOps
#############################
echo "#############################"
echo "Configuring Arc for Kubernetes GitOps"
echo "#############################"
az extension add -n k8s-configuration --yes
az extension add -n k8s-extension --yes

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
echo "#############################"
echo "Deploy IoT Operations components"
echo "#############################"
az extension add --upgrade --name azure-iot-ops --allow-preview true --yes

echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

az connectedk8s enable-features -n $2 -g $1 --custom-locations-oid $6 --features cluster-connect custom-locations
az iot ops init --simulate-plc --cluster $2 --resource-group $1 --kv-id $(az keyvault show --name $7 -o tsv --query id)
