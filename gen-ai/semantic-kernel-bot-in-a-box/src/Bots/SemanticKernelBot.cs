// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.AI.OpenAI;
using Azure.Search.Documents;
using Azure.Storage.Blobs;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Microsoft.SemanticKernel.Planning;
using Microsoft.SemanticKernel.Planning.Handlebars;
using Plugins;
using Services;

namespace Microsoft.BotBuilderSamples
{
    public class SemanticKernelBot<T> : DocumentUploadBot<T> where T : Dialog
    {
        private Kernel kernel;
        private string _aoaiModel;
        private readonly OpenAIClient _aoaiClient;
        private readonly BingClient _bingClient;
        private readonly SearchClient _searchClient;
        private readonly BlobServiceClient _blobServiceClient;
        private readonly AzureOpenAITextEmbeddingGenerationService _embeddingsClient;
        private readonly DocumentAnalysisClient _documentAnalysisClient;
        private readonly SqlConnectionFactory _sqlConnectionFactory;
        private readonly string _welcomeMessage;
        private readonly List<string> _suggestedQuestions;
        private readonly bool _useStepwisePlanner;
        private readonly string _searchSemanticConfig;

        public SemanticKernelBot(
            IConfiguration config,
            ConversationState conversationState,
            UserState userState,
            OpenAIClient aoaiClient,
            AzureOpenAITextEmbeddingGenerationService embeddingsClient,
            T dialog,
            DocumentAnalysisClient documentAnalysisClient = null,
            SearchClient searchClient = null,
            BlobServiceClient blobServiceClient = null,
            BingClient bingClient = null,
            SqlConnectionFactory sqlConnectionFactory = null) :
            base(config, conversationState, userState, embeddingsClient, documentAnalysisClient, dialog)
        {
            _aoaiModel = config.GetValue<string>("AOAI_GPT_MODEL");
            _welcomeMessage = config.GetValue<string>("PROMPT_WELCOME_MESSAGE");
            _systemMessage = config.GetValue<string>("PROMPT_SYSTEM_MESSAGE");
            _suggestedQuestions = System.Text.Json.JsonSerializer.Deserialize<List<string>>(config.GetValue<string>("PROMPT_SUGGESTED_QUESTIONS"));
            _useStepwisePlanner = config.GetValue<bool>("USE_STEPWISE_PLANNER");
            _searchSemanticConfig = config.GetValue<string>("SEARCH_SEMANTIC_CONFIG");
            _aoaiClient = aoaiClient;
            _searchClient = searchClient;
            _blobServiceClient = blobServiceClient;
            _bingClient = bingClient;
            _embeddingsClient = embeddingsClient;
            _documentAnalysisClient = documentAnalysisClient;
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
        {
            await turnContext.SendActivityAsync(new Activity()
            {
                Type = "message",
                Text = _welcomeMessage,
                SuggestedActions = new SuggestedActions()
                {
                    Actions = _suggestedQuestions
                        .Select(value => new CardAction(type: "postBack", value: value))
                        .ToList()
                }
            });
        }

        public override async Task<string> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
        {

            await turnContext.SendActivityAsync(new Activity(type: "typing"));

            await HandleFileUploads(conversationData, turnContext);
            if (turnContext.Activity.Text.IsNullOrEmpty())
                return "";

            kernel = Kernel.CreateBuilder()
                    .AddAzureOpenAIChatCompletion(
                        deploymentName: _aoaiModel,
                        _aoaiClient
                    )
                    .Build();

            if (_sqlConnectionFactory != null) kernel.ImportPluginFromObject(new SQLPlugin(conversationData, turnContext, _sqlConnectionFactory), "SQLPlugin");
            if (_documentAnalysisClient != null) kernel.ImportPluginFromObject(new UploadPlugin(conversationData, turnContext, _embeddingsClient), "UploadPlugin");
            if (_searchClient != null) kernel.ImportPluginFromObject(new HRHandbookPlugin(conversationData, turnContext, _embeddingsClient, _searchClient, _blobServiceClient, _searchSemanticConfig), "HRHandbookPlugin");
            kernel.ImportPluginFromObject(new DALLEPlugin(conversationData, turnContext, _aoaiClient), "DALLEPlugin");
            if (_bingClient != null) kernel.ImportPluginFromObject(new BingPlugin(conversationData, turnContext, _bingClient), "BingPlugin");
            if (!_useStepwisePlanner) kernel.ImportPluginFromObject(new HumanInterfacePlugin(conversationData, turnContext, _aoaiClient), "HumanInterfacePlugin");

            if (_useStepwisePlanner)
            {
                var plannerOptions = new FunctionCallingStepwisePlannerConfig
                {
                    MaxTokens = 128000,
                };

                var planner = new FunctionCallingStepwisePlanner(plannerOptions);
                string prompt = FormatConversationHistory(conversationData);
                var result = await planner.ExecuteAsync(kernel, prompt);

                return result.FinalAnswer;
            }
            else
            {
                var plannerOptions = new HandlebarsPlannerOptions
                {
                    MaxTokens = 128000,
                };

                var planner = new HandlebarsPlanner(plannerOptions);
                string prompt = FormatConversationHistory(conversationData);
                var plan = await planner.CreatePlanAsync(kernel, prompt);
                var result = await plan.InvokeAsync(kernel, default);
                return result;
            }
        }
    }

}
