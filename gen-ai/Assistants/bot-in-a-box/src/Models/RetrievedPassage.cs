using System.Text.Json.Serialization;
using Azure.Search.Documents.Indexes;

namespace Models;

public class RetrievedPassage
{
    [JsonPropertyName("title")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public string Title { get; set; }

    [JsonPropertyName("chunk_id")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public string ChunkId { get; set; }

    [JsonPropertyName("path")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public string Path { get; set; }

    [JsonPropertyName("chunk")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public string Chunk { get; set; }
}