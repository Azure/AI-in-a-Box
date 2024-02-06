using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Mime;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.BotBuilderSamples;
using Models;

namespace Services
{
    public class AOAIClient
    {
        private readonly HttpClient _httpClient;
        private readonly string _accessKey;
        public AOAIClient(HttpClient httpClient, Uri uriBase, string apiKey)
        {
            httpClient.BaseAddress = uriBase;
            _httpClient = httpClient;
            _accessKey = apiKey;
        }

        public async Task<List<Assistant>> ListAssistants()
        {
            var result = await SendRequest<AOAIResponse<Assistant>>("/assistants", HttpMethod.Get);
            return result.Data;
        }
        public async Task<Assistant> GetAssistant(string assistantId)
        {
            return await SendRequest<Assistant>($"/assistants/{assistantId}", HttpMethod.Get);
        }
        public async Task<Thread> CreateThread()
        {
            return await SendRequest<Thread>("/threads", HttpMethod.Post);
        }
        public async Task<Thread> DeleteThread(string threadId)
        {
            return await SendRequest<Thread>($"/threads/{threadId}", HttpMethod.Delete);
        }
        public async Task<Thread> SendMessage(string threadId, MessageInput message)
        {
            return await SendRequest<Thread>($"/threads/{threadId}/messages", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(message), Encoding.UTF8, "application/json"));
        }
        public async Task<ThreadRun> CreateThreadRun(string threadId, ThreadRunInput run)
        {
            return await SendRequest<ThreadRun>($"/threads/{threadId}/runs", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(run), Encoding.UTF8, "application/json"));
        }
        public async Task<ThreadRun> GetThreadRun(string threadId, string runId)
        {
            return await SendRequest<ThreadRun>($"/threads/{threadId}/runs/{runId}", HttpMethod.Get);
        }
        public async Task<List<Message>> ListThreadMessages(string threadId)
        {
            var result = await SendRequest<AOAIResponse<Message>>($"/threads/{threadId}/messages", HttpMethod.Get);
            return result.Data;
        }

        private async Task<T> SendRequest<T>(string path, HttpMethod method, StringContent body = null)
        {
            var url = "/openai" + path + "?api-version=2024-01-01-preview";
            Console.WriteLine(url);

            var request = new HttpRequestMessage(method, url)
            {
                Headers =
                {
                    { "api-key", _accessKey },
                },
                Content = body
            };

            var response = await _httpClient.SendAsync(request, default);
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
                throw new Exception(responseContent);

            Console.WriteLine(responseContent);
            var content = JsonSerializer.Deserialize<T>(responseContent);
            return content;
        }


    }
}
