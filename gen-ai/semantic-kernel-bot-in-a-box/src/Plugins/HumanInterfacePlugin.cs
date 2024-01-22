using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Azure.AI.OpenAI;
using System.Collections.Generic;

namespace Plugins;
public class HumanInterfacePlugin
{
    private readonly OpenAIClient _aoaiClient;
    private ITurnContext<IMessageActivity> _turnContext;

    public HumanInterfacePlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, OpenAIClient aoaiClient)
    {
        _aoaiClient = aoaiClient;
        _turnContext = turnContext;
    }



    [KernelFunction, Description("Generate a human-readable final answer based on the results of a plan. Always run this as a final step of any plan to respond to the user.")]
    public async Task<string> GenerateFinalResponse(
        [Description("Plan results")] string planResults,
        [Description("User's goal")] string goal
    )
    {
        await _turnContext.SendActivityAsync($"Generating final answer...");
        var completionsOptions = new ChatCompletionsOptions("gpt-4", new List<ChatRequestMessage>{
            new ChatRequestSystemMessage(@$"The information below was obtained by connecting to external systems. Please use it to formulate a response to the user.
                [PLAN RESULTS]:
                {planResults}"),
            new ChatRequestUserMessage(goal)
        });
        var completions = await _aoaiClient.GetChatCompletionsAsync(completionsOptions);
        return completions.Value.Choices[0].Message.Content;
    }


}