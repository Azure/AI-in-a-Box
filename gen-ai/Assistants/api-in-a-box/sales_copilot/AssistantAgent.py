from typing import Iterable
import os
import io
import time
from datetime import datetime
from pathlib import Path


from AgentSettings import AgentSettings

from openai.types.beta.threads.message_content_image_file import MessageContentImageFile
from openai.types.beta.threads.message_content_text import MessageContentText
from openai.types.beta.threads.messages import MessageFile
from openai.types import FileObject
from PIL import Image
from ArgumentException import ArgumentExceptionError


class AssistantAgent:
    def __init__(self, settings, client, name, instructions, data_folder, tools_list, keep_state: bool = False, fn_calling_delegate=None):
        if name is None:
            raise ArgumentExceptionError("name parameter missing")
        if instructions is None:
            raise ArgumentExceptionError("instructions parameter missing")
        if tools_list is None:
            raise ArgumentExceptionError("tools_list parameter missing")

        self.assistant = None
        self.settings = settings
        self.client = client
        self.name = name
        self.instructions = instructions
        self.data_folder = data_folder
        self.tools_list = tools_list
        self.fn_calling_delegate = fn_calling_delegate
        self.keep_state = keep_state
        self.ai_threads = []
        self.ai_files = []
        self.file_ids = []
        self.get_agent()

    def upload_file(self, path: str) -> FileObject:
        print(path)
        with Path(path).open("rb") as f:
            return self.client.files.create(file=f, purpose="assistants")

    def upload_all_files(self):
        files_in_folder = os.listdir(self.data_folder)
        local_file_list = []
        for file in files_in_folder:
            filePath = self.data_folder + file
            assistant_file = self.upload_file(filePath)
            self.ai_files.append(assistant_file)
            local_file_list.append(assistant_file)
        self.file_ids = [file.id for file in local_file_list]

    def get_agent(self):
        if self.data_folder is not None:
            self.upload_all_files()
            self.assistant = self.client.beta.assistants.create(
                name=self.name,  # "Sales Assistant",
                # "You are a sales assistant. You can answer questions related to customer orders.",
                instructions=self.instructions,
                tools=self.tools_list,
                model=self.settings.model_deployment,
                file_ids=self.file_ids
            )
        else:
            self.assistant = self.client.beta.assistants.create(
                name=self.name,  # "Sales Assistant",
                # "You are a sales assistant. You can answer questions related to customer orders.",
                instructions=self.instructions,
                tools=self.tools_list,
                model=self.settings.model_deployment
            )

    def process_prompt(self, user_name: str, user_id: str, prompt: str) -> None:

        # if keep_state:
        #     thread_id = check_if_thread_exists(user_id)

        #     # If a thread doesn't exist, create one and store it
        #     if thread_id is None:
        #         print(f"Creating new thread for {name} with user_id {user_id}")
        #         thread = self.client.beta.threads.create()
        #         store_thread(user_id, thread)
        #         thread_id = thread.id
        #     # Otherwise, retrieve the existing thread
        #     else:
        #         print(
        #             f"Retrieving existing thread for {name} with user_id {user_id}")
        #         thread = self.client.beta.threads.retrieve(thread_id)
        #         add_thread(thread)
        # else:
        thread = self.client.beta.threads.create()

        self.client.beta.threads.messages.create(
            thread_id=thread.id, role="user", content=prompt)

        run = self.client.beta.threads.runs.create(
            thread_id=thread.id,
            assistant_id=self.assistant.id,
            instructions="Please address the user as Jane Doe. The user has a premium account. Be assertive, accurate, and polite. Ask if the user has further questions. Do not provide explanations for the answers."
            + "The current date and time is: "
            + datetime.now().strftime("%x %X")
            + ". ",
        )

        print("processing ...")
        while True:
            run = self.client.beta.threads.runs.retrieve(
                thread_id=thread.id, run_id=run.id)
            if run.status == "completed":
                # Handle completed
                messages = self.client.beta.threads.messages.list(
                    thread_id=thread.id)
                self.print_messages(user_name, messages)
                break
            if run.status == "failed":
                messages = self.client.beta.threads.messages.list(
                    thread_id=thread.id)
                self.print_messages(user_name, messages)
                # Handle failed
                break
            if run.status == "expired":
                # Handle expired
                break
            if run.status == "cancelled":
                # Handle cancelled
                break
            if run.status == "requires_action":
                if self.fn_calling_delegate:
                    self.fn_calling_delegate(self.client, thread, run)
            else:
                time.sleep(5)
        if not self.keep_state:
            self.client.beta.threads.delete(thread.id)
            print("Deleted thread: ", thread.id)

    def read_assistant_file(self, file_id: str):
        response_content = self.client.files.content(file_id)
        return response_content.read()

    def print_messages(self, name: str, messages: Iterable[MessageFile]) -> None:
        message_list = []

        # Get all the messages till the last user message
        for message in messages:
            message_list.append(message)
            if message.role == "user":
                break

        # Reverse the messages to show the last user message first
        message_list.reverse()

        # Print the user or Assistant messages or images
        for message in message_list:
            for item in message.content:
                # Determine the content type
                if isinstance(item, MessageContentText):
                    if message.role == "user":
                        print(f"user: {name}:\n{item.text.value}\n")
                    else:
                        print(f"{message.role}:\n{item.text.value}\n")
                    file_annotations = item.text.annotations
                    if file_annotations:
                        for annotation in file_annotations:
                            file_id = annotation.file_path.file_id
                            content = self.read_assistant_file(file_id)
                            print(f"Annotation Content:\n{str(content)}\n")
                elif isinstance(item, MessageContentImageFile):
                    # Retrieve image from file id
                    data_in_bytes = self.read_assistant_file(
                        item.image_file.file_id)
                    # Convert bytes to image
                    readable_buffer = io.BytesIO(data_in_bytes)
                    image = Image.open(readable_buffer)
                    # Resize image to fit in terminal
                    width, height = image.size
                    image = image.resize(
                        (width // 2, height // 2), Image.LANCZOS)
                    # Display image
                    image.show()

    def cleanup(self):
        print(self.client.beta.assistants.delete(self.assistant.id))
        print("Deleting: ", len(self.ai_threads), " threads.")
        for thread in self.ai_threads:
            print(self.client.beta.threads.delete(thread.id))
        print("Deleting: ", len(self.ai_files), " files.")
        for file in self.ai_files:
            print(self.client.files.delete(file.id))
