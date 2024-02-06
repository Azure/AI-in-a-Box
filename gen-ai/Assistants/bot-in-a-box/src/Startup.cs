// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using Azure;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Azure.AI.OpenAI;
using Azure.Identity;
using Azure.Search.Documents;
using Azure.Storage;
using Azure.Storage.Blobs;
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
using Microsoft.SemanticKernel.Connectors.OpenAI;
using Microsoft.WindowsAzure.Storage.Auth;
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
            services.AddSingleton(new AzureOpenAITextEmbeddingGenerationService(configuration.GetValue<string>("AOAI_EMBEDDINGS_MODEL"), configuration.GetValue<string>("AOAI_API_ENDPOINT"), configuration.GetValue<string>("AOAI_API_KEY")));
            // if (!configuration.GetValue<string>("DOCINTEL_API_ENDPOINT").IsNullOrEmpty())
            //     services.AddSingleton(new DocumentAnalysisClient(new Uri(configuration.GetValue<string>("DOCINTEL_API_ENDPOINT")), new AzureKeyCredential(configuration.GetValue<string>("DOCINTEL_API_KEY"))));
            // if (!configuration.GetValue<string>("SEARCH_API_ENDPOINT").IsNullOrEmpty())
            //     if (!configuration.GetValue<string>("SEARCH_API_KEY").IsNullOrEmpty())
            //         services.AddSingleton(new SearchClient(new Uri(configuration.GetValue<string>("SEARCH_API_ENDPOINT")), configuration.GetValue<string>("SEARCH_INDEX"), new AzureKeyCredential(configuration.GetValue<string>("SEARCH_API_KEY"))));
            //     else
            //         services.AddSingleton(new SearchClient(new Uri(configuration.GetValue<string>("SEARCH_API_ENDPOINT")), configuration.GetValue<string>("SEARCH_INDEX"), azureCredentials));
            // if (!configuration.GetValue<string>("SQL_CONNECTION_STRING").IsNullOrEmpty())
            //     services.AddSingleton(new SqlConnectionFactory(configuration.GetValue<string>("SQL_CONNECTION_STRING")));
            // if (!configuration.GetValue<string>("BING_API_ENDPOINT").IsNullOrEmpty())
            //     services.AddSingleton(new BingClient(new System.Net.Http.HttpClient(), new Uri(configuration.GetValue<string>("BING_API_ENDPOINT")), configuration.GetValue<string>("BING_API_KEY")));
            // if (!configuration.GetValue<string>("BLOB_API_ENDPOINT").IsNullOrEmpty())
            //     if (!configuration.GetValue<string>("BLOB_API_KEY").IsNullOrEmpty())
            //         services.AddSingleton(new BlobServiceClient(new Uri(configuration.GetValue<string>("BLOB_API_ENDPOINT")), new StorageSharedKeyCredential(configuration.GetValue<string>("BLOB_API_ENDPOINT").Split('/')[2].Split('.')[0], configuration.GetValue<string>("BLOB_API_KEY"))));
            //     else
            //         services.AddSingleton(new BlobServiceClient(new Uri(configuration.GetValue<string>("BLOB_API_ENDPOINT")), azureCredentials));

            services.AddHttpClient();
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
