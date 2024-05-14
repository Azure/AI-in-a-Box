set -e

echo "Loading azd .env file from current environment..."

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF


# Find the secret for the direct line channel
SECRET=$(az bot directline show --name $BOT_NAME --resource-group $AZURE_RESOURCE_GROUP_NAME --with-secrets --query "properties.properties.sites[0].key" -o tsv)

# Set on App Service instance
az webapp config appsettings set -g $AZURE_RESOURCE_GROUP_NAME -n $APP_NAME --settings DIRECT_LINE_SECRET=$SECRET
