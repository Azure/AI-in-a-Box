using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Threading.Tasks;
using HtmlAgilityPack;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.BotBuilderSamples;
using Models;

public class Tools
{
    private HttpClient client = new HttpClient();
    private ITurnContext _turnContext;
    private ConversationData _conversationData;

    public Tools(
        ConversationData conversationData,
        ITurnContext<IMessageActivity> turnContext
    )
    {
        _conversationData = conversationData;
        _turnContext = turnContext;
    }

    public async Task<ToolOutputData> RunRequestedTools(ThreadRun run)
    {
        var submitData = new ToolOutputData()
        {
            ToolOutputs = new()
        };
        foreach (ToolCall toolcall in run.RequiredAction.SubmitToolOutputs.ToolCalls)
        {
            var method = typeof(Tools).GetMethod(toolcall.Function.Name);
            var arguments = JsonSerializer.Deserialize<Dictionary<string, object>>(toolcall.Function.Arguments);
            string output = await (Task<string>)method.Invoke(this, [arguments]);
            var toolOutput = new ToolOutput
            {
                ToolCallId = toolcall.Id,
                Output = output
            };
            submitData.ToolOutputs.Add(toolOutput);
        }
        return submitData;
    }

    public async Task<string> mslearn_query_articles(Dictionary<string, object> arguments)
    {
        var query = arguments["query"].ToString();
        await _turnContext.SendActivityAsync($"Searching MS Learn for \"{query}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://learn.microsoft.com/api/search?search={UrlEncoder.Default.Encode(query)}&locale=en-us&$top=3"
        );
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();
        else
            return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";
    }

    public async Task<string> mslearn_get_article(Dictionary<string, object> arguments)
    {
        var pageUrl = arguments["page_url"].ToString();
        if (!pageUrl.StartsWith("https://learn.microsoft.com/"))
            return "NOT ALLOWED TO FETCH DATA FROM API OUTSIDE OF LEARN.MICROSOFT.COM";
        await _turnContext.SendActivityAsync($"Getting docs page \"{pageUrl}\"...");

        var web = new HtmlWeb();
        var doc = web.Load(pageUrl);

        return doc.GetElementbyId("main-column").InnerText;
    }
    public async Task<string> wikipedia_query_articles(Dictionary<string, object> arguments)
    {
        var query = arguments["query"].ToString();
        await _turnContext.SendActivityAsync($"Searching Wikipedia for \"{query}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://en.wikipedia.org/w/api.php?action=opensearch&search={UrlEncoder.Default.Encode(query)}&limit=1"
        );
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();
        else
            return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";
    }
    public async Task<string> wikipedia_get_article(Dictionary<string, object> arguments)
    {
        var pageTitle = arguments["page_title"].ToString();
        await _turnContext.SendActivityAsync($"Getting article \"{pageTitle}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://en.wikipedia.org/w/api.php?action=query&format=json&titles={UrlEncoder.Default.Encode(pageTitle)}&prop=extracts&explaintext"
        );
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();
        else
            return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";

    }
    public async Task<string> bot_show_image(Dictionary<string, object> arguments)
    {
        var imageUrl = arguments["image_url"].ToString();
        List<object> images = [new { type = "Image", url = imageUrl }];
        object adaptiveCardJson = new
        {
            type = "AdaptiveCard",
            version = "1.0",
            body = images
        };

        var adaptiveCardAttachment = new Microsoft.Bot.Schema.Attachment()
        {
            ContentType = "application/vnd.microsoft.card.adaptive",
            Content = adaptiveCardJson,
        };
        await _turnContext.SendActivityAsync(MessageFactory.Attachment(adaptiveCardAttachment));
        return "IMAGE SENT TO USER SUCCESSFULLY. DO NOT EMBED IT INTO YOUR RESPONSE.";
    }
}