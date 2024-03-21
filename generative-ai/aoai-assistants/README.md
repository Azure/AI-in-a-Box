# Assistants in-a-Box
![Banner](../../media/images/banner-assistants-in-a-box.png)

## Overview
The Assistants API enables you to create AI assistants within your own apps. These assistants have instructions and can use models, tools, and knowledge to answer user questions. The API currently offers three types of tools: Code Interpreter, Retrieval, and Function calling.

## Key Features and Benefits
- **Code Interpreter Tool:** The Code Interpreter feature of the Assistants API enables the writing and execution of Python code within a secure environment. This functionality is capable of handling various types of files, including those with different data and formatting, and can produce output files containing data and graphical representations.
- **Function Calling Tool:** The Assistants API, like the Chat Completions API, enables function calling. With function calling, you can define functions for the Assistants and it will intelligently provide the necessary functions to be called, along with their respective arguments.
- **Knowledge Retrieval:** The Assistant can enhance its knowledge by incorporating information from external sources, such as exclusive product details or documents shared by users. When a file is uploaded and given to the Assistant, OpenAI will automatically break down the documents into smaller parts, organize and store the embeddings, and utilize vector search to find relevant content that can be used to respond to user inquiries.
- **Threads:** A Thread represents a conversation. The Assistant will ensure that requests to the model fit within the maximum context window, using relevant optimization techniques such as truncation

## Use Case
Envision an all-in-one assistant aiding with finances, fetching information, and handling tasks effortlessly. The Assistants API offers developers a toolkit to enrich their apps. Key features like ***Function Calling*** enable seamless integration for tasks like messaging and device control. With ***Knowledge Retrieval***, developers can tap into vast data, ensuring accurate user responses. The API's ***Code Interpreter*** provides calculation abilities, while blending these powers crafts a versatile, assistant for diverse tasks.

## How It Works
The Assistants API operates through a straightforward flow:


![Banner](../../media/images/assistantsapi-flow-overview.svg)

1. **Assistant Creation:** Developers define an assistant with custom instructions and select a model, along with enabling specific tools like Code Interpreter, Retrieval, and Function calling.
2. **Thread Creation:** When a user initiates a conversation, a thread is created to facilitate the interaction.
3. **Message Exchange:** Users interact with the assistant by sending messages, which are added to the thread.
4. **Assistant Execution:** The assistant processes the messages within the thread, triggering relevant tools as necessary.
5. **Response Handling:** Once processing is complete, the assistant generates responses, which are then delivered back to the user via the thread.

## Samples

Check out the provided samples to get started with integrating the Assistants API into your application. The code showcases foundational concepts such as Assistants, Threads, Messages, Runs, and the Assistant lifecycle, offering a clear starting point for implementation.

| Topic | Description |
|----------------------|--------------------------------------------------|
| [Math Tutor](./api-in-a-box/math_tutor/assistant-math_tutor.ipynb) | Showcases the foundational concepts of Assistants such as Threads, Messages, Runs, Tools, and lifecycle management. |
| [Financial Assistant](./api-in-a-box/personal_finance/assistant-personal_finance.ipynb) | Function Calling with Yfinance to get latest stock prices. Summarization of user provided article. Extract country info from article, extract country, capital and other aspects, and call an API to get more information about each country. |
| [Failed Banks](./api-in-a-box/failed_banks/assistant-failed_banks.ipynb) | Failed Banks is an Assistant designed to analyze and extract data concerning failed banks. It can provide insights into questions like identifying failed banks within specific states during a given time frame and generate charts illustrating bank failures across the US. |
| [Wind Farm](./api-in-a-box/wind_farm/assistant-wind_farm.ipynb) | Utilizing Assistant tools such as the Code Interpreter and Function calling, this bot is capable of retrieving a CSV file that illustrates turbine wind speed, voltage, and the last maintenance date. It assists you in reviewing the file contents and aids in determining whether a specific turbine is in need of maintenance. |
| [Sales Assistant](./api-in-a-box/sales_assistant/assistant_sales.ipynb) | Showcases how you can create an Assistant adept at managing various tasks, such as handling relational data across different files and supporting multiple users simultaneously within the same Assistant across distinct threads. |
| [Assistants Bot-in-a-Box](./bot-in-a-box/) | The Assistants API Bot in-a-box automates virtual assistant deployment on Azure, facilitating seamless communication between users and assistants across various messaging channels. It streamlines message processing and response delivery through Azure Bot Services and the Assistants API. |

## Prerequisites
Before using the Assistants API, ensure you have:

* An [Azure subscription](https://azure.microsoft.com/en-us/free/).
* Created and deployed an [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource) Resource.
* Set up the necessary environment variables containing API credentials. (i.e. [.env]())
* Installed Python 3.7+ for running the provided sample code.