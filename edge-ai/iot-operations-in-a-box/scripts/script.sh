#!/bin/bash

#############################
# Script Params
#############################
# $1 = Azure Resource Group Name
# $2 = Azure Arc for Kubernetes cluster name
# $3 = Azure Arc for Kubernetes cluster location

#############################
# Script Definition
#############################
logpath=/var/log/deploymentscriptlog

#############################
#Install K3s
#############################
echo "#############################" >> $logpath
echo "Installing K3s CLI" >> $logpath
echo "#############################" >> $logpath
curl -sfL https://get.k3s.io | sh -

echo "
KUBECONFIG=~/.kube/config
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
" >> ~/.bashrc

KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"

#############################
#Install Helm
#############################
echo "#############################" >> $logpath
echo "Installing Helm" >> $logpath
echo "#############################" >> $logpath
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo "source <(helm completion bash)" >> ~/.bashrc

#############################
#Install Azure CLI
#############################
echo "#############################" >> $logpath
echo "Installing Azure CLI" >> $logpath
echo "#############################" >> $logpath
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#############################
#Arc for Kubernetes setup
#############################
az login --identity
az extension add --name connectedk8s
# az provider register --namespace Microsoft.Kubernetes
# az provider register --namespace Microsoft.KubernetesConfiguration
# az provider register --namespace Microsoft.ExtendedLocation

# Need to grab the resource group name of the VM
az connectedk8s connect --resource-group $1 --name $2 --location $3

#############################
#Arc for Kubernetes GitOps
#############################
az extension add -n k8s-configuration
az extension add -n k8s-extension

# Deploy Extension
# Need to be updated for Ai-In-A-Box Iot Operations Repo
az k8s-extension create \
    -g $1 \
    -c $2 \
    -n vws-app-config \
    --cluster-type managedClusters \
    --extension-type=microsoft.flux

# Front-End
# Need to be updated for Ai-In-A-Box Iot Operations Repo
az k8s-configuration flux create \
    -g $1 \
    -c $2 \
    -n vws-app-config \
    --namespace vws-app \
    -t managedClusters \
    --scope cluster \
    -u https://github.com/Welasco/testflux2.git \
    --interval 2m \
    --branch main \
    --kustomization name=vws-app path=./vws-app prune=true sync_interval=2m

