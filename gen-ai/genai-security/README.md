# Guidance: Security for Genenerative AI (GenAI) Applications
![ Need Banner](../../media/images/banner-genai-security.png)

## Introduction
As LLMs become more easily available and integrated into our work and personal lives, the promise of the technology is tempered by the potential for it to be misused. And the potential for misuse becomes even more significant when you realize LLMs can be combined with other powerful software components and agents to orchestrate a pipeline of actions. OR combined with propriatary and personal data to introduce new avenues for data disclosure and leakage.   

The intention for this page is not to reiterate security guidance that is generally available for more traditional or cloud software applications but to focus on guidance specific to *GenAI* applications and the unique characteristics and challenges of LLMs.  

## Threats & Risks
The security threats and risks with traditional software applications are familiar and understood. *GenAI* and LLMs introduce new and unique security risks including:  
* **AI responses are based on statistical probabilities** or the best chance for correct output. LLMs generate convincing human-like responses by predicting what words come next in a phrase. While they can be great at helping with tasks like summarizing a document or explaining complicated concepts or boosting creativity, there can be issues like responses being inaccurate, incomplete, inappropriate, or completely fabricated. You may be familiar with one well known example where ChatGPT provided non-existant legal citations that lawyers presented in court: [Here's what happens when your lawyer uses ChatGPT](https://www.nytimes.com/2023/05/27/nyregion/avianca-airline-lawsuit-chatgpt.html).
* *GenAI* is **by design a non-deterministic technology** which means that given identical inputs, responses and output may differ.  
* *GenAI* applications **can be extended with agents, plugins, and even external APIs that can significantly expand the attack surface** for a GenAI application. For instance, an LLM may implicitly trust a plugin or 3rd party component that is malicious.  
* Another challenge with GenAI is that it **currently it is not possible to enforce an isolation boundary between the data and the control planes**. This means that LLMs are not always able to differentiate between data being submitted as content or an adversarial instruction submitted as content. Think about a SQL databases: instructions are supplied through query language and validated with a parser before data is queried, manipulated, or provided as output.  With a SQL injection attack, a malicious instruction can piggyback in on a ambiguously phrased language construct but it can be mitigated with a parameterized query. GenAI/LLMs do not have that boundary between syntax (control plane) and data and need to rely on other security practices.  
  

## Security Strategies  
Infrastructure plays an indispensable role in helping create a secure landscape for *GenAI* applications, particularly cloud environments. Below are strategies tht can help ensure the security of a *GenAI* environment:    
* **Threat Modeling** Include *GenAI* apps in your threat modeling practice. Undertand that *GenAI* can extend attack surface with access to underlying or referenced data sources, access to model API keys, workflow orchestration, and agents and plugsins. Learn what can go wrong. 
* **Architecture strategies** help ensure  a secure, scalable, and available environment. 
  * [Baseline OpenAI end-to-end chat reference architecture](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/architecture/baseline-openai-e2e-chat): a baseline architecture for building and deploying enterprise chat apps that use Azure OpenAI.
  * [OpenAI end-to-end baseline reference implementation](https://github.com/azure-Samples/openai-end-to-end-baseline): Author and run a chat app in a single region with Azure ML and OpenAI. 
* **Network strategies** help ensure that the cloud infrastructure is properly segmented and that access is controlled and monitored.  It includes implementing network segmentation, using secure protocols, enforcing Secure APIs and endpoints.  For GenAI specific recommendations:    
  * [Cognitive Services Laning Zone in-a-box](https://github.com/Azure/AI-in-a-Box/blob/kbaroni/cognitive-services-landing-zone-in-a-box/README.md)
* **Access and Identity strategies** to enforce user verification and provide a barrier to malicious access. When possible, use managed identities and RBAC to authenticate and authorize access and avoid use of *GenAI* service API keys for access. See:  
  * [Authentication & Authorization in GenAI Apps with Entra ID & Search](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/authentication-and-authorization-in-generative-ai-applications/ba-p/4022277)
* **Application strategies** help ensure the application is configured securely and vulnerabilities are identified and addressed:
    * Use App front end services to manage access and throughput. See: [Azure OpenAI Service Load Balancing with Azure API Management](https://learn.microsoft.com/en-us/samples/azure-samples/azure-openai-apim-load-balancing/azure-openai-service-load-balancing-with-azure-api-management/) and [Smart load balancing for OpenAI endpoints and Azure API Managment](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/smart-load-balancing-for-openai-endpoints-and-azure-api/ba-p/3991616)
    * Ensure related services are deployed securely (AI Search, Cosmos DB, etc)
    * Secure and validate training data and injestion pipelines  
* **Governance strategies** help ensure the infrastructure is being used is meeting security and compliance requirements and that policies and procedures are in place to manage risk and accountability: 
  * Become familiar with Responsible AI principles and frameworks and integrate them early in the development of your application.  More here: [Responsible AI](./responsible-ai)
  * Leverage platform capabilities for logging, auditing, and monitoring *GenAI* apps 
  
## Adversarial Prompting

#### Attacks
An adversarial prompt attack is when a prompt manipulates the LLM to deviate from the original intention of the prompt and generates malicious or unintended outputs and responses. They exploit the inherent ambiguity of language models. You may be familiar with some types of prompt attacks:   
* Prompt injection/leaking  
* Jailbreaking 
* Multi-prompt
* Multi-language
* Obfuscation (token smuggling)


For a more complete list of prompt injection attacks see: [The EL15 Guide to Prompt Injection: Techniques, Prevention Methods & Tools](https://www.lakera.ai/blog/guide-to-prompt-injection)

#### Mitigations
There is a growing list of specific techniques that can be used to mitigating adversarial prompt attacks that include enriching prompts with specific instructions, formatting, and providing examples of the kind of output content that is intended.  Below are some additional strategies to consider: 
  * Defensive Instructions
  * Parameterizing the Prompt
  * Determine intent
  * Monitor for degradation in output quality
  * Use inbound/outbound blocking/white lists or filters or rules 
  * Use other models or dedicated services to pre-process requests 
  * Use the native power of models to steer zero- or few-shot prompting strategies. See [promptbase](https://github.com/microsoft/promptbase) for a growing collection of resources, best practices, and sample scripts.  

See [Exploring Adversarial Prompting and Mitigations in AI-Infused Applications](https://www.linkedin.com/pulse/exploring-adversarial-prompting-mitigations-alex-morales-3sqne/) for more specifics on these types of attacks and defense tactics. 
  
## Resources & References
* [OWASP Top 10 for LLM applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/) and the [downloadable whitepaper](https://www.llmtop10.com/assets/downloads/OWASP-Top-10-for-LLM-Applications-v1_1.pdf)
* [OWASP LLM AI Security & Governance Checklist](https://owasp.org/www-project-top-10-for-large-language-model-applications/llm-top-10-governance-doc/LLM_AI_Security_and_Governance_Checklist.pdf)
* [Security Best Practices for GenAI Applications in Azure](https://techcommunity.microsoft.com/t5/azure-architecture-blog/security-best-practices-for-genai-applications-openai-in-azure/ba-p/4027885)
* [Steering at the Frontier: Extending the Power of Prompting](https://www.microsoft.com/en-us/research/blog/steering-at-the-frontier-extending-the-power-of-prompting/)
* [Planning red teaming for large language models (LLMs) and their applications](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/red-teaming)

