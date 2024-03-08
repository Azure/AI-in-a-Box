
# Starting off the post deployment steps. The following steps are to deploy Azure IoT Operations components

# Reference: https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-prepare-cluster?tabs=ubuntu#create-a-cluster


# This needs to be run by elevated user.
sudo apt install nfs-common

echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
echo fs.file-max = 100000 | sudo tee -a /etc/sysctl.conf

sudo sysctl -p


az provider register -n "Microsoft.ExtendedLocation"
az provider register -n "Microsoft.Kubernetes"
az provider register -n "Microsoft.KubernetesConfiguration"
az provider register -n "Microsoft.IoTOperationsOrchestrator"
az provider register -n "Microsoft.IoTOperationsMQ"
az provider register -n "Microsoft.IoTOperationsDataProcessor"
az provider register -n "Microsoft.DeviceRegistry"



# https://learn.microsoft.com/en-us/azure/iot-operations/deploy-iot-ops/howto-deploy-iot-operations?tabs=portal
az extension add --upgrade --name azure-iot-ops

# All above needs to be run by elevated user.

# Creating a new KeyVault -- This will go to bicep portion. We need to add KeyVaultName as the paramter to Bicep as well.
az login --identity --username $5

az keyvault create --enable-rbac-authorization false  --name "<KeyVault Name>" --resource-group $1 --location "EastUS" ## This was created using portal shell. 
# Example: az keyvault create --enable-rbac-authorization false  --name "nab-r7v26nydafn7c-kv" --resource-group $1 --location "EastUS" ## This was created using portal shell. 



###
# This IoT Operations deployment config includes resource sync rules which require the logged-in principal
# to have permission to write role assignments (Microsoft.Authorization/roleAssignments/write) against the resource group.

# Use --disable-rsync-rules to not include resource sync rules in the deployment.
# Use --no-preflight to skip pre-flight checks.

###

# This the following needs to be run by the service principal.
export OBJECT_ID = $(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)
az connectedk8s enable-features -n $2 -g $1 --custom-locations-oid $OBJECT_ID --features cluster-connect custom-locations

az iot ops verify-host

az iot ops init --cluster <CLUSTER_NAME> -g "rg-nab" --kv-id $(az keyvault create -n <NEW_KEYVAULT_NAME> -g <RESOURCE_GROUP> -o tsv --query id)

az iot ops init --cluster $2 -g $1 --kv-id "<KeyVaultId>"
# Example: az iot ops init --cluster "nabeelK3sArcCluster" -g "rg-nab" --kv-id "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-nab/providers/Microsoft.KeyVault/vaults/nab-r7v26nydafn7c-kv"

# This the following needs to be run by the service principal.



# Following is a typical output
# {
#   "clusterName": "nabeelK3sArcCluster",
#   "clusterNamespace": "azure-iot-operations",
#   "csiDriver": {
#     "enableSecretRotation": "true",
#     "keyVaultId": "/subscriptions/310d16c1-82db-4aed-bdc1-9c7a4a8f0098/resourceGroups/rg-nab/providers/Microsoft.KeyVault/vaults/nab-r7v26nydafn7c-kv",
#     "kvSatSecretName": "azure-iot-operations",
#     "rotationPollInterval": "1h",
#     "spAppId": "14d8fe6b-8f79-46f1-b72f-0456e1bf4062",
#     "spObjectId": "e9c1cae6-be29-45a1-b0ec-06ffdf9588cf",
#     "version": "1.5.1"
#   },
#   "deploymentLink": "https://portal.azure.com/#blade/HubsExtension/DeploymentDetailsBlade/id/%2Fsubscriptions%2F310d16c1-82db-4aed-bdc1-9c7a4a8f0098%2FresourceGroups%2Frg-nab%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2Faziotops.init.10538a3e284a4e9fb035c9fb700e87b8",
#   "deploymentName": "aziotops.init.10538a3e284a4e9fb035c9fb700e87b8",
#   "deploymentState": {
#     "correlationId": "17a1b874-8340-463c-9582-88b78ad7bbb8",
#     "opsVersion": {
#       "adr": "0.1.0-preview",
#       "aio": "0.3.0-preview",
#       "akri": "0.1.0-preview",
#       "layeredNetworking": "0.1.0-preview",
#       "mq": "0.2.0-preview",
#       "observability": "0.1.0-preview",
#       "opcUaBroker": "0.2.0-preview",
#       "processor": "0.1.2-preview"
#     },
#     "resources": [
#       "Microsoft.ExtendedLocation/customLocations/nabeelk3sarccluster-ops-init-cl",
#       "Microsoft.ExtendedLocation/customLocations/nabeelk3sarccluster-ops-init-cl/resourceSyncRules/nabeelk3sarccluster-ops-init-cl-adr-sync",
#       "Microsoft.ExtendedLocation/customLocations/nabeelk3sarccluster-ops-init-cl/resourceSyncRules/nabeelk3sarccluster-ops-init-cl-aio-sync",
#       "Microsoft.ExtendedLocation/customLocations/nabeelk3sarccluster-ops-init-cl/resourceSyncRules/nabeelk3sarccluster-ops-init-cl-dp-sync",
#       "Microsoft.ExtendedLocation/customLocations/nabeelk3sarccluster-ops-init-cl/resourceSyncRules/nabeelk3sarccluster-ops-init-cl-mq-sync",
#       "Microsoft.IoTOperationsDataProcessor/instances/nabeelk3sarccluster-ops-init-processor",
#       "Microsoft.IoTOperationsMQ/mq/init-1162c-mq-instance",
#       "Microsoft.IoTOperationsMQ/mq/init-1162c-mq-instance/broker/broker",
#       "Microsoft.IoTOperationsMQ/mq/init-1162c-mq-instance/broker/broker/authentication/authn",
#       "Microsoft.IoTOperationsMQ/mq/init-1162c-mq-instance/broker/broker/listener/listener",
#       "Microsoft.IoTOperationsMQ/mq/init-1162c-mq-instance/diagnosticService/diagnostics",
#       "Microsoft.IoTOperationsOrchestrator/targets/nabeelk3sarccluster-ops-init-target",
#       "Microsoft.Kubernetes/connectedClusters/nabeelK3sArcCluster/providers/Microsoft.KubernetesConfiguration/extensions/akri",
#       "Microsoft.Kubernetes/connectedClusters/nabeelK3sArcCluster/providers/Microsoft.KubernetesConfiguration/extensions/assets",
#       "Microsoft.Kubernetes/connectedClusters/nabeelK3sArcCluster/providers/Microsoft.KubernetesConfiguration/extensions/azure-iot-operations",
#       "Microsoft.Kubernetes/connectedClusters/nabeelK3sArcCluster/providers/Microsoft.KubernetesConfiguration/extensions/layered-networking",
#       "Microsoft.Kubernetes/connectedClusters/nabeelK3sArcCluster/providers/Microsoft.KubernetesConfiguration/extensions/mq",
#       "Microsoft.Kubernetes/connectedClusters/nabeelK3sArcCluster/providers/Microsoft.KubernetesConfiguration/extensions/processor"
#     ],
#     "status": "Succeeded",
#     "timestampUtc": {
#       "ended": "2024-03-05T22:17:27",
#       "started": "2024-03-05T22:10:11"
#     }
#   },
#   "resourceGroup": "rg-nab",
#   "tls": {
#     "aioTrustConfigMap": "aio-ca-trust-bundle-test-only",
#     "aioTrustSecretName": "aio-ca-key-pair-test-only"
#   }
# }

# Installing Open service mesh. Reference https://aepreviews.ms/docs/edge-storage-accelerator/prepare-linux/arc-connected-aks-on-azure/
# Why we need OSM? We need to enhance the edge capabilities by adding Edge storage accelerator. More details here: https://aepreviews.ms/docs/edge-storage-accelerator/overview/
# Prerequisite: Per documentation for Rre-Requisite is here: https://aepreviews.ms/docs/edge-storage-accelerator/prepare-linux/#pre-requisites
# Note: For Ubuntu 20.04 on Standard D8s v3 machines we need 3 SSDs attached for additional storage.

az k8s-extension create --resource-group "rg-nab" --cluster-name "nabeelK3sArcCluster" --cluster-type connectedClusters --extension-type Microsoft.openservicemesh --scope cluster --name osm
kubectl patch meshconfig osm-mesh-config -n "arc-osm-system" -p '{"spec":{"featureFlags":{"enableWASMStats": false }, "traffic":{"outboundPortExclusionList":[443,2379,2380], "inboundPortExclusionList":[443,2379,2380]}}}' --type=merge


