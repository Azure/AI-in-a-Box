// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Microsoft.BotBuilderSamples
{
    public class ConversationTurn
    {
        public string Role { get; set; } = null;

        public string Message { get; set; } = null;
    }
    public class Attachment
    {
        public string Name { get; set; }
        public List<AttachmentPage> Pages { get; set; } = new List<AttachmentPage>();
    }
    public class AttachmentPage
    {
        public string Content { get; set; } = null;
        public float[] Vector { get; set; } = null;
    }
    // Defines a state property used to track conversation data.
    public class ConversationData
    {
        // The time-stamp of the most recent incoming message.
        public string Timestamp { get; set; }

        // The ID of the user's channel.
        public string ChannelId { get; set; }

        // Track user's thread
        public string ThreadId { get; set; }

        // Track conversation history
        public List<ConversationTurn> History = new List<ConversationTurn>();

        // Track attached documents
        public List<Attachment> Attachments = new List<Attachment>();

    }
}
