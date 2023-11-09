<p align="center">
  <img src="../../Assets/images/aiservices-in-a-box.svg" alt="FTA AI Services-in-a-Box: Deployment Accelerator" style="width: 15%" />
</p>

# Doc-Intelligence-in-a-Box

## Solution Architecture
Below architecture diagram illustrates the main components and information flow of this solution accelerator. For the work flow details, please refer to the page for [Architecture Description](./Deployment/Architecture_Description/README.md). 

![Architecture Diagram](./Deployment/Images/Arch-SA-PDF-Form-Processing-Automation-AAC.png "PDF Form Processing Automation Architecture Diagram")

# Azure PDF Form Processing Automation Solution Accelerator

Form processing is a critical business function across industries. Many companies are still relying on manual processes, which are costly, time-consuming, and error prone. Replacing these manual processes not only reduces a company’s cost and risk but is also an essential part of a company’s digital transformation journey. 

This solution accelerator empowers companies to automate the processing of PDF forms to modernize their operations, save time, and reduce cost.

The solution accelerator receives the PDF forms, extracts the fields from the form, and saves the data in Azure Cosmos DB. Power BI is then used to visualize the data.

The solution accelerator was designed with a modular, metadata-driven methodology. It can be utilized directly without code modification to process and visualize any single-page PDF forms such as safety forms, invoices, incident records, health screening forms, payment authorization forms, and many others.

To use the solution accelerator, you only need to collect sample PDF forms, train a new model to learn the form's layout and plug the model into the solution. The Power BI report will need to be re-designed for your specific data sets to drive insights.

**Who can leverage this solution?** Businesses have many types of single-page forms to be processed and analyzed. For example, safety forms, invoices, incident records, housing application forms, credit card application forms, job applications forms, and many others.

**Outcome of the solution**: Key data fields are extracted from many single-page PDF forms, stored in Azure Data Lake Storage and Cosmos DB. The data is visualized in dashboard pages to drive actionable insights. 

**Possible extension**: Businesses can utilize data fields stored in Azure Data Lake Storage or Azure Cosmos DB to perform further processing. For example, if safety forms are processed, the data can be used for work place safety analysis, incident analysis, and compliance reporting. If invoices are processed, the processed data can be used for invoice payment applications. 

**What are the input?** Input to this solutions are (1) single-page pdf forms or (2) multiple page pdf documents with each page as a self-contained form. In this case, the solution has a 'split pdf file' feature to split the multiple page pdf file into single-page pdf forms. 

**Limitations:** Each PDF form must fit into **a single page pdf file**. If the PDF file contains multiple pages, the system assumes that each page is a self-contained PDF form, and will split the multi-page PDF file into single pages before processing. After splitting, each split file will be only one page, containing a single form. Please review the sample files posted here to see the format: [Single Page PDF File Sample](./Deployment/Data/samples/test/contoso_set_1/ContosoSafety360-Sample-1.pdf) and [Multi Page PDF File Sample](./Deployment/Data/samples/test/contoso_set_1/ContosoSafety360-Combo-1.pdf).

**How to deploy and test the solution?**  The solution is supplied with sample manufacture safety forms, form recognizer labeled files, and a Power BI model. Please follow the step by step [Deployment Guide](./Deployment/README.md) to deploy and set up the solution to your own Azure subscription, test the solution with the test forms supplied, and then visualized the data using the Power BI model supplied. 

**Key Azure technologies** utilized in this solution are:  Azure Data Lake Storage,  Azure Form Recognizer, Azure Logic Apps, Azure Functions App, Azure Cosmos DB, and Power BI.  **The Azure Form Recognizer** is a cloud-based Azure Applied AI service that uses machine learning models to extract and analyze fields, text, and tables from documents or images. **Azure Logic App** is a cloud-based platform for creating and running automated end-to-end workflows. **Azure Functions App** provides low-cost, custom application logic development and data processing capabilities to help businesses solve complex problems with ease of design, development, deployment, and maintenance. **Azure Cosmos DB** is a fully managed, serverless NoSQL database for high-performance applications of any size or scale. 

![Process flow](./Deployment/Images/Process-Flow.png "Process flow")

## Prerequisites

To use this solution accelerator, you will need access to an [Azure subscription](https://azure.microsoft.com/en-us/free/). An understanding of Azure Form Recognizer, Azure Form Recognizer Studio, Azure Logic Apps, Azure Functions, Azure Cosmos DB, and Power BI will be helpful. 

For additional training and support, please review:

1. [Azure Form Recognizer](https://azure.microsoft.com/en-us/services/form-recognizer/)
2. [Azure Logic Apps](https://azure.microsoft.com/en-us/services/logic-apps/#overview)
3. [Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-overview)
4. [Azure Data Lake Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
5. [Azure Cosmos DB](https://azure.microsoft.com/en-us/services/cosmos-db/)
6. [Power BI](https://docs.microsoft.com/en-us/power-bi/fundamentals/power-bi-overview)


## Getting Started
Get started by deploying the solution accelerator to a specified resource group in your own subscription. Go to the [Deployment Guide](./Deployment/README.md) to set up your Azure environment, create necessary Azure resources, and test the solution. 

## Power BI Dashboard

Below Power BI dashboard illustrates overview of sample safety form processing results, showing the number of occurrences by selected categories. The category is the field key defined by the Azure Form Recognizer labeling tool.  

![PBI w Text Search](./Deployment/Images/PBI-Overview.png)

In addition, you can have a quick overview of the safety forms categorized by important fields such as Department, Owner, Date created. From these charts, you can recognize patterns and trends, as illustrated below. 

![PBI w Summary](./Deployment/Images/PBI-Metrics.png)