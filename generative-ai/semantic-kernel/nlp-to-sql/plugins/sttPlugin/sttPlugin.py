import azure.cognitiveservices.speech as speechsdk
from semantic_kernel.skill_definition import (
    sk_function,
    sk_function_context_parameter,
)
from semantic_kernel.orchestration.sk_context import SKContext


class STTPlugin:
    @sk_function(
        description="generate text from speech",
        name="recognize_from_microphone",
        input_description="The content from microphone to be converted to text",
    )
    @sk_function_context_parameter(
        name="speech_key",
        description="speech_key",
    )
    @sk_function_context_parameter(
        name="speech_region",
        description="speech_region",
    )
    def recognize_from_microphone(self, context: SKContext) -> None:        
        speech_config = speechsdk.SpeechConfig(subscription=context["speech_key"], region=context["speech_region"])
        speech_config.speech_recognition_language="en-US"
        audio_config = speechsdk.audio.AudioConfig(use_default_microphone=True)
        speech_recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)
        
        speech_recognition_result = speech_recognizer.recognize_once_async().get()

        if speech_recognition_result.reason == speechsdk.ResultReason.RecognizedSpeech:
            #print("Recognized: {}".format(speech_recognition_result.text))
            context["result"] = speech_recognition_result.text            
        elif speech_recognition_result.reason == speechsdk.ResultReason.NoMatch:
            print("No speech could be recognized: {}".format(speech_recognition_result.no_match_details))
        elif speech_recognition_result.reason == speechsdk.ResultReason.Canceled:
            cancellation_details = speech_recognition_result.cancellation_details
            #print("Speech Recognition canceled: {}".format(cancellation_details.reason))
            if cancellation_details.reason == speechsdk.CancellationReason.Error:
                print("Error details: {}".format(cancellation_details.error_details))
                print("Did you set the speech resource key and region values?")
    
        return context