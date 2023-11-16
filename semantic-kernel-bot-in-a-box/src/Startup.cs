// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Azure;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Connector.Authentication;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Microsoft.BotBuilderSamples
{
    public class Startup
    {
        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddHttpClient().AddControllers().AddNewtonsoftJson(options =>
            {
                options.SerializerSettings.MaxDepth = HttpHelper.BotMessageSerializerSettings.MaxDepth;
            });

            // Create the Bot Framework Authentication to be used with the Bot Adapter.
            services.AddSingleton<BotFrameworkAuthentication, ConfigurationBotFrameworkAuthentication>();

            // Create the Bot Adapter with error handling enabled.
            services.AddSingleton<IBotFrameworkHttpAdapter, AdapterWithErrorHandler>();

            // Create the storage we'll be using for User and Conversation state.
            // (Memory is great for testing purposes - examples of implementing storage with
            // Azure Blob Storage or Cosmos DB are below).
            // var storage = new MemoryStorage();

            /* AZURE BLOB STORAGE - Uncomment the code in this section to use Azure blob storage */
                           
            // var storage = new BlobsStorage("<blob-storage-connection-string>", "bot-state");

            /* END AZURE BLOB STORAGE */

            /* COSMOSDB STORAGE - Uncomment the code in this section to use CosmosDB storage */

            IStorage storage;
            if (Environment.GetEnvironmentVariable("COSMOS_API_ENDPOINT") != null) {
                var cosmosDbStorageOptions = new CosmosDbPartitionedStorageOptions()
                {
                    CosmosDbEndpoint = Environment.GetEnvironmentVariable("COSMOS_API_ENDPOINT"),
                    AuthKey = Environment.GetEnvironmentVariable("COSMOS_API_KEY"),
                    DatabaseId = "SKBot",
                    ContainerId = "Conversations"
                };
                storage = new CosmosDbPartitionedStorage(cosmosDbStorageOptions);
            } else {
                storage = new MemoryStorage();
            }

            /* END COSMOSDB STORAGE */

            // Create the User state passing in the storage layer.
            var userState = new UserState(storage);
            services.AddSingleton(userState);

            // Create the Conversation state passing in the storage layer.
            var conversationState = new ConversationState(storage);
            services.AddSingleton(conversationState);

            services.AddHttpClient();
            // Create the bot as a transient. In this case the ASP Controller is expecting an IBot.
            services.AddTransient<IBot, SKBot>();
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
