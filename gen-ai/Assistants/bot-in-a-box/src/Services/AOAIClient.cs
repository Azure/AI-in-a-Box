using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos.Core;
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
            var result = await JsonRequest<AOAIResponse<Assistant>>("/assistants", HttpMethod.Get);
            return result.Data;
        }
        public async Task<Assistant> GetAssistant(string assistantId)
        {
            return await JsonRequest<Assistant>($"/assistants/{assistantId}", HttpMethod.Get);
        }
        public async Task<Thread> CreateThread()
        {
            return await JsonRequest<Thread>("/threads", HttpMethod.Post);
        }
        public async Task<Thread> DeleteThread(string threadId)
        {
            return await JsonRequest<Thread>($"/threads/{threadId}", HttpMethod.Delete);
        }
        public async Task<Thread> SendMessage(string threadId, MessageInput message)
        {
            return await JsonRequest<Thread>($"/threads/{threadId}/messages", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(message), Encoding.UTF8, "application/json"));
        }
        public async Task<ThreadRun> CreateThreadRun(string threadId, ThreadRunInput run)
        {
            return await JsonRequest<ThreadRun>($"/threads/{threadId}/runs", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(run), Encoding.UTF8, "application/json"));
        }
        public async Task<ThreadRun> SubmitToolOutputs(string threadId, string runId, ToolOutputData toolOutputData)
        {
            return await JsonRequest<ThreadRun>($"/threads/{threadId}/runs/{runId}/submit_tool_outputs", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(toolOutputData), Encoding.UTF8, "application/json"));
        }
        public async Task<ThreadRun> GetThreadRun(string threadId, string runId)
        {
            return await JsonRequest<ThreadRun>($"/threads/{threadId}/runs/{runId}", HttpMethod.Get);
        }
        public async Task<List<Message>> ListThreadMessages(string threadId)
        {
            var result = await JsonRequest<AOAIResponse<Message>>($"/threads/{threadId}/messages", HttpMethod.Get);
            return result.Data;
        }
        public async Task<Models.File> UploadFile(Stream file, string fileName)
        {
            MultipartFormDataContent form = new MultipartFormDataContent
            {
                { new StringContent("assistants"), "purpose" },
                { new StreamContent(file), "file", fileName }
            };
            var result = await JsonRequest<Models.File>($"/files", HttpMethod.Post, form);
            return result;
        }
        public async Task<HttpResponseMessage> GetFile(string fileId)
        {
            var result = await SendRequest($"/files/{fileId}/content", HttpMethod.Get);
            return result;
        }

        private async Task<HttpResponseMessage> SendRequest(string path, HttpMethod method, StringContent body = null)
        {
            var url = "/openai" + path + "?api-version=2024-02-15-preview";

            var request = new HttpRequestMessage(method, url)
            {
                Headers =
                {
                    { "api-key", _accessKey },
                },
                Content = body
            };
            return await _httpClient.SendAsync(request, default);
        }


        private async Task<T> JsonRequest<T>(string path, HttpMethod method, StringContent body = null)
        {
            var response = await SendRequest(path, method, body);
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
                throw new Exception(responseContent);

            var content = JsonSerializer.Deserialize<T>(responseContent);
            return content;
        }

        private async Task<HttpResponseMessage> SendRequest(string path, HttpMethod method, MultipartFormDataContent body)
        {
            var url = "/openai" + path + "?api-version=2024-02-15-preview";

            var request = new HttpRequestMessage(method, url)
            {
                Headers =
                {
                    { "api-key", _accessKey },
                },
                Content = body
            };
            return await _httpClient.SendAsync(request, default);
        }


        private async Task<T> JsonRequest<T>(string path, HttpMethod method, MultipartFormDataContent body)
        {
            var response = await SendRequest(path, method, body);
            
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
                throw new Exception(responseContent);

            var content = JsonSerializer.Deserialize<T>(responseContent);
            return content;
        }


    }
}
