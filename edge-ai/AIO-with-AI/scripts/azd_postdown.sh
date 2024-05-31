#!/bin/sh
# Loading the .env file from the current environment and deleting the service principal
echo "Loading azd .env file from current environment..."
while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

# Delete the service principal
az ad sp delete --id "$AZURE_ENV_SPAPPID"