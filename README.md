# AI-in-a-Box

<p align="center">
  <img src="media/images/ai-in-a-box.png" alt="FTA AI-in-a-Box: Deployment Accelerator" style="width: 15%" />
</p>

Embarking on an Azure AI/ML journey can appear challenging for certain organizations and engineers, often leading to roadblocks in their initial scenarios. To address this challenge, providing a user-friendly and intuitive template becomes crucial.  Such a template should serve as a guiding example, illustrating the complete AI/ML/LLM lifecycle, showcasing the integration of MLOps practices, detailing the setup of training pipelines, offering insights into the processes of model training, deployment, access control, and integration with other services. This ensures a smoother and more comprehensible transition into the world of Azure AI and ML.

<i>AI-in-a-Box</i> aims to provide an "Azure AI/ML <i>Easy Button</i>" for common scenarios within Azure ML, Edge AI, Cog Services and Azure OpenAI. Something that shows you how the pieces fit together in easy to deploy templates. Using the **patterns** available here, engineers will be able to quickly setup an Azure ML/AI Edge/Cog Services and/or Azure Open AI environment which optionally includes data ingestion, model training and creation, scaling patterns and edge deployments. So, if you’re seeking to shed some light into the realm of Azure ML/AI and Open AI, you’ve come to the right spot.

<p align="center">
  <img src="media/images/aibxtable.png" alt="FTA AI-in-a-Box: Deployment Accelerator" />
</p>

## Available Guidance

|Topic|Description|
|---|---|
|[Responsible AI](./responsible-ai/) | This provides essential guidance on the responsible use of AI and LLM technologies. | 
|[Security for Generative AI Applications](./gen-ai/genai-security/)| This document provides specific security guidance for Generative AI (GenAI) applications. |

## Available Patterns

|Category|Pattern|Description|Supported Use Cases and Features|
|---|---|---|---|
| ML-in-a-Box |[Azure ML Operationalization in-a-box](./machine-learning/ml-ops-in-a-box)|Boilerplate Data Science project from model development to deployment and monitoring|<li>End-to-end MLOps project template <li>Outer Loop (infrastructure setup) <br> <li>Inner Loop (model creation and deployment lifecycle)|
| EdgeAI-in-a-Box |[Edge AI in-a-box](./edge-ai/)|Edge AI from model creation to deployment on Edge Device(s) |<li>Create a model and deploy to Edge Device <li>Outer Loop Infrastructure Setup (IoT Hub, IoT Edge, Edge VM, Container Registry, Azure ML) <br> <li>Inner Loop (model creation and deployment)|
| AI Services-in-a-Box |[Doc Intelligence in-a-box](./ai-services/doc-intelligence-in-a-box) | This accelerator enables companies to automate PDF form processing, modernize operations, save time, and cut costs as part of their digital transformation journey. |<li>Receive PDF Forms<br> <li>Function App and Logic App for Orchestration<br> <li>Document Intelligence Model creation for form processing and content extraction <br> <li> Saves PDF data in Azure Cosmos DB |
| AI Services-in-a-Box |[Video Analysis-Azure Open AI in-a-box](./ai-services/gpt-video-analysis-in-a-box/) | Extracts information about videos by ingesting them into an Azure Computer Vision Video Retrieval index and sending the index to Azure GPT-4 Turbo with Vision along with the prompt and system message. |<li>Orchestration through Azure Data Factory<br> <li>Low code solution, easily extensible for your own use cases through ADF parameters<br> <li> Reuse same solution and deployed resources for many different scenarios<br> <li> Saves GPT4-V results to Azure CosmosDB|
| AOAI-in-a-Box |[Cognitive Services Landing Zone in-a-box](./ai-services/ai-landing-zone)|Minimal enterprise-ready networking and AI Services setup to support most Cognitive Services scenarios in a secure environment|<li>Hub-and-Spoke Vnet setup and peering <br> <li>Cognitive Service deployment <br> <li>Private Endpoint setup <br> <li>Private DNS integration with PaaS DNS resolver|
| AOAI-in-a-Box |[Semantic Kernel Bot in-a-box](./gen-ai/semantic-kernel-bot-in-a-box)|Extendable solution accelerator for advanced Azure OpenAI Bots|<li>Deploy Azure OpenAI bot to multiple channels (Web, Teams, Slack, etc) <br> <li>Built-in Retrieval-Augmented Generation (RAG) support <br> <li>Implement custom AI Plugins|
| AOAI-in-a-Box |[NLP to SQL in-a-box](./gen-ai/nlp-sql-in-a-box)|Unleash the power of a cutting-edge speech-enabled SQL query system with Azure Open AI, Semantic Kernel, and Azure Speech Services. Simply speak your data requests in natural language, and let the magic happen.|<li>Allows users to verbally express natural language queries <br> <li>Translate into SQL statements using Azure Speech & AOAI <br> <li> Execute  on an Azure SQL DB |
| AOAI-in-a-Box |[Assistants API in-a-box](./gen-ai/Assistants/api-in-a-box)|Harnessing the simplicity of the Assistants API, developers can seamlessly integrate assistants with diverse functionalities, from executing code to retrieving data, empowering users with versatile and dynamic digital assistants tailored to their needs.| <li>Offers three main capabilities: Code Interpreter (tech tasks), Retrieval (finding info), and Function calling (task execution) <br> <li>These powers combine to form a versatile super-assistant for handling diverse tasks |
| AOAI-in-a-Box |[Assistants API Bot in-a-box](./gen-ai/Assistants/bot-in-a-box)|This tutorial provides a step-by-step guide on how to deploy a virtual assistant leveraging the Azure OpenAI Assistants API. It covers the infrastructure deployment, configuration on the AI Studio and Azure Portal, and end-to-end testing examples.| <li>Deploy the necessary infrastructure to support an Azure OpenAI Assistant <br> <li>Configure as Assistant with the required tools <li>Connect a Bot Framework application to your Assistant to deploy the chat to multiple channels |

## Key contacts

If you have any questions or would like to contribute please reach out to: aibox@microsoft.com

| Contact | GitHub ID | Email |
|--------------|------|-----------|
| Alex Morales | @msalemor | alemor@microsoft.com |
| Andrés Padilla | @AndresPad | andres.padilla@microsoft.com | 
| Chris Ayers | @codebytes | chrisayers@microsoft.com |
| Eduardo Noriega | @EduardoN | ednorieg@microsoft.com |
| Jean Hayes | @jehayesms | jean.hayes@microsoft.com |
| Marco Aurélio Bigélli Cardoso  | @MarcoABCardoso | macardoso@microsoft.com | 
| Maria Vrabie  | @MariaVrabie | mavrabie@microsoft.com | 
| Neeraj Jhaveri | @neerajjhaveri | neeraj.jhaveri@microsoft.com |
| Thiago Rotta | @rottathiago | thiago.rotta@microsoft.com |
| Victor Santana | @Welasco | vsantana@microsoft.com |
| Sabyasachi Samaddar | @ssamadda | ssamadda@microsoft.com |
