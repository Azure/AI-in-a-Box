from openai import AzureOpenAI
from AgentRegistration import AgentRegistration
from AgentSettings import AgentSettings
from ArgumentException import ArgumentExceptionError


class AgentProxy:
    def __init__(self, settings=None, client=None, registered_agents: list[AgentRegistration] = None):
        self.settings = settings
        self.client = client
        self.registered_agents = registered_agents

        if registered_agents is None:
            raise ArgumentExceptionError("Missing registered_agents")

        if settings is None:
            self.settings = AgentSettings()

        if client is None:
            client = AzureOpenAI(
                api_key=self.settings.api_key,
                api_version=self.settings.api_version,
                azure_endpoint=self.settings.api_endpoint)

    def __semantic_intent(self, prompt: str) -> str:
        prompt_template = """system:
You are an agent that can determine intent from the following list of intents and return the intent that best matches the user's question or statement.

List of intents:
<INTENTS>
OtherAgent: any other question

user:
<QUESTION>

Output in ONE word."""

        intents = ""
        for reg_agent in self.registered_agents:
            intents += f"{reg_agent.intent}: {reg_agent.intent_desc}\n"

        full_prompt = prompt_template.replace(
            "<INTENTS>", intents).replace("<QUESTION>", prompt)
        completion = self.client.chat.completions.create(
            model=self.settings.model_deployment,
            messages=[
                {
                    "role": "user",
                    "content": full_prompt,
                },
            ],
            max_tokens=2,
            temperature=0.1
        )
        try:
            intent = completion.choices[0].message.content
            return intent
        except:
            return "Unknown"

    def process_for_intent(self, user_name, user_id, prompt: str) -> str:
        intent = self.__semantic_intent(prompt)
        print(f'Intent: {intent}')
        if intent is None or intent == "OtherAgent" or intent == "Unknown":
            completion = self.client.chat.completions.create(
                model=self.settings.model_deployment,
                messages=[
                    {
                        "role": "user",
                        "content": prompt,
                    }
                ]
            )
            print(completion.choices[0].message.content)
        else:
            for registered_agent in self.registered_agents:
                if registered_agent.intent == intent:
                    return registered_agent.agent.process_prompt(user_name, user_id, prompt)
