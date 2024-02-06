// Sample code from: https://github.com/microsoft/BotFramework-WebChat

using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Models
{
    public class AOAIResponse<T> {
        [JsonPropertyName("data")]
        public List<T> Data { get; set; }
    }
    public class Assistant {
        [JsonPropertyName("id")]
        public string Id { get; set; }

        [JsonPropertyName("name")]
        public string Name { get; set; }
    }
    public class Thread
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }
    }

    public class MessageInput
    {
        [JsonPropertyName("role")]
        public string Role { get; set; } = null;

        [JsonPropertyName("content")]
        public string Content { get; set; } = null;
    }

    public class MessageContentText {
        [JsonPropertyName("value")]
        public string Value { get; set; }

    }
    public class MessageContent {
        [JsonPropertyName("type")]
        public string Type { get; set; }
        [JsonPropertyName("text")]
        public MessageContentText Text { get; set; }
    }

    public class Message
    {
        [JsonPropertyName("role")]
        public string Role { get; set; }

        [JsonPropertyName("content")]
        public List<MessageContent> Content { get; set; }
    }

    public class ThreadRunInput
    {

        [JsonPropertyName("assistant_id")]
        public string AssistantId { get; set; }

        [JsonPropertyName("instructions")]
        public string Instructions { get; set; }
    }
    public class ThreadRun
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }

        [JsonPropertyName("assistant_id")]
        public string AssistantId { get; set; }

        [JsonPropertyName("instructions")]
        public string Instructions { get; set; }

        [JsonPropertyName("status")]
        public string Status { get; set; }
    }

}