# Guidance on Scaling OpenAI Applications with Azure Services

## Introduction

This guidance document contains best practices for scaling OpenAI applications within Azure, detailing resource organization, quota management, rate limiting, and the strategic use of Provisioned Throughput Units (PTUs) and Azure API Management (APIM) for efficient load balancing.

## Best Practices for Azure OpenAI Resources

- Consolidate Azure OpenAI workloads under a **single Azure subscription** to streamline management and cost optimization.
- Treat Azure OpenAI resources as a **shared service** to ensure efficient usage of PTU and PAYG resources.
- Utilize separate subscriptions only for distinct development and production environments or for geographic requirements.
- Prefer **resource groups for regional isolation**, which simplifies scaling and management compared to multiple subscriptions.
- Maintain a **single Azure OpenAI resource per region**, allowing up to 30 enabled regions within a single subscription.
- Create both PAYG and PTU deployments within each Azure OpenAI resource for each model to ensure flexible scaling.
- Leverage PTUs for business critical usage and PAYG for traffic that exceeds the PTU allocation.

## Quotas and Rate Limiting

### Tokens
- Tokens are basic text units processed by OpenAI models. Efficient token management is crucial for cost and load balancing.

### Quotas
- OpenAI sets API quotas based on subscription plans, dictating API usage within specific time frames.
- Quotas are per model, per region, and per subscription.
- Proactively monitor quotas to prevent unexpected service disruptions.
- **Quotas do not guarantee capacity**, and traffic may be throttled if the service is overloaded. 
- During peak traffic, the service may throttle requests even if the quota has not been reached.

### Rate Limiting
- Rate limiting ensures equitable API access and system stability. 
- Rate Limits are imposed on the number of requests per minute (RPM) and the number of tokens per minute (TPM).
- Implement backoff strategies to handle rate limit errors effectively.

### PTUs
- Utilize PTUs for baseline usage of OpenAI workloads to guarantee consistent throughput.
- PAYG deployments should handle traffic that exceeds the PTU allocation.

## Load Balancing with Azure API Management (APIM)

- APIM plays a pivotal role in managing, securing, and analyzing APIs.
- Policies within APIM can be used to manage traffic, secure APIs and enforce usage quotas.
- **Load Balancing** within APIM distributes traffic evenly, ensuring no single instance is overwhelmed.
- **Circuit Breaker** policies in APIM prevent cascading failures and improve system resilience.
- **Smart Load Balancing** with APIM ensures prioritized traffic distribution across multiple OpenAI resources.

## Security and High Availability

- Use Azure API Management to route traffic, ensuring centralized security and compliance.
- Implement private endpoints to secure OpenAI resources and prevent unauthorized access.
- Leverage Managed Identity to secure access to OpenAI resources and other Azure services.

## Addressing Special Cases and Limitations

- Fine-tuned models should be treated as unique domains. Create separate Azure OpenAI resources for each model family based on specific requirements.

## Conclusion

This guidance outlines a strategy for leveraging Azure OpenAI resources at an enterprise level. By centralizing OpenAI resources and adopting smart load balancing with APIM, organizations can maximize their investment in OpenAI, ensuring scalability, cost-effectiveness, and performance across a wide range of applications and use cases. 

## Additional Resources

- [Smart load balancing with Azure API Management](https://github.com/Azure-Samples/openai-apim-lb)
- [Smart load balancing with Azure Container Apps](https://github.com/Azure-Samples/openai-aca-lb)
- [Using Azure API Management Circuit Breaker and Load balancing with Azure OpenAI Service](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/using-azure-api-management-circuit-breaker-and-load-balancing/ba-p/4041003)

For more detailed information on OpenAI's capabilities, tokens, quotas, rate limits, and PTUs, visit the [Azure OpenAI documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/openai/).
