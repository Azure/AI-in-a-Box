#!/bin/bash

# Get the signed-in user's ID
spid=$(az ad signed-in-user show --query id --output tsv)

# Set the environment variable AZURE_SP_OBJECT_ID
export AZURE_SP_OBJECT_ID="$spid"


