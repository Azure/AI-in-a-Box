// Sample code from: https://github.com/microsoft/BotFramework-WebChat
using System;
using System.Net.Http;
using System.Net.Mime;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using Models;

namespace Services
{
    public class SpeechService
    {
        private readonly HttpClient _httpClient;
        private readonly string _speechApiKey;

        public SpeechService(HttpClient httpClient, string uriBase, string speechApiKey)
        {
            httpClient.BaseAddress = new Uri(uriBase);

            _httpClient = httpClient;
            _speechApiKey = speechApiKey;
        }

        // Generates a new Direct Line token given the secret.
        // Provides user ID in the request body to bind the user ID to the token.
        public async Task<SpeechTokenDetails> GetTokenAsync(CancellationToken cancellationToken = default)
        {
            var tokenRequest = new HttpRequestMessage(HttpMethod.Post, "sts/v1.0/issueToken")
            {
                Headers =
                {
                    { "Ocp-Apim-Subscription-Key", _speechApiKey },
                },
            };

            var tokenResponseMessage = await _httpClient.SendAsync(tokenRequest, cancellationToken);

            if (!tokenResponseMessage.IsSuccessStatusCode)
            {
                throw new InvalidOperationException($"Speech token API call failed with status code {tokenResponseMessage.StatusCode}");
            }

            using var responseContentStream = await tokenResponseMessage.Content.ReadAsStreamAsync();
            var token = new System.IO.StreamReader(responseContentStream, Encoding.UTF8).ReadToEnd();

            return new SpeechTokenDetails() {
                Token = token
            };
        }
    }
}