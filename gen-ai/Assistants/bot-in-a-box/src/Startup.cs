// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Azure;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Connector.Authentication;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;
using Services;

namespace Microsoft.BotBuilderSamples
{
    public class Startup
    {
        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            var configuration = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json", optional: true)
                .AddEnvironmentVariables()
                .Build();
            services.AddSingleton(configuration);

            services.AddHttpClient<DirectLineService>();

            DefaultAzureCredential azureCredentials;
            if (configuration.GetValue<string>("MicrosoftAppType") == "UserAssignedMSI")
                azureCredentials = new DefaultAzureCredential(new DefaultAzureCredentialOptions() { ManagedIdentityClientId = configuration.GetValue<string>("MicrosoftAppId") });
            else
                azureCredentials = new DefaultAzureCredential();
            services.AddHttpClient().AddControllers().AddNewtonsoftJson(options =>
            {
                options.SerializerSettings.MaxDepth = HttpHelper.BotMessageSerializerSettings.MaxDepth;
            });

            // Create the Bot Framework Authentication to be used with the Bot Adapter.
            services.AddSingleton<BotFrameworkAuthentication, ConfigurationBotFrameworkAuthentication>();

            // Create the Bot Adapter with error handling enabled.
            services.AddSingleton<IBotFrameworkHttpAdapter, AdapterWithErrorHandler>();

            IStorage storage;
            if (configuration.GetValue<string>("COSMOS_API_ENDPOINT") != null)
            {
                var cosmosDbStorageOptions = new CosmosDbPartitionedStorageOptions()
                {
                    CosmosDbEndpoint = configuration.GetValue<string>("COSMOS_API_ENDPOINT"),
                    TokenCredential = azureCredentials,
                    DatabaseId = "AssistantBot",
                    ContainerId = "Conversations"
                };
                storage = new CosmosDbPartitionedStorage(cosmosDbStorageOptions);
            }
            else
            {
                storage = new MemoryStorage();
            }


            // Create the User state passing in the storage layer.
            var userState = new UserState(storage);
            services.AddSingleton(userState);

            // Create the Conversation state passing in the storage layer.
            var conversationState = new ConversationState(storage);
            services.AddSingleton(conversationState);
            services.AddSingleton(new AOAIClient(new System.Net.Http.HttpClient(), new Uri(configuration.GetValue<string>("AOAI_API_ENDPOINT")), configuration.GetValue<string>("AOAI_API_KEY")));
            services.AddHttpClient();
            if (configuration.GetValue<string>("SPEECH_API_ENDPOINT") != null)
                services.AddSingleton(new SpeechService(new System.Net.Http.HttpClient(), configuration.GetValue<string>("SPEECH_API_ENDPOINT"), configuration.GetValue<string>("SPEECH_API_KEY")));
            // Create the bot as a transient. In this case the ASP Controller is expecting an IBot.
            // services.AddSingleton<LoginDialog>();
            services.AddSingleton<LoginDialog>();
            services.AddTransient<IBot, AssistantBot<LoginDialog>>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseDefaultFiles()
                .UseStaticFiles()
                .UseRouting()
                .UseAuthorization()
                .UseEndpoints(endpoints =>
                {
                    endpoints.MapControllers();
                });

            // app.UseHttpsRedirection();
        }
    }
}
