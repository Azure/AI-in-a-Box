namespace SalesAgent;

using agent;
using Azure.AI.OpenAI.Assistants;

public class SalesAgent
{
    private SalesAgent() { }

    public static async Task<AssistantAgent> GetAgent(AgentSettings? settings,
    AssistantsClient? client)
    {
        var dataFolder = "../sales_copilot/data/";

        var agent = new AssistantAgent(settings, client, "Sales Agent", "You are an assistant that can help answer questions customers, sellers, orders and inventory.", dataFolder: dataFolder);
        await agent.CreateAssistant();
        return agent;
    }
}