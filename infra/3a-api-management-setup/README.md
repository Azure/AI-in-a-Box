# Azure OpenAI Using PTUs/TPMs With API Management
# The _Scaling Secret Sauce_
### You are here: https://github.com/Azure/AI-in-a-Box/tree/main/infra/3a-api-management-setup

## Introduction
While there are already a few reference architectures available for using Azure OpenAI, this article will focus on AOAI + APIM with **deploying at scale** using PTUs (Reserved Capacity) and TPM (Pay-As-You-Go).

## A Quick Review

Azure OpenAI (AOAI) + API Management (APIM):
![image](https://github.com/Azure/AI-in-a-Box/assets/9942991/1c8ec063-4fd2-42bb-b8ac-db8772edec7e)

APIs are the foundation of an API Management service instance. Each API represents a set of operations available to app developers.
Each API contains a reference to the backend service that implements the API, and its operations map to backend operations. Azure OpenAI provides an API endpoint to consume the AOAI service, and APIM utilzies this AOAI endpoint.

Operations in API Management are highly configurable, with control over URL mapping, query and path parameters, request and response content, and operation response caching. You can read additional details on using APIM here <https://learn.microsoft.com/en-us/azure/api-management/api-management-key-concepts> 

When using Azure OpenAI with API Management, this gives you the most flexibility in terms of both queing prompts (text sent to AOAI) as well as return code/error handling management. More later in this repo on using APIM with AOAI.

## TPMs and PTUs
First, let's define TPMs and PTUs.  As we continue understanding scaling of the Azure OpenAI service, we Azure OpenAI's quota feature enables assignment of rate limits to your deployments, and also used for billing purposes.
Microsoft also recently introduced a new quota management system 
along with the ability to use reserved capacity, Provisioned Throughput Units (PTU), for AOAI.  We will describe both TPMs and PTUs, as this is critical for scaling of services.

### TPMs
Typically, many organizations will test or scale Azure OpenAI using TPMs, or Tokens Per Minute, the standard default AOAI service. Azure OpenAI's quota feature enables assignment of rate limits to your deployments, up-to a global limit called your “quota.” Quota is assigned to your subscription on a per-region, per-model basis in units of Tokens-per-Minute (TPM), by default. When you onboard a subscription to Azure OpenAI, you'll receive default quota for most available models. Then, you'll assign TPM to each deployment as it is created, and the available quota for that model will be reduced by that amount. You can learn more about AOAI quota managment here:  https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/quota?tabs=rest

It is important to note that although the billing for AOAI service is token-based (TPM), the actual triggers which rate limit is based on a per second basis. That is, if you are using a GPT-4 (8K) model with an 8K limit, and have concurrent users, the token limit is throttled at whatever the maximum is, based on the model limit.

https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/quota?tabs=rest

### PTUs 
Beyond the default TPMs described above, a new Azure OpenAI service feature called Provisioned Throughput Units (PTUs), define the model processing capacity, **using reserved resources**, for processing prompts and generating completions.

PTUs are purchased as a monthly commitment with an auto-renewal option, which reserves AOAI capacity against an Azure subscription, in a specific Azure region.

Throughput is highly dependent on your scenario, and will be affected by a few items including number and ratio of prompt and generation tokens, number of simultaneous requests,

As organizations scale using Azure OpenAI, they may see rate limit on how fast tokens are processed, in their prompt+completion. There is a limit to how much text (prompts) can be sent due to the token limits  for each model that can be consumed in a single request+response from Azure OpenAI Service. It is important to note the overall size of tokens used include BOTH the prompt (text sent to the AOAI model) PLUS the return completion (response back from the model), and also this token size and limt varies for each different AOIA model type. 
For example,  with a quota of 240,000 TPM for GPT-35-Turbo in Azure East US region, you can have a single deployment of 240K TPM, 2 deployments of 120K TPM each, or any number of deployments in one or multiple deployments as long as the TPMs add up to 240K (or less) total in that region.
As our customers are scaling, they can add an additional Azure OpenAI account in the same region, as described here: https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal

The maximum Azure OpenAI resources per region per Azure subscription is 30 (at the time of this writing) and also depending on regional capacity **availability.** This limit may increase in the future. https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits

# Scaling
There are other articles/repos which describe this basic scenario, and also provide configurations for the basic APIM setup used with AOAI, so we will not re-invent the wheel here. Example: https://github.com/Azure-Samples/openai-python-enterprise-logging

![image](https://github.com/Azure/AI-in-a-Box/assets/9942991/fb524952-564b-4623-9d70-c54a1f5a869d)

# The Scaling Secret Sauce (yes you heard it hear first)

So how do we control (or queue) messages when using multiple Azure OpenAI instances (accounts)
As a best practice, Microsoft recommends the use of **retry logic** whenever using a service such as AOAI.  With APIM, this will allow us do this easily, but with some secret sauce added it... using the concept of _retries with exponential backoff_.
Retries with exponential backoff is a technique that retries an operation, with an exponentially increasing wait time, up to a maximum retry count has been reached (the exponential backoff). This technique embraces the fact that cloud resources might intermittently be unavailable for more than a few seconds for any reason, or more likely using AOAI, if an error is returned due to too many tokens per second (or requests per second) in a large scale deployment.

You can enable This can be accomplished via the APIM Retry Policy, https://learn.microsoft.com/en-us/azure/api-management/retry-policy

	<retry condition="@(context.Response.StatusCode == 429 || context.Response.StatusCode >= 500)" interval="1" delta="1" max-interval="30" count="13">

Note the above error is specifc to an response status code equal to '429', which is the return code for 'server busy', which states too many concurrent requests were sent to the model.
**And extremely important**: When the APIM **interval, max-interval and delta** parameters are specified, then an **exponential interval retry algorithm** is applied. 
It is with this exponential retry are you able to scale many thousands of users with very low error responses.
Without this secret sauce of ,  once the initial rate limts hit with concurrent users, the latency and error issues compound further and further. That is, 

# Multi-Region


# Best Practices

	### 1. HTTP Return Codes/Errors:  As described in the Secret Sauce section above, you can use retries with exponential backoff for any 429 errors
https://learn.microsoft.com/en-us/azure/api-management/retry-policy

	However, you should always configure error checking on the size of prompt vs the model this prompt is intended for.
For example, for GPT-4 (8k), this model supports a max request token limit of 8,192.  If your prompt is 10K in size, then this will fail, AND ALSO any subsequent retries would fail as well, as the token limit was already reached.
As a best practice, ensure the prompt size does not exceed the max request token limit immediately, prior to sending the prompt across the wire to the AOAI service.
	
Again here are the token limits for each model: Azure OpenAI Service models - Azure OpenAI | Microsoft Learn
		
This table describes **a few of the common** HTTP Response Codes from AOAI

HTTP Response Code | Cause | Remediation | Notes
--- | --- | --- | ---
200 | Processed the prompt. Completion without error | N/A |
429 (v0613 AOAI Models)	|  Server Busy (Rate limit reached for requests) | APIM - Retries with Exponential Backoff |	When the APIM interval, max-interval and delta are specified, an exponential interval retry algorithm is applied. 
424 (v0301 AOAI Models)	| Server Busy (Rate limit reached for requests) | APIM - Retries with Exponential Backoff | Same as above
408  | Request timeout | APIM Retry with interval | Many reasons why a timeout could occur, such as a network connection error.
50x |	Internal server error due to transient error or backend AOAI internal error |	APIM Retry with interval| See Retry Policy Link

**Retry Policy**: https://learn.microsoft.com/en-us/azure/api-management/retry-policy	
	
	
	### 2. Auto update to Default 

	As versions of When Auto-update to default is selected your model deployment will be automatically updated within two weeks of a change in the default version.
	
	If you are still in the early testing phases for inference models, we recommend deploying models with auto-update to default set whenever it is available.
	2. Latest + Default Model Deployments
	3. Purchasing PTU's:
		Billing is up-front for the entire month, starting on the day of purchase
		
		PTUs can be added to a commitment mid-month, but cannot be reduced
		
		If a commitment is not renewed, deployed PTUs will revert to per hour pricing
		Single Region
		
	
	4. Multi-Region APIM:
	Azure API Management has 3 production level tiers - Basic, Standard, and Premium.
Upgrade and scale an Azure API Management instance | Microsoft Learn
	
	The Premium tier enables you to distribute a single Azure API Management instance across any number of desired Azure regions. When you initially create an Azure API Management service, the instance contains only one unit and resides in a single Azure region (the primary region).
What does this provide? If you have a multi-regional Azure OpenAI deployment, does this mean you are required to also have a multi-region (Premium) SKU of APIM? No, not necessarily!
	What the Premium SKU gives you is the ability to have one region be the primary and any number of regions as seondar
	

	How to deploy an Azure API Management service instance to multiple Azure regions.
	
	Rate Limits: Rate limit best practices From <https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/quota?tabs=rest> 
	To minimize issues related to rate limits, it's a good idea to use the following techniques:
		• Set max_tokens and best_of to the minimum values that serve the needs of your scenario. For example, don’t set a large max-tokens value if you expect your responses to be small as this may increase response times.
		• Use quota management to increase TPM on deployments with high traffic, and to reduce TPM on deployments with limited needs.
		• Avoid sharp changes in the workload. Increase the workload gradually.
		• Test different load increase patterns.
