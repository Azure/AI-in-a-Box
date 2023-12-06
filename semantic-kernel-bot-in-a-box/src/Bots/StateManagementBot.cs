// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;

namespace Microsoft.BotBuilderSamples
{
    public class StateManagementBot : ActivityHandler
    {
        public readonly BotState _conversationState;
        public readonly BotState _userState;
        private int _max_messages;
        private int _max_attachments;

        public StateManagementBot(IConfiguration config, ConversationState conversationState, UserState userState)
        {
            _conversationState = conversationState;
            _userState = userState;
            _max_messages = config.GetValue<int?>("CONVERSATION_HISTORY_MAX_MESSAGES") ?? 10;
            _max_attachments = config.GetValue<int?>("MAX_ATTACHMENTS") ?? 5;
        }

        public override async Task OnTurnAsync(ITurnContext turnContext, CancellationToken cancellationToken = default(CancellationToken))
        {
            await base.OnTurnAsync(turnContext, cancellationToken);
            // Save any state changes that might have occurred during the turn.
            await _conversationState.SaveChangesAsync(turnContext, false, cancellationToken);
            await _userState.SaveChangesAsync(turnContext, false, cancellationToken);
        }

        protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
        {
            await turnContext.SendActivityAsync("Welcome to State Bot Sample. Type anything to get started.");
        }

        protected override async Task OnMessageActivityAsync(ITurnContext<IMessageActivity> turnContext, CancellationToken cancellationToken)
        {
            
            var conversationStateAccessors = _conversationState.CreateProperty<ConversationData>(nameof(ConversationData));
            var conversationData = await conversationStateAccessors.GetAsync(turnContext, () => new ConversationData());


            var userStateAccessors = _userState.CreateProperty<UserProfile>(nameof(UserProfile));
            var userProfile = await userStateAccessors.GetAsync(turnContext, () => new UserProfile());

            // -- Special keywords
            // Clear conversation
            if (turnContext.Activity.Text != null && turnContext.Activity.Text.ToLower() == "clear") {
                conversationData.History.Clear();
                conversationData.Attachments.Clear();
                await turnContext.SendActivityAsync("Conversation context cleared");
                return;
            }
            conversationData.History.Add(new ConversationTurn { Role = "user", Message = turnContext.Activity.Text });

            var replyText = await ProcessMessage(conversationData, turnContext);


            conversationData.History.Add(new ConversationTurn { Role = "assistant", Message = replyText });
            
            if (turnContext.Activity.Text == null || turnContext.Activity.Text.ToLower() == "") {
                return;
            }
            
            await turnContext.SendActivityAsync(replyText);

            conversationData.History = conversationData.History.GetRange(
                Math.Max(conversationData.History.Count - _max_messages, 0), 
                Math.Min(conversationData.History.Count, _max_messages)
            );
            conversationData.Attachments = conversationData.Attachments.GetRange(
                Math.Max(conversationData.Attachments.Count - _max_attachments, 0), 
                Math.Min(conversationData.Attachments.Count, _max_attachments)
            );

        }

        public virtual async Task<string> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext) {
            await turnContext.SendActivityAsync(JsonSerializer.Serialize(conversationData.History));
            return $"This chat now contains {conversationData.History.Count} messages";
        }

        public string FormatConversationHistory(ConversationData conversationData) {
            string history = "";
            List<ConversationTurn> latestMessages = conversationData.History.GetRange(
                Math.Max(conversationData.History.Count - _max_messages, 0), 
                Math.Min(conversationData.History.Count, _max_messages)
            );
            foreach (ConversationTurn conversationTurn in latestMessages)
            {
                history += $"{conversationTurn.Role.ToUpper()}:\n{conversationTurn.Message}\n";
            }
            history += "ASSISTANT:";
            return history;
        }
    }
}
