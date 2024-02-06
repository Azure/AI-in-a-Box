// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.Search.Documents;
using Azure.Storage.Blobs;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Services;
using Models;
using Microsoft.Kiota.Abstractions;

namespace Microsoft.BotBuilderSamples
{
    public class AssistantBot<T> : DocumentUploadBot<T> where T : Dialog
    {
        private Kernel kernel;
        private string _aoaiModel;
        private string _aoaiAssistant;
        private readonly AOAIClient _aoaiClient;
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

        public AssistantBot(
            IConfiguration config,
            ConversationState conversationState,
            UserState userState,
            AOAIClient aoaiClient,
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
            _aoaiAssistant = config.GetValue<string>("AOAI_ASSISTANT_ID");
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
            if (conversationData.ThreadId.IsNullOrEmpty())
            {
                await turnContext.SendActivityAsync("No thread found - opening a new one for you.");
                var thread = await _aoaiClient.CreateThread();
                conversationData.ThreadId = thread.Id;
                await turnContext.SendActivityAsync($"Thread started: {thread.Id}");
            }
            else
            {
                await turnContext.SendActivityAsync($"Thread found: {conversationData.ThreadId}");
            }

            if (turnContext.Activity.Text.ToLower() == "clear")
            {
                var thread = await _aoaiClient.DeleteThread(conversationData.ThreadId);
                conversationData.ThreadId = null;
                conversationData.History.Clear();
                conversationData.Attachments.Clear();
                return $"Thread {thread.Id} deleted.";
            }

            // Add user message to thread
            await _aoaiClient.SendMessage(conversationData.ThreadId, new MessageInput{
                Role = "user",
                Content = turnContext.Activity.Text
            });

            // Run thread
            var run = await _aoaiClient.CreateThreadRun(conversationData.ThreadId, new ThreadRunInput{
                AssistantId = _aoaiAssistant,
                Instructions = _systemMessage
            });

            // Wait until run completes
            while (run.Status != "completed") {
                await turnContext.SendActivityAsync($"The assistant is running...");
                System.Threading.Thread.Sleep(10000);
                run = await _aoaiClient.GetThreadRun(conversationData.ThreadId, run.Id);
            }

            // Send back first message
            var messages = await _aoaiClient.ListThreadMessages(conversationData.ThreadId);
            return messages.First().Content.First().Text.Value;
        }
    }

}
