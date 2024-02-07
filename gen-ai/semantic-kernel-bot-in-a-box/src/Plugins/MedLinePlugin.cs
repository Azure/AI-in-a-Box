using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using System.Net.Http;
using System.Collections.Generic;
using System.Net.Http.Json;
using System.Xml;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;

namespace Plugins;

public class MedlinePlugin
{
    static HttpClient client = new HttpClient();

    private ITurnContext<IMessageActivity> _turnContext;

    public MedlinePlugin(IConfiguration config, ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
    {
        _turnContext = turnContext;
    }


    [KernelFunction, Description("Search for up-to-date information on health-related topics. Always list source documents when using information from this function. Do not search for very specific content - instead use more generic wording, and as few words as possible.")]
    public async Task<string> ESearch(
        [Description("The text to be searched.")] string query
    )
    {

        await _turnContext.SendActivityAsync($"Searching MedLine for \"{query}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://wsearch.nlm.nih.gov/ws/query?retmax=3&db=healthTopics&term={query.Replace(" ", "+")}"
        );
        var textResult = "";
        if (response.IsSuccessStatusCode)
        {
            if (response.IsSuccessStatusCode)
            {
                var xmlDoc = new XmlDocument();
                var strRes = await response.Content.ReadAsStringAsync();
                xmlDoc.LoadXml(strRes);
                foreach (XmlNode node in xmlDoc.GetElementsByTagName("document"))
                {

                    textResult += $"{node.OuterXml} \n\n";
                }

            }
        }
        return textResult;

    }
}