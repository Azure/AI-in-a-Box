// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Planning;
using Microsoft.SemanticKernel.Planning.Stepwise;

namespace Microsoft.BotBuilderSamples
{
    public class StateManagementBot : ActivityHandler
    {
        private BotState _conversationState;
        private BotState _userState;

        public StateManagementBot(ConversationState conversationState, UserState userState)
        {
            _conversationState = conversationState;
            _userState = userState;
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
            // Get the state properties from the turn context.

            var conversationStateAccessors = _conversationState.CreateProperty<ConversationData>(nameof(ConversationData));
            var conversationData = await conversationStateAccessors.GetAsync(turnContext, () => new ConversationData());

            var userStateAccessors = _userState.CreateProperty<UserProfile>(nameof(UserProfile));
            var userProfile = await userStateAccessors.GetAsync(turnContext, () => new UserProfile());

            conversationData.History.Add(new ConversationTurn { Role = "user", Message = turnContext.Activity.Text });
            

            var replyText = await ProcessMessage(conversationData, turnContext);

            await turnContext.SendActivityAsync(replyText);
            conversationData.History.Add(new ConversationTurn { Role = "assistant", Message = replyText });
        }

        public virtual async Task<string> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext) {
            await turnContext.SendActivityAsync(JsonSerializer.Serialize(conversationData.History));
            return $"This chat now contains {conversationData.History.Count} messages";
        }
    }
}
