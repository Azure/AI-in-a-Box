using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using System.Text.Json;
using Models;
using Services;

namespace Plugins;
public class BingPlugin
{
    private ITurnContext<IMessageActivity> _turnContext;
    private BingClient _bingClient;

    public BingPlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, BingClient bingClient)
    {
        _turnContext = turnContext;
        _bingClient = bingClient;
    }
    // Returns search results with headers.

    [SKFunction, Description("Search the internet by text using Bing. Terms and conditions require you to explicitly say results were pulled from the web, and list links the links associated with any information you provide. Before using this function, the assistant should always ask whether the user would like it to search the web.")]
    public async Task<string> BingSearch(
        [Description("The query to pass into Bing")] string query,
        [Description("The result type you are looking for. One of \"webpages\",\"images\",\"videos\",\"news\". If no news are returned, you may try webpages as a fallback.")] string resultType
    )
    {
        await _turnContext.SendActivityAsync($"Searching the internet for {resultType} with the description \"{query}\"...");

        SearchResult result = await _bingClient.WebSearch(query, resultType);

        return JsonSerializer.Serialize(result);

    }

}