# MLOps in-a-box
![Banner](./readme_assets/banner-mlops-in-a-box.png)

## Use Case
 End-to-end operationalization of ML model through Azure ML and GitHub actions leveraging Azure ML CLI V2

## Solution Architecture
<img src="./readme_assets/mlops_simplified.jpg" />

## Pre-requisites
1. Access to a GitHub Repo (You'll need to create a GitHub repo with the necessary artifacts)
1. Ensure **Microsoft.MachineLearningServices** Resource Provider is registered within Azure  
[Register a Resource Provider](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
1. Ensure you have a have a high enough user with enough access to deploy Azure resources (Contributor or Owner).
1. Clone repository / copy files locally
1. Start working your way through the [setup instructions](./documentation/00-set-up.md)  here >> [Set-up](./documentation/00-set-up.md)

## Steps to make GitHub Actions to work

### Azure Authentication
The GitHub Actions are using some actions that requires Azure Authentication. It's required to generate a Service Principal and save the credentias as a secret in GitHub repository settings or setup GitHub OIDC authentication. **It's always recommended to use GitHub OIDC**.

Here is the steps using Azure Service Principals and saving them as [secrets](https://help.github.com/en/articles/virtual-environments-for-github-actions#creating-and-using-secrets-encrypted-variables) in the GitHub repository and then use them in the workflow.


Follow the steps to configure Azure Service Principal with a secret:
  * Define a new secret under your repository settings, Add secret menu
  * Store the output of the below [az cli](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) command as the value of secret variable, for example 'AZURE_CREDENTIALS'
```bash

   az ad sp create-for-rbac --name "myApp" --role contributor \
                            --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
                            --sdk-auth

  # Replace {subscription-id}, {resource-group} with the subscription, resource group details

  # The command should output a JSON object similar to this:


  {
    "clientId": "<GUID>",
    "clientSecret": "<STRING>",
    "subscriptionId": "<GUID>",
    "tenantId": "<GUID>",
    "resourceManagerEndpointUrl": "<URL>"
    (...)
  }

```

For GitHub OIDC follow the steps documented in the reference bellow:

Reference: [Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)

## GitHub Personal Access Token configuration
The provided GitHub Actions require an invocation of a GitHub Action "Deploy Model to a target - 03-deploy-model.yml" after the AzureML training job has successfully finished. It's required to setup a GitHub Personal Access Token and save it as a secret inside of the GitHub repository for Azure Function be able to authenticate and invoke the GitHub Action.

Use the following reference to create you GitHub Personal Access token: (Managing your personal access tokens)[https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens]. You can chose to use a Fine-grained tokens, you must give the following permissions to GitHub repository:
- Read access to metadata
- Read and Write access to actions, code, repository hooks, and workflows

After you have created the GitHub Personal Access Token you must create a [secrets](https://help.github.com/en/articles/virtual-environments-for-github-actions#creating-and-using-secrets-encrypted-variables) in the GitHub repository and then use them in the workflow. The name must be **gitHubPAT**.

## GitHub Actions replacements
It's required to change the specifics of your environment in the GitHub Actions we are providing.
Here is where you have to look to replace:

- Update the main.parameters.json with all the specifics of your environment.
