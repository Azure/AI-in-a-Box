using System.ComponentModel;
using System.Threading.Tasks;
using Models;
using Microsoft.SemanticKernel;
using System.Linq;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Azure.Search.Documents;
using System;
using Azure.Search.Documents.Models;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using System.Collections.Generic;
using Microsoft.IdentityModel.Tokens;
using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using System.Web;

namespace Plugins;

public class HRHandbookPlugin
{
    private readonly SearchClient _searchClient;
    private readonly BlobServiceClient _blobServiceClient;
    private ITurnContext<IMessageActivity> _turnContext;
    private readonly AzureOpenAITextEmbeddingGenerationService _embeddingClient;
    private readonly string _searchSemanticConfig;

    public HRHandbookPlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, AzureOpenAITextEmbeddingGenerationService embeddingClient, SearchClient searchClient, BlobServiceClient blobServiceClient, string searchSemanticConfig)
    {
        _searchClient = searchClient;
        _blobServiceClient = blobServiceClient;
        _searchSemanticConfig = searchSemanticConfig;
        _embeddingClient = embeddingClient;
        _turnContext = turnContext;
    }

    [KernelFunction, Description("Search for HR information in the handbook. Whenever you use information from this source, you must provide itemized sources at the end of your response, including the document name, and link where available. When adding links, always include query paramenters. If the result is a PDF file and the page number is available, append #page={page number} to the end of the link. Do not provide links if they were not retrieved.")]
    public async Task<string> FindHR(
        [Description("The query to be used in the search")] string query
    )
    {
        await _turnContext.SendActivityAsync($"Searching the HR Handbook with the query \"{query}\"...");
        var embedding = await _embeddingClient.GenerateEmbeddingsAsync(new List<string> { query });
        var vector = embedding.First().ToArray();

        var searchOptions = new SearchOptions
        {
            VectorSearch = new()
            {
                Queries = { new VectorizedQuery(vector) { KNearestNeighborsCount = 3, Fields = { "vector" } } }
            },
            SemanticSearch = new()
            {
                SemanticConfigurationName = _searchSemanticConfig,
                QueryCaption = new(QueryCaptionType.Extractive),
                QueryAnswer = new(QueryAnswerType.Extractive),
            },
            QueryType = SearchQueryType.Semantic,
            Size = 3,
        };
        var response = await _searchClient.SearchAsync<RetrievedPassage>(query, searchOptions);
        var textResults = "[HR HANDBOOK RESULTS]\n\n";
        var searchResults = response.Value.GetResults();
        if (searchResults.Count() == 0)
            return "No results found";
        foreach (SearchResult<RetrievedPassage> result in searchResults)
        {
            textResults += $"Title: {result.Document.Title} \n\n";
            textResults += $"Section: {string.Join(" ", result.Document.ChunkId.Split("_").Skip(2))} \n\n";
            if (!result.Document.Path.IsNullOrEmpty())
            {
                textResults += $"Link: \"{createSasUri(result.Document.Path)} \n\n\"";
            }
            textResults += $"Content: {result.Document.Chunk}\n*****\n\n";
        }
        Console.WriteLine(textResults);
        return textResults;
    }

    private string createSasUri(string resourceUri)
    {
        var resourceUriParts = resourceUri.Split('/');
        string containerName = resourceUriParts[3];
        string blobName = HttpUtility.UrlDecode(string.Join("/", resourceUriParts.Skip(4))); 
        // Create a Uri object with a service SAS appended
        BlobClient blobClient = _blobServiceClient
            .GetBlobContainerClient(containerName)
            .GetBlobClient(blobName);
        // Create a SAS token that's valid for one day
        BlobSasBuilder sasBuilder = new BlobSasBuilder
        {
            BlobContainerName = containerName,
            BlobName = blobName,
            Resource = "b",
            ExpiresOn = DateTimeOffset.UtcNow.AddDays(1)
        };
        sasBuilder.SetPermissions(BlobContainerSasPermissions.Read);
        Uri sasURI = blobClient.GenerateSasUri(sasBuilder);

        return sasURI.ToString();
    }

}
