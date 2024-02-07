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

public class PubmedPlugin
{
    static HttpClient client = new HttpClient();

    private ITurnContext<IMessageActivity> _turnContext;

    public PubmedPlugin(IConfiguration config, ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
    {
        _turnContext = turnContext;
    }

    class ESearchResponse
    {
        public object header { get; set; }
        public ESearchResult esearchresult { get; set; }

    }
    class ESearchResult
    {
        public int count { get; set; }
        public int retmax { get; set; }
        public int retstart { get; set; }
        public List<string> idList { get; set; }
    }


    [KernelFunction, Description("Search for relevant scientific papers on health-related topics. Do not use this unless the user's question is related to recent research. Always list source documents when using information from this function.")]
    public async Task<string> ESearch(
        [Description("The text to be searched. Will only match documents containing this text exactly, so use as few words as possible.")] string query
    )
    {

        await _turnContext.SendActivityAsync($"Searching Pubmed for \"{query}\"...");
        ESearchResponse esresponse = null;
        HttpResponseMessage response = await client.GetAsync(
            $"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmode=json&retmax=3&sort=relevance&term=%22{query.Replace(" ", "+AND+")}%22"
        );
        if (response.IsSuccessStatusCode)
        {
            esresponse = await response.Content.ReadFromJsonAsync<ESearchResponse>();
        }
        return string.Join("\n", esresponse.esearchresult.idList);
    }

    [KernelFunction, Description("Retrieve the summary of a list of articles")]
    public async Task<string> FindHotels(
        [Description("Comma-separated list of article IDs to be retrieved. If information coming from this function is used, you must provide the relevant links at the end of the final answer.")] string ids
    )
    {
        string textResult = "";
        HttpResponseMessage response = await client.GetAsync(
            $"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id={ids}"
        );
        if (response.IsSuccessStatusCode)
        {
            var xmlDoc = new XmlDocument();
            var strRes = await response.Content.ReadAsStringAsync();
            xmlDoc.LoadXml(strRes);
            foreach (XmlNode node in xmlDoc.GetElementsByTagName("AbstractText")) {
                var article = node.ParentNode.ParentNode;
                var id = article.ParentNode.ChildNodes[0].InnerText;
                var title = article.ChildNodes[1].InnerText;
                var summary = node.InnerText;
                textResult += $"{title}: {summary}\nSource link: https://pubmed.ncbi.nlm.nih.gov/{id}/\n*****\n";
            }

        }
        return textResult;
    }

}