. ./scripts/loadenv.sh

if [ -z $AZURE_SEARCH_NAME ]; then exit; fi

echo "Creating Azure Search Index"

AZURE_SEARCH_API_KEY=$(az search admin-key show --service-name $AZURE_SEARCH_NAME -g $AZURE_RESOURCE_GROUP_NAME --query primaryKey --output tsv)
curl -X POST "${AZURE_SEARCH_ENDPOINT}/indexes?api-version=2020-06-30" -H 'Content-type:application/json' -H "api-key: ${AZURE_SEARCH_API_KEY}" -d @scripts/hotels-sample-index.json -v
curl -X POST "${AZURE_SEARCH_ENDPOINT}/indexes/hotels-sample-index/docs/index?api-version=2020-06-30" -H 'Content-type:application/json' -H "api-key: ${AZURE_SEARCH_API_KEY}" -d @scripts/hotels-sample-data.json -v