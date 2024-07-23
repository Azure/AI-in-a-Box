import logging

from openai import AssistantEventHandler
from openai.types.beta.threads.runs import ToolCall
from openai.types.beta.threads import Text


logger = logging.getLogger(__name__)


class EventHandler(AssistantEventHandler):
    def __init__(self):
        super().__init__()
        self.result = ''

    def on_exception(self, exception: Exception) -> None:
        logger.error("please try again. an exception occurred: {}".format(exception))

    def on_tool_call_created(self, tool_call: ToolCall):
        logger.info("started calling tool {}".format(tool_call['type']))

    def on_tool_call_done(self, tool_call: ToolCall) -> None:
        logger.info("completed calling tool {}".format(tool_call['type']))

    def on_text_done(self, text: Text) -> None:
        self.result = text.value

        is_first_url_citation = True
        for annotation in text.annotations:
            if annotation.type == "url_citation":
                if is_first_url_citation:
                    self.result += "\nUrl citations: \n"
                title = annotation.model_extra['url_citation']['title']
                url = annotation.model_extra['url_citation']['url']
                self.result += "* {} - [{}]({})\n".format(annotation.text, title, url)

    def on_timeout(self) -> None:
        logger.warning("timeout occurred. please try again")

    def on_end(self) -> None:
        logger.info("completed conversation with assistant")

    def get_result(self) -> str:
        return self.result
