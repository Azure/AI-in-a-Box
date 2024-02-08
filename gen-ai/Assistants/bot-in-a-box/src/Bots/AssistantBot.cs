// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.Encodings.Web;
using System.Net.Http;
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
    public class AssistantBot<T> : StateManagementBot<T> where T : Dialog
    {
        private Kernel kernel;
        private string _aoaiModel;
        private string _aoaiAssistant;
        private readonly AOAIClient _aoaiClient;
        private readonly string _welcomeMessage;
        private readonly List<string> _suggestedQuestions;
        private readonly string _searchSemanticConfig;
        private HttpClient client = new HttpClient();

        public AssistantBot(
            IConfiguration config,
            ConversationState conversationState,
            UserState userState,
            AOAIClient aoaiClient,
            T dialog) :
            base(config, conversationState, userState, dialog)
        {
            _aoaiModel = config.GetValue<string>("AOAI_GPT_MODEL");
            _aoaiAssistant = config.GetValue<string>("AOAI_ASSISTANT_ID");
            _welcomeMessage = config.GetValue<string>("PROMPT_WELCOME_MESSAGE");
            _systemMessage = config.GetValue<string>("PROMPT_SYSTEM_MESSAGE");
            _suggestedQuestions = System.Text.Json.JsonSerializer.Deserialize<List<string>>(config.GetValue<string>("PROMPT_SUGGESTED_QUESTIONS"));
            _aoaiClient = aoaiClient;
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
                // await turnContext.SendActivityAsync("No thread found - opening a new one for you.");
                var thread = await _aoaiClient.CreateThread();
                conversationData.ThreadId = thread.Id;
                // await turnContext.SendActivityAsync($"Thread started: {thread.Id}");
            }
            else
            {
                // await turnContext.SendActivityAsync($"Thread found: {conversationData.ThreadId}");
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
            await _aoaiClient.SendMessage(conversationData.ThreadId, new MessageInput
            {
                Role = "user",
                Content = turnContext.Activity.Text
            });

            // Run thread
            var run = await _aoaiClient.CreateThreadRun(conversationData.ThreadId, new ThreadRunInput
            {
                AssistantId = _aoaiAssistant,
                Instructions = _systemMessage
            });

            // Wait until run completes
            while (run.Status != "completed")
            {
                Console.WriteLine(JsonSerializer.Serialize(run));
                if (run.Status == "requires_action")
                {
                    if (run.RequiredAction.SubmitToolOutputs.ToolCalls.First().Function.Name == "get_wikipedia_content")
                    {
                        var arguments = System.Text.Json.JsonSerializer.Deserialize<GetWikipediaContentArguments>(run.RequiredAction.SubmitToolOutputs.ToolCalls.First().Function.Arguments);
                        var content = await GetWikipediaContent(conversationData, turnContext, arguments.PageTitle);
                        await _aoaiClient.SubmitToolOutputs(conversationData.ThreadId, run.Id, new ToolOutputData(){
                            ToolOutputs = new List<ToolOutput>{ 
                                new ToolOutput { 
                                    ToolCallId = run.RequiredAction.SubmitToolOutputs.ToolCalls.First().Id,
                                    Output = content
                                } 
                            }
                        });
                    }
                    if (run.RequiredAction.SubmitToolOutputs.ToolCalls.First().Function.Name == "query_wikipedia")
                    {
                        var arguments = System.Text.Json.JsonSerializer.Deserialize<QueryWikipediaArguments>(run.RequiredAction.SubmitToolOutputs.ToolCalls.First().Function.Arguments);
                        var content = await QueryWikipedia(conversationData, turnContext, arguments.Query);
                        await _aoaiClient.SubmitToolOutputs(conversationData.ThreadId, run.Id, new ToolOutputData(){
                            ToolOutputs = new List<ToolOutput>{ 
                                new ToolOutput { 
                                    ToolCallId = run.RequiredAction.SubmitToolOutputs.ToolCalls.First().Id,
                                    Output = content
                                } 
                            }
                        });
                    }
                }
                // await turnContext.SendActivityAsync($"The assistant is running...");
                System.Threading.Thread.Sleep(10000);
                run = await _aoaiClient.GetThreadRun(conversationData.ThreadId, run.Id);
            }

            // Send back first message
            var messages = await _aoaiClient.ListThreadMessages(conversationData.ThreadId);
            return messages.First().Content.First().Text.Value;
        }
        public async Task<string> QueryWikipedia(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, string query)
        {
            await turnContext.SendActivityAsync($"Searching Wikipedia for \"{query}\"...");
            HttpResponseMessage response = await client.GetAsync(
                $"https://en.wikipedia.org/w/api.php?action=opensearch&search={UrlEncoder.Default.Encode(query)}&limit=1"
            );
            if (response.IsSuccessStatusCode)
                return await response.Content.ReadAsStringAsync();
            else 
                return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";
        }
        public async Task<string> GetWikipediaContent(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, string pageTitle)
        {
            await turnContext.SendActivityAsync($"Getting article \"{pageTitle}\"...");
            HttpResponseMessage response = await client.GetAsync(
                $"https://en.wikipedia.org/w/api.php?action=query&format=json&titles={UrlEncoder.Default.Encode(pageTitle)}&prop=extracts&explaintext"
            );
            if (response.IsSuccessStatusCode)
                return await response.Content.ReadAsStringAsync();
            else
                return $"FAILED TO FETCH DATA FROM API. STATUS CODE {response.StatusCode}";

        }

        class QueryWikipediaArguments
        {
            [JsonPropertyName("query")]
            public string Query { get; set; }
        }
        class GetWikipediaContentArguments
        {
            [JsonPropertyName("page_title")]
            public string PageTitle { get; set; }
        }
    }
}