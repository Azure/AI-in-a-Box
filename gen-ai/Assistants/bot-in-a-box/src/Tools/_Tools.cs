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
using Microsoft.Extensions.Configuration;
using Models;
using Services;

public class Tools
{
    private readonly IConfiguration _config;
    private HttpClient client = new HttpClient();
    private AOAIClient _aoaiClient;
    private ITurnContext _turnContext;
    private ConversationData _conversationData;

    public Tools(
        IConfiguration config,
        ConversationData conversationData,
        ITurnContext<IMessageActivity> turnContext,
        AOAIClient aoaiClient
    )
    {
        _config = config;
        _conversationData = conversationData;
        _turnContext = turnContext;
        _aoaiClient = aoaiClient;
    }

    public async Task<ToolOutputData> RunRequestedTools(ThreadRun run)
    {
        var submitData = new ToolOutputData()
        {
            ToolOutputs = new(),
            Stream = true
        };
        foreach (ToolCall toolcall in run.RequiredAction.SubmitToolOutputs.ToolCalls)
        {
            var method = typeof(Tools).GetMethod(toolcall.Function.Name);
            var arguments = JsonSerializer.Deserialize<Dictionary<string, object>>(toolcall.Function.Arguments);
            string output = await (Task<string>)method.Invoke(this, new object[] { arguments });
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
    public async Task<string> bing_query(Dictionary<string, object> arguments)
    {
        var query = arguments["query"].ToString();
        var resultType = arguments["type"].ToString();
        await _turnContext.SendActivityAsync($"Searching Bing for {resultType} about \"{query}\"...");
        // Construct the search request URI.
        var path = _config["BING_API_ENDPOINT"] + "/v7.0/search?count=3&q=" + Uri.EscapeDataString(query) + "&responseFilter=" + Uri.EscapeDataString(resultType);

        var tokenRequest = new HttpRequestMessage(HttpMethod.Get, path)
        {
            Headers =
            {
                { "Ocp-Apim-Subscription-Key", _config["BING_API_KEY"] },
            },
        };
        var response = await client.SendAsync(tokenRequest, default);
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();
        else
            return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";
    }
    public async Task<string> dalle_generate_images(Dictionary<string, object> arguments)
    {
        var numImages = ((JsonElement)arguments["num_images"]).GetInt32();
        var prompt = arguments["prompt"].ToString();
        await _turnContext.SendActivityAsync($"Generating {numImages} images with the description \"{prompt}\"...");
        var imageGenerationOutput = await _aoaiClient.GenerateImages(
            new ImageGenerationInput()
            {
                Prompt = prompt,
                Size = "1024x1024",
                N = numImages
            });

        List<object> images = new();
        foreach (GeneratedImage img in imageGenerationOutput.Data)
            images.Add(new { type = "Image", url = img.Url });
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
        return "Images were generated successfully and already sent to user. No need to embed or reference them into your next message.";
    }
}