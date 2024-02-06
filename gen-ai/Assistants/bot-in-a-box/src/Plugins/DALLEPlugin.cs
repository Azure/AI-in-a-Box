using System.ComponentModel;
using System.Threading.Tasks;
using Azure;
using Microsoft.SemanticKernel;
using Microsoft.BotBuilderSamples;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Azure.AI.OpenAI;
using System.Collections.Generic;

namespace Plugins;
public class DALLEPlugin
{
    private readonly OpenAIClient _aoaiClient;
    private ITurnContext<IMessageActivity> _turnContext;

    public DALLEPlugin(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, OpenAIClient aoaiClient)
    {
        _aoaiClient = aoaiClient;
        _turnContext = turnContext;
    }



    [KernelFunction, Description("Generate images from descriptions.")]
    public async Task<string> GenerateImages(
        [Description("The description of the images to be generated")] string prompt,
        [Description("The number of images to generate. If not specified, I should use 1")] int n
    )
    {
        await _turnContext.SendActivityAsync($"Generating {n} images with the description \"{prompt}\"...");
        Response<ImageGenerations> imageGenerations = await _aoaiClient.GetImageGenerationsAsync(
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
        foreach (ImageGenerationData img in imageGenerations.Value.Data)
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