# NLP to SQL in-a-box
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
(Leverage the following article for reference as you deploy the solution: [SQL Queries with Azure Open AI and Semantic Kernel](https://techcommunity.microsoft.com/t5/analytics-on-azure-blog/revolutionizing-sql-queries-with-azure-open-ai-and-semantic/ba-p/3913513))

**Step 1.** Clone the [AI-in-a-Box repository](https://github.com/Azure/AI-in-a-Box)

**Step 2.** Create Azure Resources (User Assigned Managed Identity, SQL Server, SQL DB, Azure OpenAI and Azure AI Speech Service)

**Step 2.** Create some mock data in Azure SQL Server

**Step 3.** Create the Environment file .env

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
    cd gen-ai/nlp-sql-in-a-box
    ```

2. Deploy resources:
    ```
    azd up
    ```

    You will be prompted for a subscription, and region.


## Post Deployment
Once your resources have been deployed you will need to do the following to get the app up and running:

1. Add your client IP4 address in the Azure SQL Server Firewall rules:       
    * If you don't know how to add your IP Address to your SQL Server follow this link -> [Create a server-level firewall rule in Azure portal](https://learn.microsoft.com/en-us/azure/azure-sql/database/firewall-create-server-level-portal-quickstart)

2. Create some mock data in Azure SQL Server. 
    * Log in to the Azure SQL Server Query Editor or through SQL Server Management Studio and create a fake table
    ```
    CREATE TABLE ExplorationProduction (
        WellID INT PRIMARY KEY,
        WellName VARCHAR(50),
        Location VARCHAR(100),
        ProductionDate DATE,
        ProductionVolume DECIMAL(10, 2),
        Operator VARCHAR(50),
        FieldName VARCHAR(50),
        Reservoir VARCHAR(50),
        Depth DECIMAL(10, 2),
        APIGravity DECIMAL(5, 2),
        WaterCut DECIMAL(5, 2),
        GasOilRatio DECIMAL(10, 2)
    );
    ```
3. Create/Update config.ini within the data folder and add in your sql server/sql db information:

    ```
    [database]
    server_name = <servername>.database.windows.net
    database_name = <databasename>
    username = <username>
    password = <password>
    ```

4. Create/Update environment file, you can rename the .env-sample file to .env which is located in the root (nlp-sql-in-a-box) folder. Please fill in the details in the file in the below format:

    ```
    AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
    AZURE_OPENAI_ENDPOINT="https://YOURAOAIINSTANCE.openai.azure.com/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-07-01-preview"
    AZURE_OPENAI_API_KEY="<key>"
    SPEECH_KEY="<speech key>"
    SPEECH_REGION="eastus"
    server_name = <server name>
    database_name = <database name>
    SQLADMIN_USER = <username>
    SQL_PASSWORD = <password>
    ```

5. Log in to the Azure Open AI Studio [https://oai.azure.com](https://oai.azure.com/) and under Deployments make sure that the gpt-35-turbo version 0301 deployment is created.

6. Now lets insert in new data into the ExplorationProduction table we created above by running the create_data.py script:
    * Run the create_data.py in either a command prompt or vscode debugger.
        * If you use the vscode debugger make sure to open up the nlp-sql-in-a-box folder directly in vscode.
    * This will generate and insert 1,000 fake records. 
    * Go back Azure SQL Server Query Editor or through SQL Server Management Studio and check that the new entries were inserted.

7. Run the Final Orchestrator by running the main_app.py
    * The code in this file is a Python script that uses the Semantic Kernel to build a conversational agent that can process natural language queries and generate SQL queries to retrieve data from a database. The script uses the Azure Cognitive Services Speech SDK to recognize speech input from the user and synthesize speech output to the user.
     * Make sure you pip install any dependencies that are mentioned in the requirements.txt file.
     * Run the main_app.py in either a command prompt or vscode debugger.

8. Sample Demo
    * Here is a screenshot of a sample demo of the application. The speech is printed to show the conversation.

    ```
    Speech synthesized to speaker for text [....Welcome to the Kiosk Bot!! I am here to help you with your queries. I am still learning. So, please bear with me.]
    Speech synthesized to speaker for text [Please ask your query through the Microphone:]
    Listening:
    Processing........
    The query is: How many locations are there?
    The SQL query is: SELECT COUNT(DISTINCT Location) AS 'Number of Locations'
    FROM ExplorationProduction
    Speech synthesized to speaker for text [The result of your query is: 9985]
    Speech synthesized to speaker for text [Do you have any other query? Say Yes to Continue]
    Listening:
    Speech synthesized to speaker for text [Please ask your query through the Microphone:]
    Listening:
    Processing........
    The query is: How many wells are there were water cut is more than 95?
    The SQL query is: SELECT COUNT(*) FROM ExplorationProduction WHERE WaterCut > 95
    Speech synthesized to speaker for text [The result of your query is: 245]
    Speech synthesized to speaker for text [Do you have any other query? Say Yes to Continue]
    Listening:
    Speech synthesized to speaker for text [Thank you for using the Kiosk Bot. Have a nice day.]
    Time taken Overall(mins):  1.3298223217328389
    ```


