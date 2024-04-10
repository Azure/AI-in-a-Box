using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.IdentityModel.Tokens;
using Models;

namespace Services
{
    public class AOAIClient
    {
        private readonly HttpClient _httpClient;
        private readonly string _accessKey;
        private readonly string _dalleDeployment;
        public AOAIClient(HttpClient httpClient, Uri uriBase, string apiKey, string dalleDeployment)
        {
            httpClient.BaseAddress = uriBase;
            _httpClient = httpClient;
            _accessKey = apiKey;
            _dalleDeployment = dalleDeployment;
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
        public async Task<ImageGenerationResult> GenerateImages(ImageGenerationInput input)
        {
            if (_dalleDeployment.IsNullOrEmpty())
                return await GenerateImagesV2(input);
            else
                return await GenerateImagesV3(_dalleDeployment, input);
        }
        public async Task<ImageGenerationResult> GenerateImagesV2(ImageGenerationInput input)
        {
            var output = await JsonRequest<ImageGenerationOutput>($"/images/generations:submit", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(input), Encoding.UTF8, "application/json"), "2023-06-01-preview");
            var response = await JsonRequest<ImageGenerationStatusResponse>($"/operations/images/{output.Id}", HttpMethod.Get, apiVersion: "2023-06-01-preview");
            while (response.Status != "succeeded") {
                response = await JsonRequest<ImageGenerationStatusResponse>($"/operations/images/{output.Id}", HttpMethod.Get, apiVersion: "2023-06-01-preview");
                System.Threading.Thread.Sleep(5000);
            }
            return response.Result;
        }
        public async Task<ImageGenerationResult> GenerateImagesV3(string deploymentId, ImageGenerationInput input)
        {
            return await JsonRequest<ImageGenerationResult>($"/deployments/{deploymentId}/images/generations", HttpMethod.Post, new StringContent(JsonSerializer.Serialize(input), Encoding.UTF8, "application/json"), "2023-12-01-preview");
        }
        private async Task<HttpResponseMessage> SendRequest(string path, HttpMethod method, StringContent body = null, string apiVersion = "2024-02-15-preview")
        {
            var url = "/openai" + path + "?api-version=" + apiVersion;

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


        private async Task<T> JsonRequest<T>(string path, HttpMethod method, StringContent body = null, string apiVersion = "2024-02-15-preview")
        {
            var response = await SendRequest(path, method, body, apiVersion);
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
                throw new Exception(responseContent);

            var content = JsonSerializer.Deserialize<T>(responseContent);
            return content;
        }

        private async Task<HttpResponseMessage> SendRequest(string path, HttpMethod method, MultipartFormDataContent body, string apiVersion = "2024-02-15-preview")
        {
            var url = "/openai" + path + "?api-version=" + apiVersion;

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


        private async Task<T> JsonRequest<T>(string path, HttpMethod method, MultipartFormDataContent body, string apiVersion = "2024-02-15-preview")
        {
            var response = await SendRequest(path, method, body, apiVersion);
            
            var responseContent = await response.Content.ReadAsStringAsync();
            if (!response.IsSuccessStatusCode)
                throw new Exception(responseContent);

            var content = JsonSerializer.Deserialize<T>(responseContent);
            return content;
        }


    }
}
