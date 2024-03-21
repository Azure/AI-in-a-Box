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
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using HtmlAgilityPack;
using Services;
using Models;
using System.IO;


namespace Microsoft.BotBuilderSamples
{
    public class AssistantBot<T> : StateManagementBot<T> where T : Dialog
    {
        private string _aoaiAssistant;
        private readonly AOAIClient _aoaiClient;
        private readonly string _welcomeMessage;
        private readonly List<string> _suggestedQuestions;
        private readonly string _appUrl;
        private HttpClient client = new HttpClient();

        public AssistantBot(
            IConfiguration config,
            ConversationState conversationState,
            UserState userState,
            AOAIClient aoaiClient,
            T dialog) :
            base(config, conversationState, userState, dialog)
        {
            _aoaiAssistant = config.GetValue<string>("AOAI_ASSISTANT_ID");
            _welcomeMessage = config.GetValue<string>("PROMPT_WELCOME_MESSAGE");
            _systemMessage = config.GetValue<string>("PROMPT_SYSTEM_MESSAGE");
            _suggestedQuestions = JsonSerializer.Deserialize<List<string>>(config.GetValue<string>("PROMPT_SUGGESTED_QUESTIONS"));
            _aoaiClient = aoaiClient;
            _appUrl = config.GetValue("APP_URL", "http://localhost:3978");
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

        public override async Task<List<string>> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
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

            // Process any attachments

            if (!turnContext.Activity.Attachments.IsNullOrEmpty())
                foreach (Bot.Schema.Attachment attachment in turnContext.Activity.Attachments)
                    await IngestAttachment(conversationData, turnContext, attachment);

            if (turnContext.Activity.Text.IsNullOrEmpty())
                return new List<string>() {"1"};

            // Process keywords
            if (turnContext.Activity.Text.ToLower() == "clear")
            {
                var thread = await _aoaiClient.DeleteThread(conversationData.ThreadId);
                conversationData.ThreadId = null;
                conversationData.History.Clear();
                conversationData.Attachments.Clear();
                return new List<string>() { $"Thread {thread.Id} deleted." };
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
            while (run.Status != "completed" && run.Status != "failed")
            {
                if (run.Status == "requires_action")
                {
                    var tools = new Tools(conversationData, turnContext, _aoaiClient);
                    var submitData = await tools.RunRequestedTools(run);
                    await _aoaiClient.SubmitToolOutputs(conversationData.ThreadId, run.Id, submitData);
                }
                // await turnContext.SendActivityAsync($"The assistant is running...");
                System.Threading.Thread.Sleep(10000);
                run = await _aoaiClient.GetThreadRun(conversationData.ThreadId, run.Id);
            }
            if (run.Status == "failed")
            {
                await turnContext.SendActivityAsync("Something went wrong when running the assistant.");
            }

            // Send back all messages written by the assistant since the last user message
            var responses = new List<string>();
            var messages = await _aoaiClient.ListThreadMessages(conversationData.ThreadId);
            var firstAssistantMessageIndex = messages.FindIndex(x => x.Role == "user") - 1;

            for (var i = firstAssistantMessageIndex; i >= 0; i--)
            {
                for (var j = messages[i].Content.Count() - 1; j >= 0; j--)
                {
                    if (messages[i].Content[j].Type == "text")
                    {
                        responses.Add(messages[i].Content[j].Text.Value);
                        await turnContext.SendActivityAsync(messages[i].Content[j].Text.Value);
                    }
                    if (messages[i].Content[j].Type == "image_file")
                    {
                        responses.Add($"Image (ID: {messages[i].Content[j].ImageFile.FileId})");
                        List<object> images = new() { new { type = "Image", url = $"https://{_appUrl}/openai/files/{messages[i].Content[j].ImageFile.FileId}/content" } };
                        object adaptiveCardJson = new
                        {
                            type = "AdaptiveCard",
                            version = "1.0",
                            body = images
                        };

                        var adaptiveCardAttachment = new Bot.Schema.Attachment()
                        {
                            ContentType = "application/vnd.microsoft.card.adaptive",
                            Content = adaptiveCardJson,
                        };
                        await turnContext.SendActivityAsync(MessageFactory.Attachment(adaptiveCardAttachment));
                    }
                }
            }
            return responses;
        }


        private async Task IngestAttachment(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, Bot.Schema.Attachment attachment)
        {
            Uri fileUri = new Uri(attachment.ContentUrl);
            var httpClient = new HttpClient();
            var stream = await httpClient.GetStreamAsync(fileUri);
            var file = await _aoaiClient.UploadFile(stream, attachment.Name);
            await _aoaiClient.SendMessage(conversationData.ThreadId, new MessageInput()
            {
                Role = "user",
                Content = "(File uploaded)",
                FileIds = new List<string>() {file.Id}
            });
            stream.Dispose();
            await turnContext.SendActivityAsync($"File {attachment.Name} uploaded successfully!");
        }
    }
}