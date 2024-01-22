// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Azure;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.SemanticKernel.Connectors.OpenAI;


namespace Microsoft.BotBuilderSamples
{
    public class DocumentUploadBot<T> : StateManagementBot<T> where T : Dialog
    {
        private readonly AzureOpenAITextEmbeddingGenerationService _embeddingsClient;
        private readonly DocumentAnalysisClient _documentAnalysisClient;

        public DocumentUploadBot(IConfiguration config, ConversationState conversationState, UserState userState, AzureOpenAITextEmbeddingGenerationService embeddingsClient, DocumentAnalysisClient documentAnalysisClient, T dialog) : base(config, conversationState, userState, dialog)
        {
            _embeddingsClient = embeddingsClient;
            _documentAnalysisClient = documentAnalysisClient;
        }

        public async Task HandleFileUploads(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext)
        {
            if (turnContext.Activity.Attachments.IsNullOrEmpty())
                return;
            var pdfAttachments = turnContext.Activity.Attachments.Where(x => x.ContentType == "application/pdf");
            if (pdfAttachments.IsNullOrEmpty())
                return;
            if (_documentAnalysisClient == null) {
                await turnContext.SendActivityAsync("Document upload not supported as no Document Intelligence endpoint was provided");
                return;
            }
            foreach (Bot.Schema.Attachment pdfAttachment in pdfAttachments) {
                await IngestPdfAttachment(conversationData, turnContext, pdfAttachment);
            }
        }

        private async Task IngestPdfAttachment(ConversationData conversationData, ITurnContext<IMessageActivity> turnContext, Bot.Schema.Attachment pdfAttachment)
        {
            Uri fileUri = new Uri(pdfAttachment.ContentUrl);

            var httpClient = new HttpClient();
            var stream = await httpClient.GetStreamAsync(fileUri);

            var ms = new MemoryStream();
            stream.CopyTo(ms);
            ms.Position = 0;

            var operation = await _documentAnalysisClient.AnalyzeDocumentAsync(WaitUntil.Completed, "prebuilt-layout", ms);
            
            ms.Dispose();

            AnalyzeResult result = operation.Value;

            var attachment = new Attachment();
            attachment.Name = pdfAttachment.Name;
            foreach (DocumentPage page in result.Pages)
            {
                var attachmentPage = new AttachmentPage();
                attachmentPage.Content = "";
                for (int i = 0; i < page.Lines.Count; i++)
                {
                    DocumentLine line = page.Lines[i];
                    attachmentPage.Content += $"{line.Content}\n";
                }
                // Embed content
                var embedding = await _embeddingsClient.GenerateEmbeddingsAsync(new List<string> { attachmentPage.Content });
                attachmentPage.Vector = embedding.First().ToArray();
                attachment.Pages.Add(attachmentPage);
            }
            conversationData.Attachments.Add(attachment);

            var replyText = $"File {pdfAttachment.Name} uploaded successfully! {result.Pages.Count()} pages ingested.";
            conversationData.History.Add(new ConversationTurn { Role = "assistant", Message = replyText });
            await turnContext.SendActivityAsync(replyText);
        }
    }
}
