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

#1 install arc our way
#2 install arc our way with custom arc installation from arc jumpstart NSTALL_K3S_EXEC="server --disable traefik --node-external-ip ${publicIp}"
#3 install arc our way with custom arc installation and also with specific version
#4 install helm their way
#5 install helm our way
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
#Install Helm
#############################
# #echo "Installing Helm"
# #curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
# #sudo apt-get install apt-transport-https --yes
# #echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# #sudo apt-get update -y
# #sudo apt-get install helm -y
# #echo "source <(helm completion bash)" >> /home/$adminUsername/.bashrc

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

# sudo -u $adminUsername az config set extension.use_dynamic_install=yes_without_prompt
# sudo -u $adminUsername az extension add --name "connectedk8s" --yes
# sudo -u $adminUsername az extension add --name "k8s-configuration" --yes
# sudo -u $adminUsername az extension add --name "k8s-extension" --yes
# sudo -u $adminUsername az extension add --name "customlocation" --yes
# sudo -u $adminUsername az extension add --name azure-iot-ops --allow-preview true --upgrade --yes

#sudo -u $adminUsername az login --service-principal --username $appId --password=$spSecret --tenant $tenantId
#sudo -u $adminUsername az login --identity --username $vmUserAssignedIdentityPrincipalID

# Onboard the cluster to Azure Arc and enabling Container Insights using Kubernetes extension
#echo ""
# rg=$(sudo -u $adminUsername az resource list --query "[?name=='$virtualMachineName']".[resourceGroup] --resource-type "Microsoft.Compute/virtualMachines" -o tsv)
# Use the az connectedk8s connect command to Arc-enable your Kubernetes cluster and manage it as part of your Azure resource group
# sudo -u $adminUsername az connectedk8s connect --resource-group $rg --name $arcK8sClusterName --location $location --kube-config /home/${adminUsername}/.kube/config --tags 'Project=jumpstart_azure_arc_k8s' --correlation-id "d009f5dd-dba8-4ac7-bac9-b54ef3a6671a"
#sudo -u $adminUsername az k8s-extension create --resource-group $resourceGroup -n "azuremonitor-containers" --cluster-name $arcK8sClusterName  --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers
