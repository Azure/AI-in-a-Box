using System;
using System.ComponentModel;
using System.Threading.Tasks;
using Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Azure.AI.OpenAI;
using System.Collections.Generic;

namespace Plugins;
public class DALLEPlugin
{
    private readonly OpenAIClient client;
    private ITurnContext<IMessageActivity> _turnContext;

    public DALLEPlugin(IConfiguration config, ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
    {
        var _aoaiApiKey = config.GetValue<string>("AOAI_API_KEY");
        var _aoaiApiEndpoint = config.GetValue<string>("AOAI_API_ENDPOINT");
        client = new(new Uri(_aoaiApiEndpoint), new AzureKeyCredential(_aoaiApiKey));
        _turnContext = turnContext;
    }



    [SKFunction, Description("Generate images from descriptions.")]
    public async Task<string> GenerateImages(
        [Description("The description of the images to be generated")] string prompt,
        [Description("The number of images to generate. If not specified, I should use 1")] int n
    )
    {
        await _turnContext.SendActivityAsync($"Generating {n} images with the description \"{prompt}\"...");
        Response<ImageGenerations> imageGenerations = await client.GetImageGenerationsAsync(
            new ImageGenerationOptions()
            {
                Prompt = prompt,
                Size = ImageSize.Size512x512,
                ImageCount = n
            });

        List<object> images = new();
        images.Add(
            new {
                type="TextBlock",
                text="Here are the generated images.",
                size="large"
            }
        );
        foreach (ImageLocation img in imageGenerations.Value.Data)
            images.Add(new { type = "Image", url = img.Url.AbsoluteUri });
        object adaptiveCardJson = new
        {
            type = "AdaptiveCard",
            version = "1.0",
            body = images
        };

        var adaptiveCardAttachment = new Microsoft.Bot.Schema.Attachment()
        {
            ContentType = "application/vnd.microsoft.card.adaptive",
            Content = adaptiveCardJson,
        };
        await _turnContext.SendActivityAsync(MessageFactory.Attachment(adaptiveCardAttachment));
        return "Images were generated successfully and already sent to user.";
    }

}