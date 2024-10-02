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
# $14 = Azure Service Principal App Object ID

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
#  14  ${spAppObjectId}

sudo apt-get update

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
spAppObjectId=${14}


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
echo "   spAppObjectId: $spAppObjectId"

# Injecting environment variables
logpath=/var/log/deploymentscriptlog

#############################
# Install Rancher K3s Cluster Jumpstart Method
# Installing Rancher K3s cluster (single control plane)
#############################
echo "Installing Rancher K3s cluster"
publicIp=$(hostname -i)

# sudo mkdir ~/.kube
# sudo -u $adminUsername mkdir /home/${adminUsername}/.kube
# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --node-external-ip ${publicIp}" INSTALL_K3S_VERSION=v${K3S_VERSION} sh -
# sudo chmod 644 /etc/rancher/k3s/k3s.yaml
# sudo kubectl config rename-context default arck3sdemo --kubeconfig /etc/rancher/k3s/k3s.yaml
# sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
# sudo cp /etc/rancher/k3s/k3s.yaml /home/${adminUsername}/.kube/config
# sudo cp /etc/rancher/k3s/k3s.yaml /home/${adminUsername}/.kube/config.staging
# sudo chown -R $adminUsername /home/${adminUsername}/.kube/
# sudo chown -R staginguser /home/${adminUsername}/.kube/config.staging

#############################
# Install Rancher K3s Cluster AI-In-A-Box Method
#############################
echo "Installing Rancher K3s cluster"
#curl -sfL https://get.k3s.io | sh -
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --node-external-ip ${publicIp}" sh -

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
#Install Helm - Quick, easy, and cross-distribution installation method with automatic updates and minimal setup
#############################
#echo "Installing Helm"
#sudo snap install helm --classic

#############################
#Install Helm - If you prefer full system integration, more control over the installation process, and you're working on a Debian-based system where this method is supported
#############################
echo "Installing Helm"
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update -y
sudo apt-get install helm -y
echo "source <(helm completion bash)" >> /home/$adminUsername/.bashrc

#############################
#Install Azure CLI
#############################
echo "Installing Azure CLI"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#curl -L https://aka.ms/InstallAzureCLIDeb | sudo bash

#############################
#Azure Arc - Onboard the Cluster to Azure Arc
#############################
echo "Connecting K3s cluster to Arc for K8s"
az login --identity --username $vmUserAssignedIdentityPrincipalID
#az login --service-principal -u ${10} -p ${11} --tenant ${12}
#az account set -s $subscriptionId

az config set extension.use_dynamic_install=yes_without_prompt

az extension add --name connectedk8s --yes

# Use the az connectedk8s connect command to Arc-enable your Kubernetes cluster and manage it as part of your Azure resource group
az connectedk8s connect \
    --resource-group $rg \
    --name $arcK8sClusterName \
    --location $location \
    --kube-config /etc/rancher/k3s/k3s.yaml

#############################
#Arc for Kubernetes Extensions
#############################
echo "Configuring Arc for Kubernetes GitOps"
az extension add -n k8s-configuration --yes
az extension add -n k8s-extension --yes

sudo apt-get update -y
sudo apt-get upgrade -y

# Sleep for 60 seconds to allow the cluster to be fully connected
sleep 60

#############################
#Azure IoT Operations
#############################
# Starting off the post deployment steps. The following steps are to deploy Azure IoT Operations components
# Reference: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#create-a-cluster
# Reference: https://learn.microsoft.com/en-us/cli/azure/iot/ops?view=azure-cli-latest#az-iot-ops-init
echo "Deploy IoT Operations Components"
az extension add --upgrade --name azure-iot-ops --allow-preview true --yes

#Increase user watch/instance limits:
echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
#Increase file descriptor limit:
echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf 

sudo sysctl -p

#Use the az connectedk8s enable-features command to enable custom location support on your cluster.
#This command uses the objectId of the Microsoft Entra ID application that the Azure Arc service uses.
echo "Enabling custom location support on the Arc cluster"

az connectedk8s enable-features -g $rg \
    -n $arcK8sClusterName \
    --custom-locations-oid $customLocationRPSPID \
    --features cluster-connect custom-locations

#Deploy Azure IoT Operations. This command takes several minutes to complete.
#--simulate-plc -> Flag to enable a simulated PLC. Flag when set, will configure the OPC-UA broker installer to spin-up a PLC server.
#--include-dp -> Flag when set, Include Data Processor in the IoT Operations deployment. https://learn.microsoft.com/en-us/azure/iot-operations/process-data/overview-data-processor ->By default, Data Processor isn't included in an Azure IoT Operations Preview deployment. If you plan to use Data Processor, you must include it when you deploy Azure IoT Operations Preview - you can't add it later. 

echo "Deploy Azure IoT Operations - Configure and deploy IoT Operations to the target Arc-enabled Cluster"
az iot ops init -g $rg \
    --cluster $arcK8sClusterName \
    --kv-id $keyVaultId \
    --sp-app-id  $spAppId \
    --sp-object-id $spObjectId \
    --sp-secret $spSecret \
    --kubernetes-distro k3s \
    --simulate-plc 

#############################
#Arc for Kubernetes AML Extension
#############################
#https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-kubernetes-extension
#allowInsecureConnections=True - Allow HTTP communication or not. HTTP communication is not a secure way. If not allowed, HTTPs will be used.
#InferenceRouterHA=False       - By default, AzureML extension will deploy 3 ingress controller replicas for high availability, which requires at least 3 workers in a cluster. Set this to False if you have less than 3 workers and want to deploy AzureML extension for development and testing only, in this case it will deploy one ingress controller replica only.
az k8s-extension create \
    -g $rg \
    -c $arcK8sClusterName \
    -n azureml \
    --cluster-type connectedClusters \
    --extension-type Microsoft.AzureML.Kubernetes \
    --scope cluster \
    --config enableTraining=False enableInference=True allowInsecureConnections=True inferenceRouterServiceType=loadBalancer inferenceRouterHA=False autoUpgrade=True installNvidiaDevicePlugin=False installPromOp=False installVolcano=False installDcgmExporter=False --auto-upgrade true --verbose # This is since our K3s is 1 node


#############################
#Deploy Namespace, InfluxDB, Simulator, and Redis
#############################
#Create a folder for Cerebral configuration files
mkdir -p /home/$adminUsername/cerebral
sleep 60

#Apply the Cerebral namespace
kubectl apply -f https://raw.githubusercontent.com/Azure/arc_jumpstart_drops/main/sample_app/cerebral_genai/deployment/cerebral-ns.yaml

#Create a directory for persistent InfluxDB data
sudo mkdir /var/lib/influxdb2
sudo chmod 777 /var/lib/influxdb2

#Deploy InfluxDB, Configure InfluxDB, and Deploy the Data Simulator
kubectl apply -f https://raw.githubusercontent.com/Azure/arc_jumpstart_drops/main/sample_app/cerebral_genai/deployment/influxdb.yaml
sleep 30
kubectl apply -f https://raw.githubusercontent.com/Azure/arc_jumpstart_drops/main/sample_app/cerebral_genai/deployment/influxdb-setup.yaml
sleep 30
kubectl apply -f https://raw.githubusercontent.com/Azure/arc_jumpstart_drops/main/sample_app/cerebral_genai/deployment/cerebral-simulator.yaml
sleep 30

#Validate the implementation
kubectl get all -n cerebral

#Deploy Redis to store user sessions and conversation history
kubectl apply -f https://raw.githubusercontent.com/Azure/arc_jumpstart_drops/main/sample_app/cerebral_genai/deployment/redis.yaml

#Deploy Cerebral Application
#Download the Cerebral application deployment file
sleep 30
wget -P /home/$adminUsername/cerebral https://raw.githubusercontent.com/Azure/arc_jumpstart_drops/main/sample_app/cerebral_genai/deployment/cerebral.yaml

sed -i 's/<YOUR_OPENAI>/65b22c3cec9d449e881b54efc91e0db3/g' /home/$adminUsername/cerebral/cerebral.yaml
sed -i 's#<AZURE OPEN AI ENDPOINT>#https://aistdioserviceeast.openai.azure.com/#g' /home/$adminUsername/cerebral/cerebral.yaml
# sed -i 's/2024-03-01-preview/2024-03-15-preview/g' /home/$adminUsername/cerebral/cerebral.yaml

kubectl apply -f /home/$adminUsername/cerebral/cerebral.yaml
sleep 30

#Install Dapr runtime on the cluster
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update
helm upgrade --install dapr dapr/dapr --version=1.11 --namespace dapr-system --create-namespace --wait
sleep 30

#Creating the ML workload namespace
#https://medium.com/@jmasengesho/azure-machine-learning-service-for-kubernetes-architects-deploy-your-first-model-on-aks-with-az-440ada47b4a0
#When creating the Azure ML Extension we do not all the ML workloads and models we create later on on the same namespace as the Azure ML Extension.
#We create a separate namespace for the ML workloads and models.
kubectl create namespace azureml-workloads
kubectl get all -n azureml-workloads

#Deploy Azure IoT MQ - Dapr PubSub Component
#rag-on-edge-pubsub-broker: a pub/sub message broker for message passing between the components.
kubectl apply -f https://raw.githubusercontent.com/Azure/AI-in-a-Box/refs/heads/aio-with-ai/edge-ai/AIO-with-AI/rag-on-edge/yaml/rag-mq-components-aio0p6.yaml

#Deploy RAG on the Edge
#Deploy tho other components of RAG on the Edge

#rag-on-edge-web: a web application to interact with the user to submit the search and generation query.
kubectl apply -f https://raw.githubusercontent.com/Azure/AI-in-a-Box/refs/heads/aio-with-ai/edge-ai/AIO-with-AI/rag-on-edge/yaml/rag-web-workload-aio0p6-acrairstream.yaml

#rag-on-edge-interface: an interface module to interact with web frontend and the backend components.
kubectl apply -f https://raw.githubusercontent.com/Azure/AI-in-a-Box/refs/heads/aio-with-ai/edge-ai/AIO-with-AI/rag-on-edge/yaml/rag-interface-dapr-workload-aio0p6-acrairstream.yaml

#rag-on-edge-vectorDB: a database to store the vectors. 
kubectl apply -f https://raw.githubusercontent.com/Azure/AI-in-a-Box/refs/heads/aio-with-ai/edge-ai/AIO-with-AI/rag-on-edge/yaml/rag-vdb-dapr-workload-aio0p6-acr-airstream.yaml

#rag-on-edge-LLM: a large language model (LLM) to generate the response based on the vector search result.
kubectl apply -f https://raw.githubusercontent.com/Azure/AI-in-a-Box/refs/heads/aio-with-ai/edge-ai/AIO-with-AI/rag-on-edge/yaml/rag-llm-dapr-workload-aio0p6-acrairstream.yaml