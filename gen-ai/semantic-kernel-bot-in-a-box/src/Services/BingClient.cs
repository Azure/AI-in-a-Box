using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Models;

namespace Services
{
    public class BingClient
    {
        private readonly HttpClient _httpClient;
        private readonly string _accessKey;
        public BingClient(HttpClient httpClient, Uri uriBase, string apiKey) {
            httpClient.BaseAddress = uriBase;
            _httpClient = httpClient;
            _accessKey = apiKey;
        }
        public async Task<SearchResult> WebSearch(string searchQuery, string resultType)
        {
            // Construct the search request URI.
            var path = "/v7.0/search?count=3&q=" + Uri.EscapeDataString(searchQuery) + "&responseFilter=" + Uri.EscapeDataString(resultType);

            var tokenRequest = new HttpRequestMessage(HttpMethod.Get, path)
            {
                Headers =
                {
                    { "Ocp-Apim-Subscription-Key", _accessKey },
                },
            };
            var response = await _httpClient.SendAsync(tokenRequest, default);

            var responseContent = await response.Content.ReadAsStringAsync();
            var searchResult = JsonSerializer.Deserialize<SearchResult>(responseContent);
            
            return searchResult;
        }

    }
}