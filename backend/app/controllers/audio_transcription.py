from groq import Groq

from app.config.settings import settings


async def transcription(audio_file):
    client = Groq(api_key=settings.GROQ_API_KEY)
    

    transcription = client.audio.transcriptions.create(
        file=audio_file,
        model="whisper-large-v3-turbo",
        temperature=0,
        response_format="verbose_json",
    )

    return transcription.text
