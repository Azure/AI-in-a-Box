import os
import logging
from typing import TextIO

from dotenv import load_dotenv
from openai import AzureOpenAI

assistant_id_env_name = "ASSISTANT_ID"
vector_store_id_env_name = "VECTOR_STORE_ID"
assistant_env_filename = "assistant.env"

load_dotenv(dotenv_path=assistant_env_filename)
file_paths = [
    "./assets/contoso_case.txt"
]


logger = logging.getLogger(__name__)


def setup_assistant(client: AzureOpenAI, bing_resource_id: str) -> str:
    with open(assistant_env_filename, "a") as env_file:
        vector_store_id = get_or_create_vector_store(client, env_file)
        assistant_id = get_or_create_assistant(client, bing_resource_id, vector_store_id, env_file)

    return assistant_id


def get_or_create_vector_store(client: AzureOpenAI, env_file: TextIO) -> str:
    vector_store_id = os.getenv(vector_store_id_env_name)

    if vector_store_id is not None:
        try:
            # validates vector store exists
            client.beta.vector_stores.retrieve(vector_store_id=vector_store_id)
            logger.info("Vector store with id {} already exists".format(vector_store_id))
            return vector_store_id
        except Exception as ex:
            raise Exception(f"Error retrieving vector store with id {vector_store_id}: {ex}")

    vector_store = client.beta.vector_stores.create(name="courtcases")
    vector_store_id = vector_store.id
    logger.info("Created new vector store with id {}".format(vector_store_id))

    # stores the id in the assistant.env file
    write_env(env_file, vector_store_id_env_name, vector_store_id)

    # Ready the files for upload to OpenAI
    file_streams = [open(path, "rb") for path in file_paths]

    # Use the upload and poll SDK helper to upload the files, add them to the vector store,
    # and poll the status of the file batch for completion.
    client.beta.vector_stores.file_batches.upload_and_poll(
        vector_store_id=vector_store_id, files=file_streams
    )

    logger.info("Uploaded files to vector store: [{}]".format(file_paths))
    return vector_store_id


def get_or_create_assistant(client: AzureOpenAI, bing_resource_id: str, vector_store_id: str, env_file: TextIO) -> str:
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
        name="Law firm copilot",
        instructions='''
You are a law firm assistant that answers questions about court cases.

You are only allowed to:
- use the file search tool to search for internal court cases
- use the browser tool to look for court cases on the web

You are not allowed to answer questions that are not related to court cases
        ''',
        tools=[{
            "type": "file_search"
        }, {
            "type": "browser",
            "browser": {
                "bing_resource_id": bing_resource_id
            }
        }],
        tool_resources={
            "file_search": {
                "vector_store_ids": [vector_store_id]
            }
        },
        model="gpt-4o-0513",
    )
    assistant_id = assistant.id

    logger.info("Created new assistant with id {}".format(assistant_id))

    # stores the id in the assistant.env file
    write_env(env_file, assistant_id_env_name, assistant_id)

    return assistant_id


def write_env(env_file: TextIO, key: str, value: str):
    env_file.write("{}=\"{}\"\n".format(key, value))
