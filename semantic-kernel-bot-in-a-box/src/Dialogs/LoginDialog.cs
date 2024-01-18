// <copyright file="LoginDialog.cs" company="Microsoft">
// Copyright (c) Microsoft. All rights reserved.
// </copyright>

using System.Threading;
using System.Threading.Tasks;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Configuration;

namespace Microsoft.BotBuilderSamples
{
    public class LoginDialog : ComponentDialog
    {
        public readonly BotState _conversationState;
        public readonly string _login_successful_message;
        public readonly string _login_failed_message;
        public LoginDialog(IConfiguration configuration)
            : base(nameof(LoginDialog))
        {
            _login_successful_message = configuration.GetValue<string?>("SSO_MESSAGE_SUCCESS");
            _login_failed_message = configuration.GetValue<string?>("SSO_MESSAGE_FAILED");
            AddDialog(new OAuthPrompt(
                nameof(OAuthPrompt),
                new OAuthPromptSettings
                {
                    ConnectionName = configuration.GetValue<string>("SSO_CONFIG_NAME"),
                    Text = configuration.GetValue<string>("SSO_MESSAGE_TITLE"),
                    Title = configuration.GetValue<string>("SSO_MESSAGE_PROMPT"),
                    Timeout = 300000, // User has 5 minutes to login (1000 * 60 * 5)
                    EndOnInvalidMessage = true
                }));


            AddDialog(new WaterfallDialog(nameof(WaterfallDialog), new WaterfallStep[]
            {
                PromptStepAsync,
                LoginStepAsync
            }));

            // The initial child Dialog to run.
            InitialDialogId = nameof(WaterfallDialog);
        }

        private async Task<DialogTurnResult> PromptStepAsync(WaterfallStepContext stepContext, CancellationToken cancellationToken)
        {
            return await stepContext.BeginDialogAsync(nameof(OAuthPrompt), null, cancellationToken);
        }

        private async Task<DialogTurnResult> LoginStepAsync(WaterfallStepContext stepContext, CancellationToken cancellationToken)
        {
            // Get the token from the previous step.
            var tokenResponse = (TokenResponse)stepContext.Result;
            if (tokenResponse?.Token != null)
            {
                try
                {
                    await stepContext.Context.SendActivityAsync(_login_successful_message);
                    return await stepContext.EndDialogAsync(cancellationToken: cancellationToken);
                }
                catch { }

            }

            await stepContext.Context.SendActivityAsync(_login_failed_message);
            return await stepContext.EndDialogAsync(cancellationToken: cancellationToken);
        }
    }
}