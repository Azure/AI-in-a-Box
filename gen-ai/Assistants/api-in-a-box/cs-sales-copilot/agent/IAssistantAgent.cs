namespace agent;
using Azure.AI.OpenAI.Assistants;

public interface IAssistantAgent
{
    public Task CreateAssistant();
    public Task LoadFiles(string folderPath);
    public Task<BinaryData> GetFileContent(string id);
    public Task ProcessMessagesAsync(IReadOnlyList<ThreadMessage> messages);
    public Task ProcessPrompt(string input);
    public Task DeleteAsync();
}
