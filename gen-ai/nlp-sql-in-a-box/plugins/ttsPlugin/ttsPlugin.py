import azure.cognitiveservices.speech as speechsdk
from semantic_kernel.skill_definition import (
    sk_function,
    sk_function_context_parameter,
)
from semantic_kernel.orchestration.sk_context import SKContext


class TTSPlugin:
    @sk_function(
        description="generate speech from text",
        name="speak_out_response",
        input_description="The content to be converted to speech",
    )
    @sk_function_context_parameter(
        name="content",
        description="The content to be converted to speech",
    )
    @sk_function_context_parameter(
        name="speech_key",
        description="speech_key",
    )
    @sk_function_context_parameter(
        name="speech_region",
        description="speech_region",
    )
    def speak_out_response(self, context: SKContext) -> None:        
        speech_config = speechsdk.SpeechConfig(subscription=context["speech_key"], region=context["speech_region"])
        content = context["content"]
        audio_config = speechsdk.audio.AudioOutputConfig(use_default_speaker=True)
        # The language of the voice that speaks.
        speech_config.speech_synthesis_voice_name='en-US-JennyNeural'
        speech_synthesizer = speechsdk.SpeechSynthesizer(speech_config=speech_config, audio_config=audio_config)
        speech_synthesis_result = speech_synthesizer.speak_text_async(content).get()

        if speech_synthesis_result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
            print("Speech synthesized to speaker for text [{}]".format(content))
        elif speech_synthesis_result.reason == speechsdk.ResultReason.Canceled:
            cancellation_details = speech_synthesis_result.cancellation_details
            print("Speech synthesis canceled: {}".format(cancellation_details.reason))
            if cancellation_details.reason == speechsdk.CancellationReason.Error:
                if cancellation_details.error_details:
                    print("Error details: {}".format(cancellation_details.error_details))
                    print("Did you set the speech resource key and region values?") 
        return context