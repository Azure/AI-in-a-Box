using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using System.Text.Json;
using Models;
using Services;
using HtmlAgilityPack;
using System;

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

    [KernelFunction, Description("Search the internet by text using Bing. Terms and conditions require you to explicitly say results were pulled from the web, and list links the links associated with any information you provide. Before using this function, the assistant should always ask whether the user would like it to search the web.")]
    public async Task<string> BingSearch(
        [Description("The query to pass into Bing")] string query,
        [Description("The result type you are looking for. One of \"webpages\",\"images\",\"videos\",\"news\". If no news are returned, you may try webpages as a fallback.")] string resultType
    )
    {
        await _turnContext.SendActivityAsync($"Searching the internet for {resultType} with the description \"{query}\"...");

        SearchResult result = await _bingClient.WebSearch(query, resultType);

        return JsonSerializer.Serialize(result);
    }

    [KernelFunction, Description("Browse to a URL to get information. This can only be used with URLs returned from Bing search. It will not work for any others. Always provide the URL source and human-readable name of the source if available when using this function.")]
    public async Task<string> BingBrowse(
        [Description("The URL to browse")] string url
    )
    {
        await _turnContext.SendActivityAsync($"Browsing to {url}...");
        
        var web = new HtmlWeb();
        var doc = web.Load(url);

        Console.WriteLine(doc.DocumentNode.InnerText);
        return doc.DocumentNode.InnerText;
    }
}