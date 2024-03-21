using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.BotBuilderSamples;
using System.Net.Http;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.SemanticKernel;
using System.Text.Encodings.Web;

namespace Plugins;

public class WikipediaPlugin
{
    static HttpClient client = new HttpClient();

    private ITurnContext<IMessageActivity> _turnContext;

    public WikipediaPlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
    {
        _turnContext = turnContext;
    }


    [KernelFunction, Description("Search Wikipedia for up-to-date information on any topic. Always add the article URL at the end of your responses.")]
    public async Task<string> QueryArticles(
        [Description("The text to be searched. Use as few words as possible.")] string query
    )
    {
        await _turnContext.SendActivityAsync($"Searching Wikipedia for \"{query}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://en.wikipedia.org/w/api.php?action=opensearch&search={UrlEncoder.Default.Encode(query)}&limit=1"
        );
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();
        else 
            return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";
    }

    [KernelFunction, Description("Retrieve a Wikipedia article. Always add the article URL at the end of your responses.")]
    public async Task<string> GetArticle(
        [Description("The article title. Must be obtained from a QueryArticles call.")] string title
    )
    {
        await _turnContext.SendActivityAsync($"Getting article \"{title}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://en.wikipedia.org/w/api.php?action=query&format=json&titles={UrlEncoder.Default.Encode(title)}&prop=extracts&explaintext"
        );
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();
        else 
            return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";
    }
}

