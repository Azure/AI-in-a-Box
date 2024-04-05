$spid = az ad signed-in-user show --query id --output tsv
azd env set AZURE_SP_OBJECT_ID $spid 
