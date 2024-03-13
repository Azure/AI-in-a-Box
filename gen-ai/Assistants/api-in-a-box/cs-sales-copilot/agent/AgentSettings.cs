namespace agent;

using dotenv.net;

public class AgentSettings
{
    public string APIEndpoint { get; set; }
    public string APIKey { get; set; }
    public string APIVersion { get; set; }
    public string APIDeploymentName { get; set; }
    public string? EnvLocation { get; }

    public AgentSettings(string? envLocation = null)
    {
        EnvLocation = envLocation;
        if (EnvLocation is null)
        {
            DotEnv.Load();
        }
        else
        {
            DotEnv.Load(new DotEnvOptions(envFilePaths: [EnvLocation]));
        }


        APIEndpoint = Environment.GetEnvironmentVariable("OPENAI_URI") ?? "";
        APIKey = Environment.GetEnvironmentVariable("OPENAI_KEY") ?? "";
        APIVersion = Environment.GetEnvironmentVariable("OPENAI_VERSION") ?? "";
        APIDeploymentName = Environment.GetEnvironmentVariable("OPENAI_GPT_DEPLOYMENT") ?? "";

        if (string.IsNullOrEmpty(APIEndpoint) || string.IsNullOrEmpty(APIKey) || string.IsNullOrEmpty(APIVersion) || string.IsNullOrEmpty(APIDeploymentName))
        {
            Console.WriteLine("Please set the OPENAI_URI, OPENAI_KEY, OPENAI_VERSION, and OPENAI_GPT_DEPLOYMENT environment variables.");
            Environment.Exit(1);
        }
    }
}