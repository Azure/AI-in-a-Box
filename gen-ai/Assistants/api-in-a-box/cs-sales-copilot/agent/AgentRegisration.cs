namespace agent;

public class AgentRegistration(AssistantAgent agent, string intent, string intentDescription)
{
    public AssistantAgent Agent { get; set; } = agent;
    public string Intent { get; set; } = intent;
    public string IntentDescription { get; set; } = intentDescription;
}