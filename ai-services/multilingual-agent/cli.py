import logging

from openai import AzureOpenAI
from azure.cognitiveservices.speech import SpeechRecognizer, SpeechSynthesizer, ResultReason, CancellationReason, PropertyId
from azure.ai.translation.text import TextTranslationClient
from azure.ai.translation.text.models import InputTextItem

from event_handler import EventHandler


logger = logging.getLogger(__name__)

base_language = 'en'


class Cli:
    def __init__(self,
                 openai_client: AzureOpenAI,
                 assistant_id: str,
                 speech_recognizer: SpeechRecognizer,
                 speech_synthesizer: SpeechSynthesizer,
                 text_translator: TextTranslationClient):
        self.openai_client = openai_client
        self.assistant_id = assistant_id
        self.speech_recognizer = speech_recognizer
        self.speech_synthesizer = speech_synthesizer
        self.text_translator = text_translator
        self.language = ''
        self.thread_id = ''

    def run(self):
        thread = self.openai_client.beta.threads.create()
        self.thread_id = thread.id

        print("Say something...")

        while True:
            try:
                user_input = self.recognize()

                base_language_text = user_input
                if not self.language.startswith(base_language):
                    base_language_text = self.translate(text=user_input, language=base_language)

                output_text = self.assistant(content=base_language_text)

                if not self.language.startswith(base_language):
                    output_text = self.translate(text=output_text, language=self.language)

                self.synthesize(output_text)
            except Exception as e:
                logger.error("failure: {}".format(e))
                continue

    def recognize(self) -> str:
        response = self.speech_recognizer.recognize_once()

        reason = response.reason
        if reason != ResultReason.RecognizedSpeech:
            error = 'Failed to recognize speech.'
            if reason == ResultReason.NoMatch:
                error = "No speech could be recognized: {}".format(response.no_match_details)
            elif reason == ResultReason.Canceled:
                cancellation_details = response.cancellation_details
                error = "Speech Recognition canceled: {}".format(cancellation_details.reason)
                if cancellation_details.reason == CancellationReason.Error:
                    error += "Error details: {}".format(cancellation_details.error_details)
            raise Exception("Speech recognition failed with error: {}".format(error))

        self.language = response.properties[PropertyId.SpeechServiceConnection_AutoDetectSourceLanguageResult]
        logger.info("Recognized (language={}): {}".format(self.language, response.text))

        return response.text

    def synthesize(self, text: str) -> None:
        response = self.speech_synthesizer.speak_text(text)

        if response.reason != ResultReason.SynthesizingAudioCompleted:
            cancellation_details = response.cancellation_details
            error = "Speech synthesis canceled: {}".format(cancellation_details.reason)
            if cancellation_details.reason == CancellationReason.Error:
                if cancellation_details.error_details:
                    error += "Error details: {}".format(cancellation_details.error_details)
            raise Exception("Speech synthesis failed with error: {}".format(error))

        logger.info("Speech synthesized for text [{}]".format(text))

    def translate(self, text: str, language: str) -> str:
        content = InputTextItem(text=text)
        translation = self.text_translator.translate(content=[content], to=[language])
        if len(translation) == 0 or len(translation[0].translations) == 0:
            raise Exception("Failed to translate to {} text: {}".format(language, text))

        logger.info("Translated [{}] to [{}]".format(text, translation[0].translations[0].text))
        return translation[0].translations[0].text

    def assistant(self, content: str) -> str:
        self.openai_client.beta.threads.messages.create(
            thread_id=self.thread_id,
            role="user",
            content=content
        )

        event_handler = EventHandler()
        with self.openai_client.beta.threads.runs.stream(assistant_id=self.assistant_id, thread_id=self.thread_id,
                                                         event_handler=event_handler) as stream:
            stream.until_done()

        return event_handler.get_result()
