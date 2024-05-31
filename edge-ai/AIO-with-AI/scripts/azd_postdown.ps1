# Loading the .env file from the current environment and deleting the service principal
Write-Host "Loading azd .env file from current environment"
foreach ($line in (& azd env get-values)) {
    if ($line -match "([^=]+)=(.*)") {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$'
	    [Environment]::SetEnvironmentVariable($key, $value)
    }
}
# Delete the service principal
az ad sp delete --id $env:AZURE_ENV_SPAPPID
