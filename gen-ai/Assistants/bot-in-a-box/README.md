# Assistants API Bot in-a-Box
![Banner](./readme_assets/banner-assistants-api-bot-in-a-box.png)

### Overview

This tutorial provides a step-by-step guide on how to deploy a virtual assistant leveraging the Azure OpenAI Assistants API. It covers the infrastructure deployment, configuration on the AI Studio and Azure Portal, and end-to-end testing examples.

### Objective

The main objective of this tutorial is to help users understand how to leverage the Assistants API to create a fully-fledged virtual assistant application.
By the end of this tutorial, you should be able to:

 - Deploy the necessary infrastructure to support an Azure OpenAI Assistant
 - Configure as Assistant with the required tools
 - Connect a Bot Framework application to your Assistant to deploy the chat to multiple channels

### Programming Languages
 - C#

### Estimated Runtime: 30 mins

### Solution Architecture

The solution architecture is described in the diagram below.

![Solution Architecture](./readme_assets/architecture.png)

The flow of messages is as follows:

- End-users connect to a messaging channel your bot is publised to, such as Web, a PowerBI dashboard or Teams;
- Messages get processed through Azure Bot Services, which communicates with a .NET application running on App Services.
- The .NET application connects to the Assistants API, creates a new thread for each conversation.
- Every time a new message comes through, it is added to the thread, and an Assistant is executed on the thread to respond.
- The .NET application waits for the Assistant to conclude processing, while providing progress updates to the user.
- Once the Assistant completes work, its response is posted to the user.

### Pre-requisites

- For running locally:
    - [Install .NET](https://dotnet.microsoft.com/en-us/download);
    - [Install Bot Framework Emulator](https://github.com/Microsoft/BotFramework-Emulator);

- For deploying to Azure:
    - Install Azure CLI
    - Install Azure Developer CLI
    - Log into your Azure subscription

    ```
    azd auth login
    ```

### Deploy to Azure

1. Clone this repository locally: 

```
git clone https://github.com/Azure/AI-in-a-Box
cd gen-ai/Assistants/bot-in-a-box
```
2. Deploy resources:
```
azd up
```
You will be prompted for a subcription, region and model information. Keep regional model availability when proceeding.

3. Go to the Azure OpenAI Studio and create an Assistant with the tools you want to use. Alternatively, you can also use the API.

> Important: currently, this application only supports Code Interpreter. Other tools will be implemented in the near future.

![Assistant Creation](./readme_assets/assistant-creation.png)

4. Add your newly created Assistant's ID in the AOAI_ASSISTANT_ID environment variable.

![Add Assistant ID to environment](./readme_assets/assistant-id-variable.png)

5. Test on Web Chat - go to your Azure Bot resource on the Azure portal and look for the Web Chat feature on the left side menu.

![Test Web Chat](./readme_assets/assistant-test.png)

### Running Locally (must deploy resources to Azure first)

After running the deployment template, you may also run the application locally for development and debugging.

- Make sure you have the appropriate permissions and are logged in the Azure CLI. The `AI Developer` role at the resource group level is recommended.
- Go to the `src` directory and look for the `appsettings.example.json` file. Rename it to `appsettings.json` and fill out the required service endpoints and configurations
- Execute the project:
```
    dotnet run
```
- Open Bot Framework Emulator and connect to http://localhost:3987/api/messages
- Don't forget to enable firewall access to any services where it may be restricted. By default, SQL Server will disable public connections.

### Keywords

- Send "clear" to delete the current thread;
- Send "logout" to sign out when SSO is enabled;

### Enabling Web Chat

To deploy a Web Chat version of your app:

- Go to your Azure Bot Resource;
- Go to Channels;
- Click on Direct Line;
- Obtain a Direct Line Secret;
- Add the secret to your App Service's environment variables, under the key DIRECT_LINE_SECRET;
- Your bot will be available at https://APP_NAME.azurewebsites.net.

Please note that doing so will make your bot public, unless you implement authentication / SSO.