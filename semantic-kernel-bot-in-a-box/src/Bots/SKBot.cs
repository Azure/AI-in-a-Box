// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Azure;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Connector.Authentication;
using Microsoft.Bot.Schema;
using Microsoft.Bot.Schema.Teams;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.AI.OpenAI.TextEmbedding;
using Microsoft.SemanticKernel.Planners;
using Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Plugins;

namespace Microsoft.BotBuilderSamples
{
    public class SKBot : StateManagementBot
    {
        private IKernel kernel;
        private string _aoaiApiKey;
        private string _aoaiApiEndpoint;
        private string _aoaiModel;
        private string _docIntelApiKey;
        private string _docIntelApiEndpoint;
        private StepwisePlanner _planner;
        private ILoggerFactory loggerFactory;
        private ILoggerProvider loggerProvider;
        private bool _debug;
        private IConfiguration _config;
        private readonly AzureTextEmbeddingGeneration embeddingClient;
        private readonly DocumentAnalysisClient documentAnalysisClient;
        private readonly IHttpClientFactory _clientFactory;
        private static string microsoftAppId;
        private static string microsoftAppPassword;

        public SKBot(IHttpClientFactory clientFactory, IConfiguration config, ConversationState conversationState, UserState userState) : base(config, conversationState, userState)
        {
            _aoaiApiKey = config.GetValue<string>("AOAI_API_KEY");
            _aoaiApiEndpoint = config.GetValue<string>("AOAI_API_ENDPOINT");
            _aoaiModel = config.GetValue<string>("AOAI_MODEL");

            embeddingClient = new AzureTextEmbeddingGeneration(modelId: "text-embedding-ada-002", _aoaiApiEndpoint, _aoaiApiKey);

            _docIntelApiKey = config.GetValue<string>("DOCINTEL_API_KEY");
            _docIntelApiEndpoint = config.GetValue<string>("DOCINTEL_API_ENDPOINT");

            if (!_docIntelApiEndpoint.IsNullOrEmpty()) documentAnalysisClient = new DocumentAnalysisClient(new Uri(_docIntelApiEndpoint), new AzureKeyCredential(_docIntelApiKey));

            _debug = config.GetValue<bool>("DEBUG");
            _config = config;
            _clientFactory = clientFactory;
            microsoftAppId = config.GetValue<string>("MicrosoftAppId");
            microsoftAppPassword = config.GetValue<string>("MicrosoftAppPassword");
        }

        private IKernel GetKernel(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext) {
           
            loggerProvider = new ThoughtLoggerProvider(_debug, turnContext);
            loggerFactory = LoggerFactory.Create(builder =>
            {
                builder
                    .SetMinimumLevel(LogLevel.Information)
                    .AddProvider(loggerProvider)
                    .AddConsole()
                    .AddDebug();
            });
            
            kernel = new KernelBuilder()
                    .WithAzureChatCompletionService(
                        deploymentName: _aoaiModel,
                        endpoint: _aoaiApiEndpoint,
                        apiKey: _aoaiApiKey
                    )
                    .WithLoggerFactory(loggerFactory)
                    .Build();

            if (!_config.GetValue<string>("DOCINTEL_API_ENDPOINT").IsNullOrEmpty()) kernel.ImportFunctions(new UploadPlugin(_config, conversationData, turnContext), "UploadPlugin");
            if (!_config.GetValue<string>("SQL_CONNECTION_STRING").IsNullOrEmpty()) kernel.ImportFunctions(new SQLPlugin(_config, conversationData, turnContext), "SQLPlugin");
            if (!_config.GetValue<string>("SEARCH_API_ENDPOINT").IsNullOrEmpty()) kernel.ImportFunctions(new SearchPlugin(_config, conversationData, turnContext), "SearchPlugin");
            kernel.ImportFunctions(new DALLEPlugin(_config, conversationData, turnContext), "DALLEPlugin");
            return kernel;
        }
        protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
        {
            await turnContext.SendActivityAsync("Welcome to GPTBot Sample. Type anything to get started.");
        }

        public override async Task<string> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
        {
            // If there are PDF files attached, ingest them
            if (
                turnContext.Activity.Attachments?.Count > 0 && 
                turnContext.Activity.Attachments.Any(x => x.ContentType == "application/pdf")
            )
            {
                if (!_config.GetValue<string>("DOCINTEL_API_ENDPOINT").IsNullOrEmpty()) {
                    var textresponse = "";
                    foreach (Bot.Schema.Attachment pdfAttachment in turnContext.Activity.Attachments.Where(x => x.ContentType == "application/pdf")) {
                        textresponse += await HandleFileUpload(conversationData, pdfAttachment) + "\n";
                    }
                    return textresponse;
                }
                else
                    return "Document upload not supported as no Document Intelligence endpoint was provided";
            }

            kernel = GetKernel(conversationData, turnContext);

            var stepwiseConfig = new StepwisePlannerConfig
            {
                GetPromptTemplate = new StreamReader("./PromptConfig/StepwiseStepPrompt.json").ReadToEnd,
                MaxIterations = 15
            };
            _planner = new StepwisePlanner(kernel, stepwiseConfig);
            string prompt = FormatConversationHistory(conversationData);
            var plan = _planner.CreatePlan(prompt);

            var res = await kernel.RunAsync(plan);

            var stepsTaken = JsonConvert.DeserializeObject<Step[]>(res.FunctionResults.First().Metadata["stepsTaken"].ToString());

            return stepsTaken[stepsTaken.Length - 1].final_answer;
        }

        private async Task<string> HandleFileUpload(ConversationData conversationData, Bot.Schema.Attachment pdfAttachment)
        {
            Uri fileUri = new Uri(pdfAttachment.ContentUrl);

            var httpClient = new HttpClient();
            var stream = await httpClient.GetStreamAsync(fileUri);

            var ms = new MemoryStream();
            stream.CopyTo(ms);
            ms.Position = 0;

            var operation = await documentAnalysisClient.AnalyzeDocumentAsync(WaitUntil.Completed, "prebuilt-layout", ms);
            
            ms.Dispose();

            AnalyzeResult result = operation.Value;

            var attachment = new Attachment();
            attachment.Name = pdfAttachment.Name;
            foreach (DocumentPage page in result.Pages)
            {
                var attachmentPage = new AttachmentPage();
                attachmentPage.Content = "";
                for (int i = 0; i < page.Lines.Count; i++)
                {
                    DocumentLine line = page.Lines[i];
                    attachmentPage.Content += $"{line.Content}\n";
                }
                // Embed content
                var embedding = await embeddingClient.GenerateEmbeddingsAsync(new List<string> { attachmentPage.Content });
                attachmentPage.Vector = embedding.First().ToArray();
                attachment.Pages.Add(attachmentPage);
            }
            conversationData.Attachments.Add(attachment);

            return $"File {pdfAttachment.Name} uploaded successfully! {result.Pages.Count()} pages ingested.";
        }
    }
}
