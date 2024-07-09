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
# $7 = Azure keyVaultName

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

#############################
#Install Helm
#############################
echo "#############################"
echo "Installing Helm"
echo "#############################"

#############################
#Install Azure CLI
#############################
echo "#############################"
echo "Installing Azure CLI"
echo "#############################"

#############################
#Arc for Kubernetes setup
#############################
echo "#############################"
echo "Connecting K3s cluster to Arc for K8s"
echo "#############################"

#############################
#Arc for Kubernetes GitOps
#############################
echo "#############################"
echo "Configuring Arc for Kubernetes GitOps"
echo "#############################"

#############################
#Azure IoT Operations
#############################
# Starting off the post deployment steps. The following steps are to deploy Azure IoT Operations components
# Reference: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#create-a-cluster
echo "#############################"
echo "Deploy IoT Operations components"
echo "#############################"
az extension add --upgrade --name azure-iot-ops

echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

az connectedk8s enable-features -n $2 -g $1 --custom-locations-oid $6 --features cluster-connect custom-locations

az iot ops verify-host

az iot ops init --simulate-plc --cluster $2 --resource-group $1 --kv-id $(az keyvault show --name $7 -o tsv --query id)

kubectl get deployments,pods -n azure-arc
kubectl get pods -n azure-iot-operations

az iot ops check
