./scripts/loadenv.ps1

if (-not $env:AZURE_SEARCH_NAME) {
    Exit 0
    echo "No search service - skipping index"
}

echo "Creating Azure Search Index"
$AZURE_SEARCH_API_KEY = az search admin-key show --service-name $env:AZURE_SEARCH_NAME -g $env:AZURE_RESOURCE_GROUP_NAME --query primaryKey --output tsv
curl -X POST "${env:AZURE_SEARCH_ENDPOINT}/indexes?api-version=2020-06-30" -H 'Content-type:application/json' -H "api-key: ${AZURE_SEARCH_API_KEY}" -d @scripts/hotels-sample-index.json -v
curl -X POST "${env:AZURE_SEARCH_ENDPOINT}/indexes/hotels-sample-index/docs/index?api-version=2020-06-30" -H 'Content-type:application/json' -H "api-key: ${AZURE_SEARCH_API_KEY}" -d @scripts/hotels-sample-data.json -v
