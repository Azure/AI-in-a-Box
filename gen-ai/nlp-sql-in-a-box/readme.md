# AI Edge in-a-box
![Banner](./readme_assets/banner-nlp-to-sql-in-a-box.png)

## Use Case
Build a cutting-edge speech-enabled SQL query system using Azure Open AI, Semantic Kernel, and Azure AI Speech Service

We will use the power of Azure Open AI and Semantic Kernel to translate your natural language queries into SQL statements that can be executed against an SQL Server database. This will allow you to interact with your data in a more intuitive and user-friendly way. No more struggling with complex SQL syntax – just speak your query and let the system do the rest!

And with Azure Speech Services, we will convert your speech into text and synthesize the results as speech. This means that you can hear the results of your query spoken back to you, making it easier to understand and digest the information.

## Solution Architecture
<img src="./readme_assets/nlp-to-sql-architecture.png" />

### The above architecture is explained step-by-step below:
1. A user speaks a natural language query into a microphone.
1. The natural language query is captured as text.
1. The text is sent to the Azure Speech to Text Service, which converts the speech into text.
1. The text is then processed by an NLP system, which converts the natural language query into an SQL query.
1. The SQL query is used to fetch data from an SQL server.
1. The data from the SQL server is returned as a result.
1. The result is sent to the Azure Text to Speech Service, which converts the text into speech.
1. The output is then played back to the user as speech.

## Prerequisites
* Read the following Blog: [Revolutionizing SQL Queries with Azure Open AI and Semantic Kernel](https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/revolutionizing-sql-queries-with-azure-open-ai-and-semantic/ba-p/3913513)
* An [Azure subscription](https://azure.microsoft.com/en-us/free/).
* Install latest version of [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest)
* Install [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
* Install latest version of [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
* Install [ODBC Driver for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server) 

## Deployment Flow 
(Leverage the following article for reference: [SQL Queries with Azure Open AI and Semantic Kernel](https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/revolutionizing-sql-queries-with-azure-open-ai-and-semantic/ba-p/3913513))

**Step 1.** Clone the [AI-in-a-Box repository](https://github.com/Azure/AI-in-a-Box)

**Step 2.** Create Azure Resources (User Assigned Managed Identity, SQL Server, SQL DB, Azure OpenAI and Azure AI Speech Service)

**Step 2.** Create some fake data in Azure SQL Server

**Step 3.** Create the Enviornment file .env

**Step 4.** Analyze the Plugin Code (STTPlugin, TTSPlugin, nlpToSqlPlugin)

**Step 5.** Analyze the main_app.py (this file Orchestrates everything)

**Step 6.** Run

## Deploy to Azure

1. Log into your Azure subscription: 
    ```
    azd auth login
    ```

1. Clone this repository locally: 

    ```
    git clone https://github.com/Azure/AI-in-a-Box
    cd nlp-sql-in-a-box
    ```

2. Deploy resources:
    ```
    azd up
    ```

    You will be prompted for a subcription, and region.


## Post Deployment
* Once the VM is deployed or your physical device is setup you can ssh into the VM/device using the below command   
    * ssh NodeVMAdmin@edgevm1.eastus.cloudapp.azure.com -p 2222 
* Once connected to your virtual machine, [verify](https://learn.microsoft.com/en-us/azure/iot-edge/quickstart-linux) that the runtime was successfully installed and configured on your IoT Edge device.
    * sudo iotedge system status
    * sudo iotedge list
    * sudo iotedge check