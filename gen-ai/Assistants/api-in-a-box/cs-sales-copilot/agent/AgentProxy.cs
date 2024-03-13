namespace agent;

using Azure;
using Azure.AI.OpenAI;

public class AgentProxy
{
    public AgentSettings Settings { get; set; } = null!;
    public List<AgentRegistration> RegisteredAgents { get; set; } = new();
    static OpenAIClient OpenAIClient { get; set; } = null!;

    public AgentProxy(AgentSettings? settings, List<AgentRegistration> registeredAgents)
    {
        Settings = settings ?? new AgentSettings();

        foreach (var agent in registeredAgents)
        {
            RegisteredAgents.Add(agent);
        }
    }

    async Task<string> SemanticIntent(string input)
    {
        var promptTemptate = @"system:
You are an agent that can determine intent from the following list of intents and return the intent that best matches the user's question or statement.

List of intents:
<INTENTS>
OtherAgent: any other question

user:
<QUESTION>

Output in ONE word.";

        var prompt = promptTemptate.Replace("<INTENTS>",
            string.Join(".\n", RegisteredAgents.Select(x => $"{x.Intent}: {x.IntentDescription}.").ToList()))
            .Replace("<QUESTION>", input);

        try
        {
            return await CallOpenLLM(prompt, 2, 0.1f);
        }
        catch (Exception)
        {
            return "OtherAgent";
        }
    }

    async Task<string> CallOpenLLM(string input, int maxTokens = 100, float temperature = 0.3f)
    {
        OpenAIClient ??= new OpenAIClient(new Uri(Settings.APIEndpoint),
            new AzureKeyCredential(Settings.APIKey));

        var chatCompletionsOptions = new ChatCompletionsOptions()
        {
            DeploymentName = Settings.APIDeploymentName, // Use DeploymentName for "model" with non-Azure clients
            Messages =
            {
                // The system message represents instructions or other guidance about how the assistant should behave
                new ChatRequestAssistantMessage(input),
            },
            MaxTokens = maxTokens,
            Temperature = temperature
        };

        try
        {
            Response<ChatCompletions> response = await OpenAIClient.GetChatCompletionsAsync(chatCompletionsOptions);
            return response.Value.Choices[0].Message.Content;
        }
        catch (Exception)
        {
            return string.Empty;
        }
    }

    public async Task ProcessForIntent(string input, int maxTokens = 100, float temperature = 0.3f)
    {
        // Determine the intent
        var intent = await SemanticIntent(input);
        Console.WriteLine($"Intent: {intent}");

        // Process the intent
        switch (intent)
        {
            case "OtherAgent":
                Console.WriteLine(await CallOpenLLM(input, maxTokens, temperature));
                break;
            default:
                foreach (var agent in RegisteredAgents)
                {
                    if (agent.Intent == intent)
                    {
                        IAssistantAgent assistantAgent = (IAssistantAgent)agent.Agent;
                        await assistantAgent.ProcessPrompt(input);
                    }
                }
                break;
        }
    }

}