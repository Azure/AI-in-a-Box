using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Write-Output "Print Request Body:"
# Write-Output $Request.Body

Write-Output "Print Request Json:"
Write-Output ($Request.Body | ConvertTo-Json -Depth 100)

# Interact with query parameters or the body of the request.
if ($Request.Body.Data.status -eq "Activated") {
  Write-Output "The Azure ML Alert is Activated, invoking the GitHub Action Workflow Dispatch API"

  # The GitHub URL must be in the format of:
  # "https://api.github.com/repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches"
  # You can use the github cli command: "gh workflow list" to get the workflow_id
  # Example:
  # "https://api.github.com/repos/Welasco/test/actions/workflows/74415295/dispatches"
  $gitHub_repoOwnerName = $Env:gitHub_repoOwnerName
  $gitHub_repoName = $Env:gitHub_repoName
  $gitHub_workflowId = $Env:gitHub_workflowId
  $gitHub_Api_Url = "https://api.github.com/repos/$gitHub_repoOwnerName/$gitHub_repoName/actions/workflows/$gitHub_workflowId/dispatches"
  $gitHub_PAT = $Env:gitHub_PAT

  $gitHub_Api_Headers = @{
    'Accept'               = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'Authorization'        = "Bearer $gitHub_PAT"
  }

  if ([string]::IsNullOrEmpty($gitHub_repoOwnerName) -or [string]::IsNullOrEmpty($gitHub_repoName) -or [string]::IsNullOrEmpty($gitHub_workflowId) -or [string]::IsNullOrEmpty($gitHub_PAT)) {
    $msg="The GitHub gitHub_repoOwnerName, gitHub_repoName, gitHub_workflowId, and gitHub_PAT must be set in the Function App Settings as Environment Variables"
    Write-Error $msg
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
      StatusCode = [HttpStatusCode]::BadRequest
      Body       = $msg
    })
    return
  }

  # All Inputs are required in the Function App Settings as Environment Variables
  $gitHub_Api_Body = @{
    ref    = 'main'
    inputs = @{
      resource_group = $Env:resource_group
      aml_workspace = $Env:aml_workspace
      aml_flow_deployment_name  = $Env:aml_flow_deployment_name
      aml_endpoint_name = $Env:aml_endpoint_name
      aml_model_name = $Env:aml_model_name
    }
  }

  if ([string]::IsNullOrEmpty($gitHub_Api_Body.inputs.resource_group) -or [string]::IsNullOrEmpty($gitHub_Api_Body.inputs.aml_workspace)) {
    $msg = "The Azure ML entires like resource_group, aml_workspace, aml_flow_deployment_name, aml_endpoint_name, aml_model_name must be set in the Function App Settings as Environment Variables"
    Write-Error $msg
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
      StatusCode = [HttpStatusCode]::BadRequest
      Body       = $msg
    })
    return
  }

  $emptylist=@()
  $gitHub_Api_Body.inputs.GetEnumerator() | ForEach-Object{
    if([string]::IsNullOrEmpty($_.Value)){
      $emptylist+=$_.Key
    }
  }

  $emptylist | ForEach-Object{
    $gitHub_Api_Body.inputs.Remove($_)
  }

  $gitHub_Api_Json_Body = $gitHub_Api_Body | ConvertTo-Json -Depth 100

  try{
    Invoke-RestMethod -Method Post -Uri $gitHub_Api_Url -Headers $gitHub_Api_Headers -Body $gitHub_Api_Json_Body
  }
  catch{
    $msg = $_.Exception.Response | ConvertTo-Json
    Write-Error $msg
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
      StatusCode = [HttpStatusCode]::BadRequest
      Body       = $msg
    })
    return
  }
}
else {
  Write-Output "Ignoring the Azure ML Alert, the status is not Activated"
}



$body = @'
{"Status": "OK"}
'@

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $body
})
