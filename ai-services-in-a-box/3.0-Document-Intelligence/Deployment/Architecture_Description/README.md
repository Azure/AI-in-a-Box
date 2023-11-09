# Architecture Description  
Below architecture diagram illustrates the main components and information flow of this solution accelerator. 

## ![Architecture Diagram](../Images/Arch-SA-PDF-Form-Processing-Automation-AAC.png "PDF Form Processing Automation Architecture Diagram")

## Architecture Workflow 

The workflow corresponding to the above architecture is described as below: 

1. Receiving and processing PDF forms received from an  outlook email account. This is an optional feature that can be omitted if not necessary. 

- [ ] 1a. Designated outlook email account receives PDF files as Attachments, which triggers the email processing logic app to start processing. This is a designated and dedicated email account that receives PDF forms as attachments. It will be good practice to limit the senders to only trusted parties and avoid malicious actors from spamming outlook email account.
- [ ] 1b. The email processing logic app extracts and uploads the PDF Attachments to a specified container in Azure Data Lake Storage, for example, `files-1-input`. This container name is configurable from the deployment scripts published in the GitHub Repository.

2. PDF forms are manually or programmatically uploaded to the `files-1-input` container in Azure Data Lake Storage.
3. Whenever PDF forms are uploaded to the specified azure storage `files-1-input` container, it will trigger the form processing logic app to start processing the PDF forms. 
4. The form processing logic app sends the location of the received PDF file to Azure Functions App for processing. 
5. Azure Functions App receives the location of file, and triggers multiple events:

```
(A) The Functions App splits the file into single pages if the file has multiple pages, with each page containing one independent form. Split files are saved to Azure Data Lake Storage, in the container `files-2-split`. 

(B) Via REST API (HTTPS POST), the Azure Functions app sends the location of the single page PDF file to Azure Form Recognizer for processing and receives response. The functions app prepares the response into desired data structure. 

(C) Azure Functions App saves the structured data as JSON file to Azure Data Lake Storage, in the container, `file-3-recognized`. 
```

6. The form processing logic app receives the processed response data. 

7. The form processing logic app sends the processed data to Azure Cosmos DB. Azure Cosmos DB saves the data into specified database and collections.

8. Power BI is connected to Azure Cosmos DB to receive data and provide insights/dashboards.
