using System.Text.Json.Serialization;
using Azure.Search.Documents.Indexes;

namespace Model;

public class Hotel
{
    [JsonPropertyName("HotelName")]
    [SimpleField(IsKey = true, IsFilterable = true, IsSortable = true)]
    public string HotelName { get; set; }

    [JsonPropertyName("Description")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public string Description { get; set; }

}