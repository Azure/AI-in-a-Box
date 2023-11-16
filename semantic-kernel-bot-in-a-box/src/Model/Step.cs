using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Model;

public class Step
{

    [JsonPropertyName("action")]
    public string action {get; set;}

    [JsonPropertyName("action_variables")]
    public Dictionary<string, dynamic> action_variables {get; set;}

    [JsonPropertyName("final_answer")]
    public string final_answer {get; set;}

    [JsonPropertyName("observation")]
    public string observation {get; set;}

    [JsonPropertyName("original_response")]
    public string original_response {get; set;}

    [JsonPropertyName("thought")]
    public string thought {get; set;}


}