// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Text.Json;
using System.Net.Http;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Services;
using Models;
using System.IO;


namespace Microsoft.BotBuilderSamples
{
    public class AssistantBot<T> : StateManagementBot<T> where T : Dialog
    {
        private readonly IConfiguration _config;
        private string _aoaiAssistant;
        private readonly AOAIClient _aoaiClient;
        private readonly string _welcomeMessage;
        private readonly List<string> _suggestedQuestions;
        private readonly string _appUrl;

        public AssistantBot(
            IConfiguration config,
            ConversationState conversationState,
            UserState userState,
            AOAIClient aoaiClient,
            T dialog) :
            base(config, conversationState, userState, dialog)
        {
            _config = config;
            _aoaiAssistant = config.GetValue<string>("AOAI_ASSISTANT_ID");
            _welcomeMessage = config.GetValue<string>("PROMPT_WELCOME_MESSAGE");
            _systemMessage = config.GetValue<string>("PROMPT_SYSTEM_MESSAGE");
            _suggestedQuestions = JsonSerializer.Deserialize<List<string>>(config.GetValue<string>("PROMPT_SUGGESTED_QUESTIONS"));
            _aoaiClient = aoaiClient;
            _appUrl = config.GetValue("APP_URL", "http://localhost:3978");
            if (!_appUrl.StartsWith("http"))
            {
                _appUrl = $"https://{_appUrl}";
            }
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
                    if (!attachment.ContentUrl.IsNullOrEmpty())
                        await IngestAttachment(conversationData, turnContext, attachment);

            if (turnContext.Activity.Text.IsNullOrEmpty())
                return new List<string>() { "1" };

            // Process keywords
            if (turnContext.Activity.Text.ToLower() == "clear")
            {
                var thread = await _aoaiClient.DeleteThread(conversationData.ThreadId);
                conversationData.ThreadId = null;
                conversationData.History.Clear();
                conversationData.Attachments.Clear();
                await turnContext.SendActivityAsync($"Thread deleted: {thread.Id}");
                return new List<string>() { $"Thread deleted: {thread.Id}" };
            }

            // Add user message to thread
            await _aoaiClient.SendMessage(conversationData.ThreadId, new MessageInput
            {
                Role = "user",
                Content = turnContext.Activity.Text
            });

            // Run thread
            Console.WriteLine("Running thread...");
            var outputStream = await _aoaiClient.CreateThreadRun(conversationData.ThreadId, new ThreadRunInput
            {
                AssistantId = _aoaiAssistant,
                Instructions = _systemMessage,
                Stream = true
            });
            // Listen to stream events
            var responses = new List<string>();
            var messageBuffer = new List<string>() { "Generating response..." };
            var messageId = "";
            var done = false;
            var reader = new StreamReader(outputStream);
            while (!done)
            {
                string eventLine = null;
                string dataLine = null;
                while (eventLine == null || dataLine == null)
                {
                    if (!reader.EndOfStream)
                    {
                        string line = await reader.ReadLineAsync();
                        if (line.StartsWith("event:"))
                        {
                            eventLine = line;
                        }
                        else if (line.StartsWith("data:"))
                        {
                            dataLine = line;
                        }
                    }
                    else
                    {
                        await Task.Delay(100); // Wait for 100 milliseconds before checking again
                    }
                }


                switch (eventLine)
                {
                    case "event: thread.run.created":
                        if (ChannelSupportsStreaming(turnContext))
                        {
                            var response = await turnContext.SendActivityAsync(string.Join("", messageBuffer));
                            messageId = response.Id;
                        }
                        continue;
                    case "event: thread.run.queued":
                        continue;
                    case "event: thread.run.in_progress":
                        continue;
                    case "event: thread.run.step.created":
                        continue;
                    case "event: thread.run.step.in_progress":
                        continue;
                    case "event: thread.run.step.completed":
                        continue;
                    case "event: thread.run.step.delta":
                        continue;
                    case "event: thread.message.created":
                        messageBuffer.Clear();
                        continue;
                    case "event: thread.message.in_progress":
                        continue;
                    case "event: thread.message.delta":
                        var threadMessageDelta = JsonSerializer.Deserialize<ThreadMessageDelta>(dataLine.Substring(6));
                        if (threadMessageDelta.Delta.Content[0].Type == "text")
                        {
                            messageBuffer.Add(threadMessageDelta.Delta.Content[0].Text.Value);
                            var partialMessage = MessageFactory.Text(string.Join("", messageBuffer));
                            partialMessage.Id = messageId;
                            partialMessage.InputHint = InputHints.IgnoringInput;
                            if (messageBuffer.Count % 50 == 0 && ChannelSupportsStreaming(turnContext))
                            {
                                await turnContext.UpdateActivityAsync(partialMessage);
                            }
                            else if (
                                messageBuffer.Count > 50 &&
                                threadMessageDelta.Delta.Content[0].Text.Value.Contains("\n") &&
                                string.Join("", messageBuffer).Count(s => s == '`') % 2 == 0 &&
                                !ChannelSupportsStreaming(turnContext))
                            {
                                await turnContext.SendActivityAsync(partialMessage);
                                messageBuffer.Clear();
                            }
                        }
                        if (threadMessageDelta.Delta.Content[0].Type == "image_file")
                        {
                            responses.Add($"Image (ID: {threadMessageDelta.Delta.Content[0].ImageFile.FileId})");
                            List<object> images = new() { new { type = "Image", url = $"{_appUrl}/openai/files/{threadMessageDelta.Delta.Content[0].ImageFile.FileId}/content" } };
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
                        continue;
                    case "event: thread.message.completed":
                        var completeMessage = MessageFactory.Text(string.Join("", messageBuffer));
                        completeMessage.InputHint = InputHints.AcceptingInput;
                        completeMessage.Id = messageId;
                        if (ChannelSupportsStreaming(turnContext))
                            await turnContext.UpdateActivityAsync(completeMessage);
                        else
                            await turnContext.SendActivityAsync(completeMessage);
                        continue;
                    case "event: thread.run.requires_action":
                        var threadRun = JsonSerializer.Deserialize<ThreadRun>(dataLine.Substring(6));
                        var tools = new Tools(_config, conversationData, turnContext, _aoaiClient);
                        var submitData = await tools.RunRequestedTools(threadRun);
                        outputStream = await _aoaiClient.SubmitToolOutputs(conversationData.ThreadId, threadRun.Id, submitData);
                        reader = new StreamReader(outputStream);
                        continue;
                    case "event: thread.run.failed":
                        threadRun = JsonSerializer.Deserialize<ThreadRun>(dataLine.Substring(6));
                        await turnContext.SendActivityAsync(threadRun.LastError.Message);
                        done = true;
                        break;
                    default:
                        done = true;
                        break;
                }
            }
            return responses;
        }

        private bool ChannelSupportsStreaming(ITurnContext<IMessageActivity> turnContext)
        {
            return turnContext.Activity.ChannelId == "msteams" ||
                   turnContext.Activity.ChannelId == "slack";
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
                FileIds = new List<string>() { file.Id }
            });
            stream.Dispose();
            await turnContext.SendActivityAsync($"File {attachment.Name} uploaded successfully!");
        }
    }
}