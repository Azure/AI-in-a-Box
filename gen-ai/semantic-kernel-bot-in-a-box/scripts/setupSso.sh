set -e

echo "Loading azd .env file from current environment..."

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

# Create an App Registration and retrieve its ID and Client ID.
APP=$(az ad app create --display-name $APP_NAME --web-redirect-uris https://token.botframework.com/.auth/web/redirect)
APP_ID=$(echo $APP | jq -r .id)
CLIENT_ID=$(echo $APP | jq -r .appId)

# Create a client secret for the newly created app
SECRET=$(az ad app credential reset --id $APP_ID)
CLIENT_SECRET=$(echo $SECRET | jq -r .password)

# Create an SSO configuration for your bot, passing in the App Registration details
az bot authsetting create --resource-group $AZURE_RESOURCE_GROUP_NAME --name $BOT_NAME --setting-name default --client-id $CLIENT_ID --client-secret $CLIENT_SECRET --parameters TenantId=$AZURE_TENANT_ID --service aadv2 --provider-scope-string User.Read

# Configure the App Service to use the SSO configuration.
az webapp config appsettings set -g $AZURE_RESOURCE_GROUP_NAME -n $APP_NAME --settings SSO_ENABLED=true SSO_CONFIG_NAME=default