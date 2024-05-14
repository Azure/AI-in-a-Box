set -e

echo "Loading azd .env file from current environment..."

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

# Delete the app registration
APP_ID=$(az ad app list --display-name $APP_NAME --query '[].id | [0]' -o tsv)
az ad app delete --id $APP_ID

# Remove SSO configuration from your bot
az bot authsetting delete --resource-group $AZURE_RESOURCE_GROUP_NAME --name $BOT_NAME --setting-name default

# Remove SSO configuration from the app.
az webapp config appsettings set -g $AZURE_RESOURCE_GROUP_NAME -n $APP_NAME --settings SSO_ENABLED=false SSO_CONFIG_NAME=