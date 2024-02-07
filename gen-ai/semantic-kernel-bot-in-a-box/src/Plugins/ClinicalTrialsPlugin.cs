using System.ComponentModel;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using System.Net.Http;
using System.Xml;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;

namespace Plugins;

public class ClinicalTrialsPlugin
{
    static HttpClient client = new HttpClient();

    private ITurnContext<IMessageActivity> _turnContext;

    public ClinicalTrialsPlugin(IConfiguration config, ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
    {
        _turnContext = turnContext;
    }


    [KernelFunction, Description("Search for relevant clinical trials for a query. Do not use this unless it can be inferred that the user would like to enroll or otherwise find out about ongoing clinical trials. ")]
    public async Task<string> ESearch(
        [Description("The text to be searched. Will only match documents containing this text exactly, so use as few words as possible.")] string query
    )
    {

        await _turnContext.SendActivityAsync($"Searching ClinicalTrials for \"{query}\"...");
        HttpResponseMessage response = await client.GetAsync(
            $"https://classic.clinicaltrials.gov/api/query/study_fields?fields=NCTId,Condition,BriefTitle,BriefSummary&max_rnk=3&expr={query.Replace(" ", "+")}"
        );
        var textResult = "";
        if (response.IsSuccessStatusCode)
        {
            if (response.IsSuccessStatusCode)
            {
                var xmlDoc = new XmlDocument();
                var strRes = await response.Content.ReadAsStringAsync();
                xmlDoc.LoadXml(strRes);
                foreach (XmlNode node in xmlDoc.GetElementsByTagName("StudyFields"))
                {

                    textResult += $"{node.OuterXml} \n\n";
                }

            }
        }
        return textResult;

    }
}