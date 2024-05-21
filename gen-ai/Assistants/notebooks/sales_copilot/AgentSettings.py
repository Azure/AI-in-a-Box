from dotenv import load_dotenv
import os


class AgentSettings:
    def __init__(self):
        load_dotenv()
        self.api_endpoint = os.getenv("OPENAI_URI")
        self.api_key = os.getenv("OPENAI_KEY")
        self.api_version = os.getenv("OPENAI_VERSION")
        self.model_deployment = os.getenv("OPENAI_GPT_DEPLOYMENT")
        self.email_URI = os.getenv("EMAIL_URI")
