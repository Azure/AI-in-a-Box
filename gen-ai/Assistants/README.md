# Assistants in-a-Box
![Banner](../../media/images/banner-assistants-in-a-box.png)

## Overview
The Assistants API enables you to create AI assistants within your own apps. These assistants have instructions and can use models, tools, and knowledge to answer user questions. The API currently offers three types of tools: Code Interpreter, Retrieval, and Function calling.

## Key Features and Benefits

- **Versatile Functionality:** Assistants can handle finances, retrieve information, and execute custom functions, all within a single interface.
- **Ease of Use:** Developers can interact with the Assistants API through simple conversational commands, enabling seamless integration into applications.
- **Extensible:** With ongoing updates and additions to the API, assistants can continuously expand their capabilities to perform even more tasks.
- **Customizable:** Developers can tailor assistants to specific needs by combining different tools, such as Code Interpreter, Retrieval, and Function calling.
- **Simplified Integration:** The API offers straightforward integration with clear instructions, enabling developers to quickly grasp fundamental concepts and explore advanced capabilities.

## Use Case
Imagine an assistant that helps you figure out your finances, retrieves useful info, and executes special functions—all in one go! It's like giving your app a brain that keeps getting smarter! By leveraging the Assistants API, developers can create assistants with easy-to-follow instructions that use special tools to get things done. Right now, it has three superpowers: Code Interpreter (for doing techy stuff), Retrieval (for finding info), and Function calling (for making things happen). You can even mix these powers to create a super-assistant that can handle all sorts of tasks.

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
| [Failed Banks](./api-in-a-box/failed_banks/assistant-failed_banks.ipynb) | Using Assistant tools Code Interpreter and Function calling, this bot can get a CSV file, gather a list of failed banks by state, and generate a chart to visually represent the data. |
| [Wind Farm](./api-in-a-box/wind_farm/assistant-wind_farm.ipynb) | Utilizing Assistant tools such as the Code Interpreter and Function calling, this bot is capable of retrieving a CSV file that illustrates turbine wind speed, voltage, and the last maintenance date. It assists you in reviewing the file contents and aids in determining whether a specific turbine is in need of maintenance. |
| [Assistants Bot-in-a-Box](./bot-in-a-box/) | The Assistants API Bot in-a-box automates virtual assistant deployment on Azure, facilitating seamless communication between users and assistants across various messaging channels. It streamlines message processing and response delivery through Azure Bot Services and the Assistants API. |

## Prerequisites
Before using the Assistants API, ensure you have:

* An [Azure subscription](https://azure.microsoft.com/en-us/free/).
* Created and deployed an [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource) Resource.
* Set up the necessary environment variables containing API credentials. (i.e. [.env]())
* Installed Python 3.7+ for running the provided sample code.