import os

from openai import AzureOpenAI


def create_assistant(client: AzureOpenAI):
    return client.beta.assistants.create(
        name="Travel planner copilot",
        instructions='''
You are travel planner that helps people plan trips across the world.
The user might give you constraints like:
- destination
- weather preference
- attractions preference
- date preference
When asked for up-to-date information, you should use the browser tool.
You should try to give a plan in the following format:
- city
- start and end date
- cost breakdown
- weather forecast
- attractions and any useful information about tickets.
        ''',
        tools=[{
            "type": "browser",
            "browser": {
                "bing_resource_id": os.getenv("BING_RESOURCE_ID")
            }
        }],
        model="gpt-4-1106-preview",
    )
