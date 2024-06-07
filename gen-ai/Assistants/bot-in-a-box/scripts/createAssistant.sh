set -e

echo "Loading azd .env file from current environment..."

while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
    export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

AOAI_API_KEY=$(az cognitiveservices account keys list -n $AOAI_NAME -g $AZURE_RESOURCE_GROUP_NAME | jq -r .key1)
AOAI_ASSISTANT_NAME="assistant_in_a_box"
ASSISTANT_ID=$(curl "$AOAI_API_ENDPOINT/openai/assistants?api-version=2024-02-15-preview" \
  -H "api-key: $AOAI_API_KEY"|\
  jq -r '[.data[] | select( .name == "'$AOAI_ASSISTANT_NAME'")][0] | .id') 
if [ "$ASSISTANT_ID" == "null" ]; then    
    ASSISTANT_ID=
else
    ASSISTANT_ID=/$ASSISTANT_ID
fi   

echo '{
    "name":"'$AOAI_ASSISTANT_NAME'",
    "model":"gpt-4",
    "instructions":"",
    "tools":[
        '$(for each in ./src/Tools/*.json; do cat $each; echo ","; done)'
        {}
    ],
    "file_ids":[],
    "metadata":{}
  }' > tmp.json
curl "$AOAI_API_ENDPOINT/openai/assistants$ASSISTANT_ID?api-version=2024-02-15-preview" \
  -H "api-key: $AOAI_API_KEY" \
  -H 'content-type: application/json' \
  -d @tmp.json \
  --fail-with-body
rm tmp.json

ASSISTANT_ID=$(curl "$AOAI_API_ENDPOINT/openai/assistants?api-version=2024-02-15-preview" \
  -H "api-key: $AOAI_API_KEY"|\
  jq -r '[.data[] | select( .name == "'$AOAI_ASSISTANT_NAME'")][0] | .id')

az webapp config appsettings set -g $AZURE_RESOURCE_GROUP_NAME -n $APP_NAME --settings AOAI_ASSISTANT_ID=$ASSISTANT_ID APP_URL=$APP_HOSTNAME