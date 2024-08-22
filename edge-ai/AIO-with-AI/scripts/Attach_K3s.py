import argparse
from azureml.core.compute import KubernetesCompute, ComputeTarget, AmlCompute
from azureml.core import Workspace
from azureml.exceptions import ComputeTargetException

def attach_k3s_cluster(resourceGroupName, amlworkspaceName, arcK3sClusterId, vmUserAssignedIdentityID, subscriptionId):
    # resourceGroupName = 'aiobx-aioedgeai-rg'
    # amlworkspaceName = 'mlw-aiobx-hev'
    # arcK3sClusterId = '/subscriptions/22c140ff-ca30-4d58-9223-08a6041970ab/resourceGroups/aiobx-aioedgeai-rg/providers/Microsoft.Kubernetes/connectedClusters/aiobmcluster1'
    # vmUserAssignedIdentityID = ['subscriptions/22c140ff-ca30-4d58-9223-08a6041970ab/resourceGroups/aiobx-aioedgeai-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aiobx-hev']
    # subscriptionId = '22c140ff-ca30-4d58-9223-08a6041970ab'

    print(f"resourceGroupName '{resourceGroupName}'.")
    print(f"amlworkspaceName '{amlworkspaceName}'.")
    print(f"arcK3sClusterId '{arcK3sClusterId}'.")
    print(f"vmUserAssignedIdentityID '{vmUserAssignedIdentityID}'.")
    print(f"subscriptionId '{subscriptionId}'.")

    # Name for the compute target
    compute_target_name = "k3s-cluster"
    # Specify Kubernetes namespace to run AzureML workloads
    ns = "default" 

    # Connect to the Azure ML Workspace
    ws = Workspace(subscription_id=subscriptionId,
                          resource_group=resourceGroupName,
                          workspace_name=amlworkspaceName)

    # Check if the compute target already exists
    try:
        compute_target = ComputeTarget(workspace=ws, name=compute_target_name)
        print(f"Compute target '{compute_target_name}' already exists.")
    except ComputeTargetException:
        # Define the configuration for the Kubernetes compute target
        k8s_config = KubernetesCompute.attach_configuration(resource_id = arcK3sClusterId, namespace = ns,  identity_type ='UserAssigned',identity_ids = [vmUserAssignedIdentityID])

        # Create the Kubernetes compute target
        #compute_target = KubernetesCompute.create(ws, compute_target_name, k8s_config)
        compute_target = ComputeTarget.attach(ws, compute_target_name, k8s_config)
        compute_target.wait_for_completion(show_output=True)

        print(f"Kubernetes compute target '{compute_target_name}' created successfully.")

    print("Compute target attached to the Azure Machine Learning workspace successfully.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Attach Azure Arc Kubernetes cluster to Azure ML workspace.")
    parser.add_argument('-g', '--resourceGroupName', required=True, help="The resource group name.")
    parser.add_argument('-w', '--amlworkspaceName', required=True, help="The Azure Machine Learning workspace name.")
    parser.add_argument('-c', '--arcK3sClusterId', required=True, help="The resource ID of the Azure Arc Kubernetes cluster.")
    parser.add_argument('-u', '--vmUserAssignedIdentityID', required=True, help="The resource ID of the User Assigned Managed Identity.")
    parser.add_argument('-s', '--subscriptionId', required=True, help="The subscription ID.")

    args = parser.parse_args()

    attach_k3s_cluster(args.resourceGroupName, args.amlworkspaceName, args.arcK3sClusterId, args.vmUserAssignedIdentityID, args.subscriptionId)