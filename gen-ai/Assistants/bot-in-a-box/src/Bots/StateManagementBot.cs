// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Builder.Teams;
using Microsoft.Bot.Connector.Authentication;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;

namespace Microsoft.BotBuilderSamples
{
    public class StateManagementBot<T> : TeamsActivityHandler where T : Dialog
    {
        public readonly BotState _conversationState;
        public readonly BotState _userState;
        protected readonly Dialog _dialog;
        private int _max_messages;
        private int _max_attachments;
        public string _systemMessage;
        public bool _sso_enabled;
        public string _sso_config_name;

        public StateManagementBot(IConfiguration config, ConversationState conversationState, UserState userState, T dialog)
        {
            _conversationState = conversationState;
            _userState = userState;
            _dialog = dialog;
            _max_messages = config.GetValue("CONVERSATION_HISTORY_MAX_MESSAGES", 10);
            _max_attachments = config.GetValue("MAX_ATTACHMENTS", 5);
            _sso_enabled = config.GetValue("SSO_ENABLED", false);
            _sso_config_name = config.GetValue("SSO_CONFIG_NAME", "default");
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

            var userTokenClient = turnContext.TurnState.Get<UserTokenClient>();

            // -- Special keywords
            // Clear conversation
            if (turnContext.Activity.Text != null)
            {
                if (turnContext.Activity.Text.ToLower() == "logout")
                {
                    await userTokenClient.SignOutUserAsync(turnContext.Activity.From.Id, _sso_config_name, turnContext.Activity.ChannelId, cancellationToken).ConfigureAwait(false);
                    await turnContext.SendActivityAsync("Signed out");
                    return;
                }
            }

            // Log in if not already done - You can also do this within Plugins and check their claims/groups
            if (_sso_enabled)
            {
                TokenResponse userToken;
                try
                {
                    userToken = await userTokenClient.GetUserTokenAsync(turnContext.Activity.From.Id, _sso_config_name, turnContext.Activity.ChannelId, null, cancellationToken);
                    var tokenHandler = new JwtSecurityTokenHandler();
                    var securityToken = tokenHandler.ReadToken(userToken.Token) as JwtSecurityToken;
                    securityToken.Payload.TryGetValue("name", out var userName);
                    userProfile.Name = userName as string;
                }
                catch
                {
                    await _dialog.RunAsync(turnContext, _conversationState.CreateProperty<DialogState>(nameof(DialogState)), cancellationToken);
                    return;
                }
            }

            conversationData.History.Add(new ConversationTurn { Role = "user", Message = turnContext.Activity.Text });

            var replyText = await ProcessMessage(conversationData, turnContext);


            conversationData.History.Add(new ConversationTurn { Role = "assistant", Message = replyText });

            if (turnContext.Activity.Text == null || turnContext.Activity.Text.ToLower() == "")
            {
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

        public virtual async Task<string> ProcessMessage(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
        {
            await turnContext.SendActivityAsync(JsonSerializer.Serialize(conversationData.History));
            return $"This chat now contains {conversationData.History.Count} messages";
        }

        public string FormatConversationHistory(ConversationData conversationData)
        {
            string history = $"{_systemMessage} Continue the conversation acting as the ASSISTANT. Respond to the USER by using available information and functions.\n\n [CONVERSATION_HISTORY]\n";
            List<ConversationTurn> latestMessages = conversationData.History.GetRange(
                Math.Max(conversationData.History.Count - _max_messages, 0),
                Math.Min(conversationData.History.Count, _max_messages)
            );
            foreach (ConversationTurn conversationTurn in latestMessages)
            {
                history += $"{conversationTurn.Role.ToUpper()}:\n{conversationTurn.Message}\n";
            }
            history += "ASSISTANT: {{Plan response goes here}}";
            return history;
        }


        protected override async Task OnTeamsSigninVerifyStateAsync(ITurnContext<IInvokeActivity> turnContext, CancellationToken cancellationToken)
        {
            // The OAuth Prompt needs to see the Invoke Activity in order to complete the login process.
            // Run the Dialog with the new Invoke Activity.
            await _dialog.RunAsync(turnContext, _conversationState.CreateProperty<DialogState>(nameof(DialogState)), cancellationToken);
        }
    }
}
