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

export K3S_VERSION="1.28.5+k3s1" # Do not change!

# Creating login message of the day (motd)
# sudo curl -v -o /etc/profile.d/welcomeK3s.sh ${templateBaseUrl}scripts/welcomeK3s.sh

# Syncing this script log to 'jumpstart_logs' directory for ease of troubleshooting
sudo -u $adminUsername mkdir -p /home/${adminUsername}/jumpstart_logs
while sleep 1; do sudo -s rsync -a /var/lib/waagent/custom-script/download/0/installK3s.log /home/${adminUsername}/jumpstart_logs/installK3s.log; done &


