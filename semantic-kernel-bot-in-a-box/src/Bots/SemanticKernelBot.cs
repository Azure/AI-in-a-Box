// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.AI.OpenAI;
using Azure.Search.Documents;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.AI.OpenAI.TextEmbedding;
using Microsoft.SemanticKernel.Planners;
using Models;
using Newtonsoft.Json;
using Plugins;
using Services;

namespace Microsoft.BotBuilderSamples
{
    public class SemanticKernelBot : DocumentUploadBot
    {
        private IKernel kernel;
        private string _aoaiModel;
        private StepwisePlanner _planner;
        private ILoggerFactory loggerFactory;
        private readonly IConfiguration _config;
        private readonly OpenAIClient _aoaiClient;
        private readonly BingClient _bingClient;
        private readonly SearchClient _searchClient;
        private readonly AzureOpenAITextEmbeddingGeneration _embeddingsClient;
        private readonly DocumentAnalysisClient _documentAnalysisClient;
        private readonly SqlConnectionFactory _sqlConnectionFactory;
        private readonly string _welcomeMessage;
        private readonly List<string> _suggestedQuestions;
        private readonly string _systemMessage;

        public SemanticKernelBot(
            IConfiguration config,
            ConversationState conversationState,
            UserState userState,
            OpenAIClient aoaiClient,
            AzureOpenAITextEmbeddingGeneration embeddingsClient,
            DocumentAnalysisClient documentAnalysisClient = null,
            SearchClient searchClient = null,
            BingClient bingClient = null,
            SqlConnectionFactory sqlConnectionFactory = null) : 
            base(config, conversationState, userState, embeddingsClient, documentAnalysisClient)
        {
            _aoaiModel = config.GetValue<string>("AOAI_GPT_MODEL");
            _welcomeMessage = config.GetValue<string>("PROMPT_WELCOME_MESSAGE");
            _suggestedQuestions = System.Text.Json.JsonSerializer.Deserialize<List<string>>(config.GetValue<string>("PROMPT_SUGGESTED_QUESTIONS"));
            _systemMessage = new StreamReader("./PromptConfig/StepwiseStepPrompt.json")
                .ReadToEnd()
                .Replace("{{PROMPT_SYSTEM_MESSAGE}}", config.GetValue<string>("PROMPT_SYSTEM_MESSAGE"));

            _aoaiClient = aoaiClient;
            _searchClient = searchClient;
            _bingClient = bingClient;
            _embeddingsClient = embeddingsClient;
            _documentAnalysisClient = documentAnalysisClient;
            _sqlConnectionFactory = sqlConnectionFactory;

            _config = config;
        }

        private IKernel GetKernel(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
        {

            loggerFactory = LoggerFactory.Create(builder =>
            {
                builder
                    .SetMinimumLevel(LogLevel.Information)
                    .AddConsole()
                    .AddDebug();
            });

            kernel = new KernelBuilder()
                    .WithAzureOpenAIChatCompletionService(
                        deploymentName: _aoaiModel,
                        _aoaiClient
                    )
                    .WithLoggerFactory(loggerFactory)
                    .WithRetryBasic()
                    .Build();

            if (_sqlConnectionFactory != null) kernel.ImportFunctions(new SQLPlugin(conversationData, turnContext, _sqlConnectionFactory), "SQLPlugin");
            if (_documentAnalysisClient != null) kernel.ImportFunctions(new UploadPlugin(conversationData, turnContext, _embeddingsClient), "UploadPlugin");
            if (_searchClient != null) kernel.ImportFunctions(new HotelsPlugin(conversationData, turnContext, _searchClient), "HotelsPlugin");
            kernel.ImportFunctions(new DALLEPlugin(conversationData, turnContext, _aoaiClient), "DALLEPlugin");
            if (_bingClient != null) kernel.ImportFunctions(new BingPlugin(conversationData, turnContext, _bingClient), "BingPlugin");
            return kernel;
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

            kernel = GetKernel(conversationData, turnContext);

            var stepwiseConfig = new StepwisePlannerConfig
            {
                GetPromptTemplate = () => _systemMessage,
                MaxIterations = 5,
                MaxTokens = 8000,
            };
            _planner = new StepwisePlanner(kernel, stepwiseConfig);
            string prompt = FormatConversationHistory(conversationData);
            var plan = _planner.CreatePlan(prompt);

            var res = await kernel.RunAsync(plan);

            var stepsTaken = JsonConvert.DeserializeObject<Step[]>(res.FunctionResults.First().Metadata["stepsTaken"].ToString());

            return stepsTaken[stepsTaken.Length - 1].final_answer;
        }
    }
}
