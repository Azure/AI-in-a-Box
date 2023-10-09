// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Threading.Tasks;
using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;

namespace Microsoft.BotBuilderSamples
{
    public class SimpleGPTBot : StateManagementBot
    {
        private string _aoaiModel;
        private OpenAIClient _client;

        public SimpleGPTBot(ConversationState conversationState, UserState userState) : base(conversationState, userState)
        {
            var _aoaiApiKey = Environment.GetEnvironmentVariable("AOAI_API_KEY");
            var _aoaiApiEndpoint = Environment.GetEnvironmentVariable("AOAI_API_ENDPOINT");
            _aoaiModel = Environment.GetEnvironmentVariable("AOAI_MODEL");

            var uri = new Uri(_aoaiApiEndpoint);

            _client = _aoaiApiKey == null
                ? new OpenAIClient(uri, new DefaultAzureCredential()) :
                new OpenAIClient(uri, new AzureKeyCredential(_aoaiApiKey));
        }

        protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
        {
            await turnContext.SendActivityAsync("Welcome to GPTBot Sample. Type anything to get started.");
        }

        public override async Task<string> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
        {
            var chatCompletionsOptions = new ChatCompletionsOptions();
            foreach (ConversationTurn conversationTurn in conversationData.History)
            {
                chatCompletionsOptions.Messages.Add(
                    new(
                        conversationTurn.Role == "user" ? ChatRole.User : ChatRole.Assistant, 
                        conversationTurn.Message
                    )
                );
            }
            Response<ChatCompletions> response = await _client.GetChatCompletionsAsync(_aoaiModel, chatCompletionsOptions);
            return response.Value.Choices[0].Message.Content;
        }

    }
}
