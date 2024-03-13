using System.Text.Json;
using agent;
using Azure.AI.OpenAI.Assistants;

namespace InformationAgent;


public class InformationAgent
{
    private InformationAgent() { }

    static ToolOutput? GetResolvedToolOutput(RequiredToolCall toolCall)
    {
        if (toolCall is RequiredFunctionToolCall functionToolCall)
        {
            if (functionToolCall.Name == getUserFavoriteCityTool.Name)
            {
                return new ToolOutput(toolCall, GetUserFavoriteCity());
            }
            using JsonDocument argumentsJson = JsonDocument.Parse(functionToolCall.Arguments);
            if (functionToolCall.Name == getCityNicknameTool.Name)
            {
                string locationArgument = argumentsJson.RootElement.GetProperty("location").GetString() ?? "";
                return new ToolOutput(toolCall, GetCityNickname(locationArgument));
            }
            if (functionToolCall.Name == getCurrentWeatherAtLocationTool.Name)
            {
                string locationArgument = argumentsJson.RootElement.GetProperty("location").GetString() ?? "";
                if (argumentsJson.RootElement.TryGetProperty("unit", out JsonElement unitElement))
                {
                    string? unitArgument = unitElement.GetString() ?? "";
                    return new ToolOutput(toolCall, GetWeatherAtLocation(locationArgument, unitArgument));
                }
                return new ToolOutput(toolCall, GetWeatherAtLocation(locationArgument));
            }
        }
        return null;
    }


    // Example of a function that defines no parameters
    public static string GetUserFavoriteCity() => "Seattle, WA";
    public static FunctionToolDefinition getUserFavoriteCityTool = new("getUserFavoriteCity", "Gets the user's favorite city.");
    // Example of a function with a single required parameter
    public static string GetCityNickname(string location) => location switch
    {
        "Seattle, WA" => "The Emerald City",
        _ => throw new NotImplementedException(),
    };
    public static FunctionToolDefinition getCityNicknameTool = new(
        name: "getCityNickname",
        description: "Gets the nickname of a city, e.g. 'LA' for 'Los Angeles, CA'.",
        parameters: BinaryData.FromObjectAsJson(
            new
            {
                Type = "object",
                Properties = new
                {
                    Location = new
                    {
                        Type = "string",
                        Description = "The city and state, e.g. San Francisco, CA",
                    },
                },
                Required = new[] { "location" },
            },
            new JsonSerializerOptions() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }));
    // Example of a function with one required and one optional, enum parameter
    public static string GetWeatherAtLocation(string location, string temperatureUnit = "f") => location switch
    {
        "Seattle, WA" => temperatureUnit == "f" ? "70f" : "21c",
        _ => throw new NotImplementedException()
    };
    public static FunctionToolDefinition getCurrentWeatherAtLocationTool = new(
        name: "getCurrentWeatherAtLocation",
        description: "Gets the current weather at a provided location.",
        parameters: BinaryData.FromObjectAsJson(
            new
            {
                Type = "object",
                Properties = new
                {
                    Location = new
                    {
                        Type = "string",
                        Description = "The city and state, e.g. San Francisco, CA",
                    },
                    Unit = new
                    {
                        Type = "string",
                        Enum = new[] { "c", "f" },
                    },
                },
                Required = new[] { "location" },
            },
            new JsonSerializerOptions() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }));

    // ToolOutput GetResolvedToolOutput(RequiredToolCall toolCall)
    // {
    //     if (toolCall is RequiredFunctionToolCall functionToolCall)
    //     {
    //         if (functionToolCall.Name == getUserFavoriteCityTool.Name)
    //         {
    //             return new ToolOutput(toolCall, GetUserFavoriteCity());
    //         }
    //         using JsonDocument argumentsJson = JsonDocument.Parse(functionToolCall.Arguments);
    //         if (functionToolCall.Name == getCityNicknameTool.Name)
    //         {
    //             string locationArgument = argumentsJson.RootElement.GetProperty("location").GetString();
    //             return new ToolOutput(toolCall, GetCityNickname(locationArgument));
    //         }
    //         if (functionToolCall.Name == getCurrentWeatherAtLocationTool.Name)
    //         {
    //             string locationArgument = argumentsJson.RootElement.GetProperty("location").GetString();
    //             if (argumentsJson.RootElement.TryGetProperty("unit", out JsonElement unitElement))
    //             {
    //                 string unitArgument = unitElement.GetString();
    //                 return new ToolOutput(toolCall, GetWeatherAtLocation(locationArgument, unitArgument));
    //             }
    //             return new ToolOutput(toolCall, GetWeatherAtLocation(locationArgument));
    //         }
    //     }
    //     return null;
    // }

    public async static Task<AssistantAgent> GetAgent(AgentSettings? settings,
    AssistantsClient? client)
    {
        List<ToolDefinition> tools = [];
        var favoriteCity = getUserFavoriteCityTool;
        var weather = getCurrentWeatherAtLocationTool;
        var nickName = getCityNicknameTool;
        tools.AddRange([favoriteCity, weather, nickName]);

        var agent = new AssistantAgent(settings, client, "Information Agent", "You are an assistant that can help answer questions related to favority cities, weather and city nick names.",
        resolveDelegate: GetResolvedToolOutput, tools: tools);
        await agent.CreateAssistant();

        return agent;
    }
}