import os
import logging

from dotenv import load_dotenv
from openai import AzureOpenAI
from azure.cognitiveservices.speech import SpeechConfig, SpeechRecognizer, AutoDetectSourceLanguageConfig, SpeechSynthesizer
from azure.cognitiveservices.speech.audio import AudioOutputConfig
from azure.ai.translation.text import TextTranslationClient, TranslatorCredential

from cli import Cli
from assistant import create_assistant

load_dotenv()

logger = logging.getLogger(__name__)


if __name__ == "__main__":
    try:
        logging.basicConfig(filename='app.log', level=logging.INFO)

        speech_key = os.getenv("SPEECH_API_KEY")
        speech_region = os.getenv("SPEECH_REGION")
        translation_key = os.getenv("TRANSLATION_KEY")
        translation_region = os.getenv("TRANSLATION_REGION")

        openai_client = AzureOpenAI(
            api_key=os.getenv("OPENAI_KEY"),
            api_version="2024-07-01-preview",
            azure_endpoint=os.getenv("OPENAI_ENDPOINT"),
            default_headers={"X-Ms-Enable-Preview": "true"}
        )

        assistant_id = os.getenv("ASSISTANT_ID")

        if assistant_id is None or assistant_id == "":
            assistant_id = create_assistant(openai_client).id
            logger.debug("created new assistant with id {}".format(assistant_id))

        speech_config = SpeechConfig(subscription=speech_key, region=speech_region)

        auto_detect_config = AutoDetectSourceLanguageConfig(languages=["en-US", "fr-FR", "pt-BR"])
        speech_recognizer = SpeechRecognizer(speech_config=speech_config, auto_detect_source_language_config=auto_detect_config)

        audio_config = AudioOutputConfig(use_default_speaker=True)
        speech_synthesizer = SpeechSynthesizer(speech_config=speech_config, audio_config=audio_config)

        translator_credential = TranslatorCredential(key=translation_key, region=translation_region)
        text_translator = TextTranslationClient(credential=translator_credential)

        runner = Cli(
            openai_client=openai_client,
            assistant_id=assistant_id,
            speech_recognizer=speech_recognizer,
            speech_synthesizer=speech_synthesizer,
            text_translator=text_translator
        )

        runner.run()
    except Exception as error:
        raise error
