namespace agent;

using System.Text;
using System.Text.Json;
using Azure;
using Azure.AI.OpenAI.Assistants;
public class AssistantAgent : IAssistantAgent
{
    public AgentSettings Settings { get; set; }
    public AssistantsClient Client { get; set; }
    public string Name { get; set; }
    public string Instructions { get; set; }
    public List<ToolDefinition> Tools { get; set; }
    public List<string> FileIds { get; set; }
    public Assistant Assistant { get; set; } = null!;
    public AssistantThread Thread { get; set; } = null!;
    public string? DataFolder { get; set; }

    public delegate ToolOutput? ResolveOutputDelegate(RequiredToolCall toolCall);
    public ResolveOutputDelegate? GetResolvedToolOutput { get; set; }


    public AssistantAgent(AgentSettings? settings, AssistantsClient? client, string name, string instructions, List<ToolDefinition>? tools = null, List<string>? fileIds = null, string? dataFolder = null, ResolveOutputDelegate? resolveDelegate = null)
    {
        // (AgentSettings? settings, AssistantsClient? client, string name, string instructions)
        Settings = settings ?? new AgentSettings();
        Client = client ?? new AssistantsClient(new Uri(Settings.APIEndpoint), new AzureKeyCredential(Settings.APIKey));
        Name = name;
        Instructions = instructions;
        Tools = tools ?? [new CodeInterpreterToolDefinition()];
        FileIds = fileIds ?? [];
        DataFolder = dataFolder;
        GetResolvedToolOutput = resolveDelegate;
    }

    public async Task LoadFiles(string folderPath)
    {
        try
        {
            var files = Directory.GetFiles(folderPath);
            foreach (var file in files)
            {
                var fullPath = Path.GetFullPath(file);
                Response<OpenAIFile> uploadAssistantFileResponse = await Client.UploadFileAsync(
                    localFilePath: fullPath,
                    purpose: OpenAIFilePurpose.Assistants);
                FileIds.Add(uploadAssistantFileResponse.Value.Id);
            }
        }
        catch (Exception) { }
    }

    public async Task CreateAssistant()
    {
        // Create 
        var opts = new AssistantCreationOptions(Settings.APIDeploymentName)
        {
            Name = this.Name,
            Instructions = this.Instructions,
            Tools = {
                new CodeInterpreterToolDefinition()
            }
        };

        foreach (var tool in this.Tools)
        {
            opts.Tools.Add(tool);
        }

        // Load files from a folder
        if (DataFolder is not null)
        {
            // Load the files in the folder
            await LoadFiles(DataFolder);

            // If files were loaded add them to the assistant
            foreach (var fileId in this.FileIds)
            {
                opts.FileIds.Add(fileId);
            }
        }

        // Create an assistant
        Response<Assistant> assistantResponse = await Client.CreateAssistantAsync(opts);
        this.Assistant = assistantResponse.Value;

        // Create an Assistant Thread
        Response<AssistantThread> threadResponse = await Client.CreateThreadAsync();
        this.Thread = threadResponse.Value;
    }

    public async Task<BinaryData> GetFileContent(string id)
    {
        var fileContentResponse = await Client.GetFileContentAsync(id);
        var fileContent = fileContentResponse.Value;
        return fileContent;
    }

    public async Task ProcessMessagesAsync(IReadOnlyList<ThreadMessage> messages)
    {
        List<ThreadMessage> localList = [];
        foreach (ThreadMessage threadMessage in messages)
        {
            localList.Add(threadMessage);
            if (threadMessage.Role == "user")
            {
                break;
            }
        }
        localList.Reverse();

        // Note: messages iterate from newest to oldest, with the messages[0] being the most recent
        foreach (ThreadMessage threadMessage in localList)
        {
            Console.Write($"{threadMessage.CreatedAt:yyyy-MM-dd HH:mm:ss} - {threadMessage.Role,10}: ");
            foreach (MessageContent contentItem in threadMessage.ContentItems)
            {
                if (contentItem is MessageTextContent textItem)
                {
                    Console.Write(textItem.Text);
                    var annotations = textItem.Annotations;
                    if (annotations != null && annotations.Count > 0)
                    {
                        foreach (var annotation in annotations)
                        {
                            if (annotation is MessageTextFileCitationAnnotation textCitation)
                            {
                                Console.Write(textCitation.Text);
                            }
                            else if (annotation is MessageTextFilePathAnnotation filCitation)
                            {
                                var content = await GetFileContent(filCitation.FileId);
                                if (content is not null)
                                {
                                    Console.Write(Encoding.UTF8.GetString(content));
                                }
                            }
                        }
                    }

                }
                else if (contentItem is MessageImageFileContent imageFileItem)
                {
                    // Console.Write($"<image from ID: {imageFileItem.FileId}");
                    var imageBytes = await GetFileContent(imageFileItem.FileId);
                    if (imageBytes is not null)
                    {
                        var b64 = Convert.ToBase64String(imageBytes);
                        var img = $"<img src='data:image/png;base64,{b64}' />";
                        Console.Write(img);
                    }
                }
                Console.WriteLine();
            }
        }
    }

    // public void Resolve(RequiredToolCall call) {
    //     if (GetResolvedToolOutput is null)
    //     {
    //         GetResolvedToolOutput = GetResolvedToolOutput(call);
    //     }
    // }

    // ToolOutput? GetResolvedToolOutput(RequiredToolCall toolCall)
    // {
    //     if (toolCall is RequiredFunctionToolCall functionToolCall)
    //     {
    //         if (functionToolCall.Name == InformationAgent.InformationAgent.getUserFavoriteCityTool.Name)
    //         {
    //             return new ToolOutput(toolCall, InformationAgent.InformationAgent.GetUserFavoriteCity());
    //         }
    //         using JsonDocument argumentsJson = JsonDocument.Parse(functionToolCall.Arguments);
    //         if (functionToolCall.Name == InformationAgent.InformationAgent.getCityNicknameTool.Name)
    //         {
    //             string locationArgument = argumentsJson.RootElement.GetProperty("location").GetString() ?? "";
    //             return new ToolOutput(toolCall, InformationAgent.InformationAgent.GetCityNickname(locationArgument));
    //         }
    //         if (functionToolCall.Name == InformationAgent.InformationAgent.getCurrentWeatherAtLocationTool.Name)
    //         {
    //             string locationArgument = argumentsJson.RootElement.GetProperty("location").GetString() ?? "";
    //             if (argumentsJson.RootElement.TryGetProperty("unit", out JsonElement unitElement))
    //             {
    //                 string? unitArgument = unitElement.GetString() ?? "";
    //                 return new ToolOutput(toolCall, InformationAgent.InformationAgent.GetWeatherAtLocation(locationArgument, unitArgument));
    //             }
    //             return new ToolOutput(toolCall, InformationAgent.InformationAgent.GetWeatherAtLocation(locationArgument));
    //         }
    //     }
    //     return null;
    // }

    public async Task ProcessPrompt(string input)
    {
        Response<ThreadMessage> messageResponse = await Client.CreateMessageAsync(
            Thread.Id,
            MessageRole.User,
            input);
        ThreadMessage message = messageResponse.Value;

        Response<ThreadRun> runResponse = await Client.CreateRunAsync(Thread, Assistant);
        ThreadRun run = runResponse.Value;

        do
        {
            await Task.Delay(TimeSpan.FromMilliseconds(5000));
            runResponse = await Client.GetRunAsync(Thread.Id, runResponse.Value.Id);
            if (runResponse.Value.Status == RunStatus.RequiresAction
                && runResponse.Value.RequiredAction is SubmitToolOutputsAction submitToolOutputsAction)
            {
                // Process Funcion calling
                List<ToolOutput> toolOutputs = new();
                foreach (RequiredToolCall toolCall in submitToolOutputsAction.ToolCalls)
                {
                    if (GetResolvedToolOutput is not null)
                    {
                        var val = GetResolvedToolOutput(toolCall);
                        if (val is not null)
                            toolOutputs.Add(val);
                    }
                }
                runResponse = await Client.SubmitToolOutputsToRunAsync(runResponse.Value, toolOutputs);
            }
        }
        while (runResponse.Value.Status == RunStatus.Queued
        || runResponse.Value.Status == RunStatus.InProgress);

        Response<PageableList<ThreadMessage>> afterRunMessagesResponse
        = await Client.GetMessagesAsync(Thread.Id);
        IReadOnlyList<ThreadMessage> messages = afterRunMessagesResponse.Value.Data;

        await ProcessMessagesAsync(messages);
    }

    public async Task DeleteAsync()
    {
        try
        {
            await Client.DeleteAssistantAsync(Assistant.Id);
            await Client.DeleteThreadAsync(Thread.Id);
            foreach (var fileId in FileIds)
            {
                await Client.DeleteFileAsync(fileId);
            }
        }
        finally
        {

        }
    }
}
