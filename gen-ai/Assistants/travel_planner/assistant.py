import os
import logging
from typing import TextIO

from dotenv import load_dotenv
from openai import AzureOpenAI

assistant_id_env_name = "ASSISTANT_ID"
assistant_env_filename = "assistant.env"

load_dotenv(dotenv_path=assistant_env_filename)
file_paths = [
    "./assets/contoso_case.txt"
]


logger = logging.getLogger(__name__)


def setup_assistant(client: AzureOpenAI, bing_resource_id: str) -> str:
    with open(assistant_env_filename, "a") as env_file:
        assistant_id = get_or_create_assistant(client, bing_resource_id, env_file)

    return assistant_id


def get_or_create_assistant(client: AzureOpenAI, bing_resource_id: str, env_file: TextIO) -> str:
    assistant_id = os.getenv(assistant_id_env_name)

    if assistant_id is not None:
        try:
            # validates vector store exists
            client.beta.assistants.retrieve(assistant_id=assistant_id)
            logger.info("Assistant with id {} already exists".format(assistant_id))
            return assistant_id
        except Exception as ex:
            raise Exception(f"Error retrieving assistant with id {assistant_id}: {ex}")

    assistant = client.beta.assistants.create(
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
                "bing_resource_id": bing_resource_id
            }
        }],
        model="gpt-4-1106-preview",
    )
    assistant_id = assistant.id

    logger.info("Created new assistant with id {}".format(assistant_id))

    # stores the id in the assistant.env file
    write_env(env_file, assistant_id_env_name, assistant_id)

    return assistant_id


def write_env(env_file: TextIO, key: str, value: str):
    env_file.write("{}=\"{}\"\n".format(key, value))
