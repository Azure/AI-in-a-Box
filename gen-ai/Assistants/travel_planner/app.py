import os
import logging

from openai import AzureOpenAI
from dotenv import load_dotenv

from cli import Cli
from assistant import setup_assistant

load_dotenv()
logging.basicConfig(
    filename='app.log',
    format="[%(asctime)s - %(name)s:%(lineno)d - %(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    level=logging.INFO
)

logger = logging.getLogger(__name__)


if __name__ == "__main__":
    bing_resource_id = os.getenv("BING_RESOURCE_ID")
    openai_key = os.getenv("OPENAI_KEY")
    openai_endpoint = os.getenv("OPENAI_ENDPOINT")

    # validate environment variables
    if bing_resource_id is None:
        raise ValueError("BING_RESOURCE_ID is not set")
    if openai_key is None:
        raise ValueError("API_KEY is not set")
    if openai_endpoint is None:
        raise ValueError("AZURE_ENDPOINT is not set")

    client = AzureOpenAI(
        api_key=openai_key,
        api_version="2024-07-01-preview",
        azure_endpoint=openai_endpoint,
        default_headers={"X-Ms-Enable-Preview": "true"}
    )

    assistant_id = setup_assistant(client=client, bing_resource_id=bing_resource_id)

    runner = Cli(client, assistant_id)

    runner.run()
