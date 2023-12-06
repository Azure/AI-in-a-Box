using System.Text.Json.Serialization;
using Azure.Search.Documents.Indexes;

namespace Models;

public class Address {
    [JsonPropertyName("StreetAddress")]
    [SimpleField(IsKey = true, IsFilterable = true, IsSortable = true)]
    public string StreetAddress { get; set; }
    [JsonPropertyName("City")]
    [SimpleField(IsKey = true, IsFilterable = true, IsSortable = true)]
    public string City { get; set; }
    [JsonPropertyName("StateProvince")]
    [SimpleField(IsKey = true, IsFilterable = true, IsSortable = true)]
    public string StateProvince { get; set; }

}

public class Hotel
{
    [JsonPropertyName("HotelName")]
    [SimpleField(IsKey = true, IsFilterable = true, IsSortable = true)]
    public string HotelName { get; set; }

    [JsonPropertyName("Description")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public string Description { get; set; }

    [JsonPropertyName("Address")]
    [SimpleField(IsFilterable = true, IsSortable = true)]
    public Address Address { get; set; }

}