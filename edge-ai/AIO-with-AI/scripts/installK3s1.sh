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
virtualMachineName=${14}
templateBaseUrl=${15}


#############################
# Script Definition
#############################

echo "";
echo "Paramaters:";
echo "   Resource Group Name: $rg";
echo "   Location: $amlworkspaceName"
echo "   vmUserAssignedIdentityPrincipalID: $vmUserAssignedIdentityPrincipalID"
echo "   customLocationRPSPID: $customLocationRPSPID"
echo "   keyVaultId: $keyVaultId"
echo "   keyVaultName: $keyVaultName"
echo "   subscriptionId: $subscriptionId"
echo "   spAppId: $spAppId"
echo "   spSecret: $spSecret"
echo "   tenantId: $tenantId"
echo "   spObjectId: $spObjectId"
echo "   virtualMachineName: $virtualMachineName"
echo "   templateBaseUrl: $templateBaseUrl"

# Injecting environment variables
logpath=/var/log/deploymentscriptlog

#############################
# Install Rancher K3s cluster
#############################
echo "Installing Rancher K3s cluster"
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

#############################
#Install Helm Arc Way
#############################
echo "Installing Helm"
sudo snap install helm --classic
#Updates the package lists on the system to include the packages available from the newly added Helm repository. This is from victors but not need
sudo apt-get update -y 

#############################
#Install Helm
#############################
# echo "Installing Helm"
# curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
# sudo apt-get install apt-transport-https --yes
# echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# sudo apt-get update -y
# sudo apt-get install helm -y
# echo "source <(helm completion bash)" >> /home/$adminUsername/.bashrc

#############################
#Install Azure CLI
#############################
echo "Installing Azure CLI"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#############################
#Azure Arc Extensions
#############################
echo "Connecting K3s cluster to Arc for K8s"
# #We might need to login with a user that has more permissions than the Azure VM UserAssignedIdentity
az login --identity --username $vmUserAssignedIdentityPrincipalID
# #az login --service-principal -u ${10} -p ${11} --tenant ${12}
# #az account set -s $subscriptionId

az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name connectedk8s --yes

# Use the az connectedk8s connect command to Arc-enable your Kubernetes cluster and manage it as part of your Azure resource group
az connectedk8s connect --resource-group $rg --name $arcK8sClusterName --location $location --kube-config /etc/rancher/k3s/k3s.yaml

az extension add --name "k8s-configuration" --yes
az extension add --name "k8s-extension" --yes
az extension add --name "customlocation" --yes
az extension add --name azure-iot-ops --allow-preview true --upgrade --yes

#az k8s-extension create --resource-group $rg --cluster-name $arcK8sClusterName -n "azuremonitor-containers" --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers
#az k8s-extension create -g $rg -c $arcK8sClusterName -n "azuremonitor-containers" --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers 

#############################
#Arc for Kubernetes GitOps
#############################
# echo "Configuring Arc for Kubernetes GitOps"
# az extension add -n k8s-configuration --yes
# az extension add -n k8s-extension --yes

# sudo apt-get update -y
# sudo apt-get upgrade -y

# # Deploy Extension
# # Need to be updated for Ai-In-A-Box Iot Operations Repo
# az k8s-extension create \
#     -g $rg \
#     -c $arcK8sClusterName \
#     -n gitops \
#     --cluster-type connectedClusters \
#     --extension-type=microsoft.flux

#############################
#Arc for Kubernetes AML Extension
#############################
#https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-kubernetes-extension
#allowInsecureConnections=True - Allow HTTP communication or not. HTTP communication is not a secure way. If not allowed, HTTPs will be used.
#InferenceRouterHA=False       - By default, AzureML extension will deploy 3 ingress controller replicas for high availability, which requires at least 3 workers in a cluster. Set this to False if you have less than 3 workers and want to deploy AzureML extension for development and testing only, in this case it will deploy one ingress controller replica only.
#--auto-upgrade-minor-version true
# az k8s-extension create \
#     -g $rg \
#     -c $arcK8sClusterName \
#     -n azureml \
#     --cluster-type connectedClusters \
#     --extension-type Microsoft.AzureML.Kubernetes \
#     --scope cluster \
#     --config enableTraining=False enableInference=True allowInsecureConnections=True inferenceRouterServiceType=loadBalancer inferenceRouterHA=False autoUpgrade=True installNvidiaDevicePlugin=False installPromOp=False installVolcano=False installDcgmExporter=False --auto-upgrade true --verbose 

#az k8s-extension create -g aibx-aioedgeai-rg -c aiobxcluster -n azureml --cluster-type connectedClusters --extension-type Microsoft.AzureML.Kubernetes --scope cluster --config enableInference=True allowInsecureConnections=True inferenceRouterServiceType=loadBalancer InferenceRouterHA=False privateEndpointILB=True 


#############################
#Azure IoT Operations
#############################
# Starting off the post deployment steps. The following steps are to deploy Azure IoT Operations components
# Reference: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#create-a-cluster
# echo "Deploy IoT Operations CCCCComponents"
# az extension add --upgrade --name azure-iot-ops --allow-preview true --yes

# echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
# echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
# echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

# sudo sysctl -p
##############################
# OBJECT_ID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
# echo "OBJECT_ID: $OBJECT_ID"

#Use the az connectedk8s enable-features command to enable custom location support on your cluster.
#This command uses the objectId of the Microsoft Entra ID application that the Azure Arc service uses.
#az connectedk8s enable-features -g $rg -n $arcK8sClusterName --custom-locations-oid $customLocationRPSPID --features cluster-connect custom-locations

#--simulate-plc -> Flag when set, will configure the OPC-UA broker installer to spin-up a PLC server.
#--include-dp -> Flag when set, Include Data Processor in the IoT Operations deployment. https://learn.microsoft.com/en-us/azure/iot-operations/process-data/overview-data-processor ->By default, Data Processor isn't included in an Azure IoT Operations Preview deployment. If you plan to use Data Processor, you must include it when you deploy Azure IoT Operations Preview - you can't add it later. 

#Deploy Azure IoT Operations. This command takes several minutes to complete:
#az iot ops init -g $rg --cluster $arcK8sClusterName --kv-id $keyVaultId --sp-app-id  $spAppId --sp-object-id $spObjectId --sp-secret $spSecret --simulate-plc --include-dp

#Deploy Azure Monitor Container Insights Extension
#Azure Monitor Container Insights provides visibility into the performance of workloads deployed on the Kubernetes cluster.
# az k8s-extension create \
#     -g $rg \
#     -c $arcK8sClusterName \
#     -n azuremonitor-containers \
#     --cluster-type connectedClusters \
#     --extension-type Microsoft.AzureMonitor.Containers