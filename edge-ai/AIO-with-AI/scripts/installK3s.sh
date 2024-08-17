#!/bin/bash
exec >installK3s.log
exec 2>&1

sudo apt-get update

sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
sudo adduser staginguser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
sudo echo "staginguser:ArcPassw0rd" | sudo chpasswd

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

# Determine the Fileshare name in Azure Storage Account
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
echo '#!/bin/bash' >> vars.sh
echo $adminUsername:$4 | awk '{print substr($1,2); }' >> vars.sh
echo $spAppId:${10} | awk '{print substr($1,2); }' >> vars.sh
echo $spSecret:${11} | awk '{print substr($1,2); }' >> vars.sh
echo $tenantId:${12} | awk '{print substr($1,2); }' >> vars.sh
echo $arcK8sClusterName:$2 | awk '{print substr($1,2); }' >> vars.sh
echo $virtualMachineName:${14} | awk '{print substr($1,2); }' >> vars.sh
echo $location:$3 | awk '{print substr($1,2); }' >> vars.sh
echo $templateBaseUrl:${15} | awk '{print substr($1,2); }' >> vars.sh
sed -i '2s/^/export adminUsername=/' vars.sh
sed -i '3s/^/export appId=/' vars.sh
sed -i '4s/^/export spSecret=/' vars.sh
sed -i '5s/^/export tenantId=/' vars.sh
sed -i '6s/^/export arcK8sClusterName=/' vars.sh
sed -i '7s/^/export virtualMachineName=/' vars.sh
sed -i '8s/^/export location=/' vars.sh
sed -i '9s/^/export templateBaseUrl=/' vars.sh


chmod +x vars.sh
. ./vars.sh


logpath=/var/log/deploymentscriptlog
export K3S_VERSION="1.28.5+k3s1" # Do not change!

# Syncing this script log to 'jumpstart_logs' directory for ease of troubleshooting
sudo -u $adminUsername mkdir -p /home/${adminUsername}/jumpstart_logs
while sleep 1; do sudo -s rsync -a /var/lib/waagent/custom-script/download/0/installK3s.log /home/${adminUsername}/jumpstart_logs/installK3s.log; done &

#############################
#Install K3s Arch Jumpstart Mothod
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

#############################
#Install Azure CLI
#############################
echo "Installing Azure CLI"
sudo apt-get update
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#############################
#Azure Arc Extensions
#############################
echo "Connecting K3s cluster to Arc for K8s"

#sudo -u $adminUsername az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.use_dynamic_install=yes_without_prompt
# sudo -u $adminUsername az extension add --name "connectedk8s" --yes
az extension add --name "connectedk8s" --yes
# sudo -u $adminUsername az extension add --name "k8s-configuration" --yes
az extension add --name "k8s-configuration" --yes
# sudo -u $adminUsername az extension add --name "k8s-extension" --yes
az extension add --name "k8s-extension" --yes
# sudo -u $adminUsername az extension add --name "customlocation" --yes
az extension add --name "customlocation" --yes
# sudo -u $adminUsername az extension add --name azure-iot-ops --allow-preview true --upgrade --yes
az extension add --name azure-iot-ops --allow-preview true --upgrade --yes

#sudo -u $adminUsername az login --service-principal --username $appId --password=$spSecret --tenant $tenantId
#sudo -u $adminUsername az login --identity --username $vmUserAssignedIdentityPrincipalID

# Onboard the cluster to Azure Arc and enabling Container Insights using Kubernetes extension
echo ""
# rg=$(sudo -u $adminUsername az resource list --query "[?name=='$virtualMachineName']".[resourceGroup] --resource-type "Microsoft.Compute/virtualMachines" -o tsv)
# Use the az connectedk8s connect command to Arc-enable your Kubernetes cluster and manage it as part of your Azure resource group
# sudo -u $adminUsername az connectedk8s connect --resource-group $rg --name $arcK8sClusterName --location $location --kube-config /home/${adminUsername}/.kube/config --tags 'Project=jumpstart_azure_arc_k8s' --correlation-id "d009f5dd-dba8-4ac7-bac9-b54ef3a6671a"
# sudo -u $adminUsername az connectedk8s connect --resource-group $rg --name $arcK8sClusterName --location $location --kube-config /etc/rancher/k3s/k3s.yaml
#az connectedk8s connect --resource-group $rg --name $arcK8sClusterName --location $location --kube-config /etc/rancher/k3s/k3s.yaml

#sudo -u $adminUsername az k8s-extension create --resource-group $resourceGroup -n "azuremonitor-containers" --cluster-name $arcK8sClusterName  --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers
#sudo -u $adminUsernmae az k8s-extension create -g $rg -c $arcK8sClusterName -n "azuremonitor-containers" --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers 
#sudo -u $adminUsernmae az k8s-extension create -g $rg -c $arcK8sClusterName -n azureml --cluster-type connectedClusters --extension-type Microsoft.AzureML.Kubernetes --scope cluster --config enableTraining=False enableInference=True allowInsecureConnections=True inferenceRouterServiceType=loadBalancer inferenceRouterHA=False autoUpgrade=True installNvidiaDevicePlugin=False installPromOp=False installVolcano=False installDcgmExporter=False --auto-upgrade true --verbose 
