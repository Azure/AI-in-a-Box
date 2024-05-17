from AgentSettings import AgentSettings
from openai import AzureOpenAI
from ArgumentException import ArgumentExceptionError
from AssistantAgent import AssistantAgent


class AgentRegistration:
    """This function is to hold the agent registration information"""

    def __init__(self, settings=None, client=None, intent: str = None, intent_desc: str = None, agent: AssistantAgent = None):
        self.settings = settings
        self.client = client
        self.agent = agent
        self.intent = intent
        self.intent_desc = intent_desc

        if intent is None:
            raise ArgumentExceptionError("intent parameter is missing")
        if intent_desc is None:
            raise ArgumentExceptionError("intent_desc parameter is missing")

        if settings is None:
            self.settings = AgentSettings()

        if client is None:
            client = AzureOpenAI(
                api_key=self.settings.api_key,
                api_version=self.settings.api_version,
                azure_endpoint=self.settings.api_endpoint)
