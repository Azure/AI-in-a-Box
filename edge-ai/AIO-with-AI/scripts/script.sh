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
