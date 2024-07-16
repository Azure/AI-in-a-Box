#!/bin/bash

# Needed to disable auto translation of resource ids
# https://github.com/Azure/azure-cli/issues/16317#issuecomment-768755622
export MSYS_NO_PATHCONV=1

# Function to remove non-printable and control characters from a string
function safe_string() {
  # Remove non-ASCII characters (including control codes)
  cleaned_string=$(echo "$1" | tr -cd '[:print:][:cntrl:]')

  echo "$cleaned_string"
}

print_usage() {
    printf "Usage: $0 [-g resource_group] [-w workspace]\n"
}

resource_group=""
workspace_name=""

while getopts "g:w:" flag; do
    case "$flag" in
        g) resource_group="$OPTARG" ;;
        w) workspace_name="$OPTARG" ;;
        *) print_usage; exit 1 ;;
    esac
done

if [[ -z "$resource_group" ]]; then
  echo "no resource group provided."
  print_usage; exit 1;
fi

if [[ -z "$workspace_name" ]]; then
  echo "no workspace provided."
  print_usage; exit 1;
fi

# set the default resource group to be used in this script
echo "Setting default resource group to $resource_group and workspace to $workspace_name"
az configure --defaults group="$resource_group" workspace="$workspace_name"

# gets the storage account path associated with the workspace
echo "Enforcing identity datastore auth mode and fetching storage account path associated with the workspace $workspace_name"
storage_path=$(az ml workspace update --system-datastores-auth-mode identity -o tsv --query "storage_account")

# creates a role assignment for the workspace
echo "Assigning Storage Blob Data Contributor role to the workspace $workspace_name with principal id $principal_id and scope $storage_path"
assigned_role=$(az role assignment create --assignee "$principal_id" --role "Storage Blob Data Contributor" --scope "$storage_path" -o tsv --query "name")
echo "Role assignment created with name $assigned_role"

# list all the compute targets in the workspace and apply the role assignment
echo "Listing all the compute targets in the workspace $workspace_name"
compute_targets=$(az ml compute list -o tsv --query '[].name')

# Loop over each compute target
while IFS= read -r line; do
  compute_name=$(safe_string "$line")

  echo "Setting system assigned identity for compute target $compute_name"
  principal_id=$(az ml compute update --name "$compute_name" --identity-type SystemAssigned -o tsv --query "identity.principal_id")

  # creates a role assignment for the compute target
  echo "Assigning Storage Blob Data Contributor role to the compute target $compute_name with principal id $principal_id and scope $storage_path"
  assigned_role=$(az role assignment create --assignee "$principal_id" --role "Storage Blob Data Contributor" --scope "$storage_path" -o tsv --query "name")
  echo "Role assignment created with name $assigned_role"
done <<< "$compute_targets"

# list all online endpoints in the workspace and apply the role assignment
echo "Listing all the online endpoints in the workspace $workspace_name"
online_endpoints=$(az ml online-endpoint list -o tsv --query '[].name')

# Loop over each online endpoint
while IFS= read -r line; do
  online_endpoint_name=$(safe_string "$line")

  echo "Setting system assigned identity and Entra token-based authentication for online endpoint $online_endpoint_name"
  principal_id=$(az ml online-endpoint update --name "$online_endpoint_name" --set authMode=AADToken identity.type=SystemAssigned -o tsv --query "identity.principal_id")

  # creates a role assignment for the online endpoint
  echo "Assigning Storage Blob Data Contributor role to the online endpoint $online_endpoint_name with principal id $principal_id and scope $storage_path"
  assigned_role=$(az role assignment create --assignee "$principal_id" --role "Storage Blob Data Contributor" --scope "$storage_path" -o tsv --query "name")
  echo "Role assignment created with name $assigned_role"
done <<< "$online_endpoints"

## extracts the storage account name from the path
echo "Extracting storage account name from the path $storage_path"
storage_name="${storage_path##*/}"

# disable shared key access in the storage account
echo "Disabling shared key access in the storage account $storage_name"
allow_shared_key_access=$(az storage account update -n "$storage_name" --allow-shared-key-access false -o tsv --query "allowSharedKeyAccess")

echo "Completed setting up workspace to enforce EntraID"
