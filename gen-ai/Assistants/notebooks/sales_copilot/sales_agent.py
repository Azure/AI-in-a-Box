from openai import AzureOpenAI

from AgentSettings import AgentSettings
from AssistantAgent import AssistantAgent

tools_list = [
    {"type": "code_interpreter"}
]

DATA_FOLDER = "data/"


def get_agent(settings=None, client=None):
    """This function creates a Sales Assistants API agent"""

    if settings is None:
        settings = AgentSettings()

    if client is None:
        client = AzureOpenAI(
            api_key=settings.api_key,
            api_version=settings.api_version,
            azure_endpoint=settings.api_endpoint)

    agent = AssistantAgent(settings,
                           client,
                           "Sales Assistant",
                           "You are an Assistant that can help answer questions and perform calculations related to customers, customer orders, inventory, and sellers with the provided CSV files.",
                           DATA_FOLDER,
                           tools_list)
    return agent
