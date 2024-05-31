# Loading the .env file from the current environment and deleting the service principal
Write-Host "Loading azd .env file from current environment"
foreach ($line in (& azd env get-values)) {
    if ($line -match "([^=]+)=(.*)") {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$'
	    [Environment]::SetEnvironmentVariable($key, $value)
    }
}
# Output the azd env get-values
azd env get-values

# Delete the service principal
Write-Host "Deleting the service principal with id $env:AZURE_ENV_SPAPPID"
az ad sp delete --id $env:AZURE_ENV_SPAPPID
