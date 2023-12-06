using System.ComponentModel;
using System.Threading.Tasks;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Models;
using Microsoft.SemanticKernel;
using System.Linq;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;

namespace Plugins;

public class HotelsPlugin
{
    private readonly SearchClient _searchClient;
    private ITurnContext<IMessageActivity> _turnContext;

    public HotelsPlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, SearchClient searchClient) {
        _searchClient = searchClient;
        _turnContext = turnContext;
    }

    

    [SKFunction, Description("Search for hotels by description.")]
    public async Task<string> FindHotels(
        [Description("The description to be used in the search")] string query
    )
    {
        await _turnContext.SendActivityAsync($"Searching hotels with the description \"{query}\"...");
        var options = new SearchOptions();
        options.Select.Add("HotelName");
        options.Select.Add("Address");
        options.Select.Add("Description");
        options.Size = 3;
        var response = await _searchClient.SearchAsync<Hotel>(searchText: query, options);
        var textResults = "[HOTEL RESULTS]\n\n";
        var searchResults = response.Value.GetResults();
        if (searchResults.Count() == 0)
            return "No hotels found";
        foreach (SearchResult<Hotel> result in searchResults)
        {
            textResults += $"Name: {result.Document.HotelName}: {result.Document.Address.StreetAddress}, ${result.Document.Address.City}\n\n";
            textResults += $"Description: {result.Document.Description}\n*****\n\n";
        }
        return textResults;
    }

}