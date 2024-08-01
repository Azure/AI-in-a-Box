import logging
from typing import Any

from openai import AssistantEventHandler
from openai.types.beta.threads.runs import ToolCall
from openai.types.beta.threads import Text, TextDelta


logger = logging.getLogger(__name__)


class EventHandler(AssistantEventHandler):
    def __init__(self):
        super().__init__()
        self.is_processing_annotation = False

    def on_exception(self, exception: Exception) -> None:
        logger.error("please try again. an exception occurred: {}".format(exception))

    def on_tool_call_created(self, tool_call: Any):
        logger.info("started calling tool {}".format(get_tool_type(tool_call)))

    def on_tool_call_done(self, tool_call: ToolCall) -> None:
        logger.info("completed calling tool {}".format(get_tool_type(tool_call)))

    def on_text_delta(self, delta: TextDelta, snapshot: Text) -> None:
        print(delta.value, end="", flush=True)

    def on_text_done(self, text: Text) -> None:
        is_first_url_citation = True
        for annotation in text.annotations:
            if annotation.type == "url_citation":
                if is_first_url_citation:
                    print("\nUrl citations: \n", end="", flush=True)
                    is_first_url_citation = False
                title = annotation.model_extra['url_citation']['title']
                url = annotation.model_extra['url_citation']['url']
                print("* {} - [{}]({})\n".format(annotation.text, title, url), end="", flush=True)

    def on_timeout(self) -> None:
        logger.warning("timeout occurred. please try again")

    def on_end(self) -> None:
        logger.info("completed conversation with assistant")


def get_tool_type(tool_call: Any) -> str:
    if isinstance(tool_call, dict):
        return tool_call['type']
    else:
        return tool_call.type
