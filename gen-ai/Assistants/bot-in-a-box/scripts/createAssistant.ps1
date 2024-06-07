$ErrorActionPreference="Stop"


Write-Host "Loading azd .env file from current environment"
foreach ($line in (& azd env get-values)) {
    if ($line -match "([^=]+)=(.*)") {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$'
	    [Environment]::SetEnvironmentVariable($key, $value)
    }
}

$AOAI_API_KEY=az cognitiveservices account keys list -n $env:AOAI_NAME -g $env:AZURE_RESOURCE_GROUP_NAME --query key1 -o tsv
$AOAI_ASSISTANT_NAME="assistant_in_a_box"
$ASSISTANT_ID=((curl "${env:AOAI_API_ENDPOINT}openai/assistants`?api-version=2024-02-15-preview" -H "api-key: $AOAI_API_KEY" | ConvertFrom-Json).data | Where-Object name -eq $AOAI_ASSISTANT_NAME).id

if ( $ASSISTANT_ID -eq $null )    
    {
        $ASSISTANT_ID=""
        echo "empty"
    }
else
    {
        $ASSISTANT_ID="/$ASSISTANT_ID"
        echo "not empty"
    }

$TOOLS=""
Get-ChildItem "./src/Tools" -Filter *.json | 
          Foreach-Object {
              $content = Get-Content $_.FullName
              if ($TOOLS -eq "") {
                  $TOOLS = $content
              } else {
                  $TOOLS = "$TOOLS,$content"
              }
          }

echo "{
    `"name`":`"${AOAI_ASSISTANT_NAME}`",
    `"model`":`"gpt-4`",
    `"instructions`":`"`",
    `"tools`":[
        $TOOLS
    ],
    `"file_ids`":[],
    `"metadata`":{}
  }" | Out-File tmp.json
curl "${env:AOAI_API_ENDPOINT}openai/assistants$ASSISTANT_ID`?api-version=2024-02-15-preview" -H "api-key: $AOAI_API_KEY" -H 'content-type: application/json' -d '@tmp.json'

rm tmp.json

$ASSISTANT_ID=((curl "${env:AOAI_API_ENDPOINT}openai/assistants`?api-version=2024-02-15-preview" -H "api-key: $AOAI_API_KEY" | ConvertFrom-Json).data | Where-Object name -eq $AOAI_ASSISTANT_NAME).id
if ( $ASSISTANT_ID -eq $null )    
    {
        throw "Failed to create assistant"
    }
else
    {
        echo "Assistant created/updated successfully"
    }

az webapp config appsettings set -g $env:AZURE_RESOURCE_GROUP_NAME -n $env:APP_NAME --settings AOAI_ASSISTANT_ID=$ASSISTANT_ID APP_URL=$env:APP_HOSTNAME