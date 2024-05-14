Write-Host "Loading azd .env file from current environment..."

$envValues = azd env get-values
$envValues.Split("`n") | ForEach-Object {
    $key, $value = $_.Split('=')
    $value = $value.Trim('"')
    Set-Variable -Name $key -Value $value -Scope Global
}

# Unset Directline secret on App Service instance
az webapp config appsettings set -g $AZURE_RESOURCE_GROUP_NAME -n $APP_NAME --settings DIRECT_LINE_SECRET=