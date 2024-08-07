import logging

from openai import AzureOpenAI

from event_handler import EventHandler


logger = logging.getLogger(__name__)


class Cli:
    def __init__(self, client: AzureOpenAI, assistant_id: str):
        self.client = client
        self.assistant_id = assistant_id

    def run(self):
        thread = self.client.beta.threads.create()

        logger.info("starting conversation with assistant (assistant_id={}, thread_id={})".format(self.assistant_id, thread.id))

        print('''
I'm a law firm assistant. 
How can I help you with court cases!
        ''')

        while True:
            user_input = input("\nYour input: ")

            if user_input == "exit":
                print("Exiting conversation with assistant")
                break

            self.client.beta.threads.messages.create(
                thread_id=thread.id,
                role="user",
                content=user_input
            )

            print("\nAssistant: ", end="", flush=True)
            event_handler = EventHandler()
            with self.client.beta.threads.runs.stream(assistant_id=self.assistant_id, thread_id=thread.id,
                                                      event_handler=event_handler) as stream:
                stream.until_done()
