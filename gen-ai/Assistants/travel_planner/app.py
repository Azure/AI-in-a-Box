import os
import logging

from openai import AzureOpenAI
from dotenv import load_dotenv

from cli import Cli
from assistant import create_assistant

load_dotenv()

logger = logging.getLogger(__name__)


if __name__ == "__main__":
    try:
        logging.basicConfig(filename='app.log', level=logging.INFO)

        client = AzureOpenAI(
            api_key=os.getenv("API_KEY"),
            api_version="2024-07-01-preview",
            azure_endpoint=os.getenv("AZURE_ENDPOINT"),
            default_headers={"X-Ms-Enable-Preview": "true"}
        )

        assistant_id = os.getenv("ASSISTANT_ID")

        if assistant_id is None or assistant_id == "":
            assistant_id = create_assistant(client).id
            logger.debug("created new assistant with id {}".format(assistant_id))

        runner = Cli(client, assistant_id)

        runner.run()
    except Exception as error:
        raise error
