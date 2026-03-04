import json
import logging
import tempfile
import wave
from pathlib import Path

import httpx
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.config.settings import settings

logger = logging.getLogger(__name__)

router = APIRouter()

GROQ_TRANSCRIBE_URL = "https://api.groq.com/openai/v1/audio/transcriptions"


def write_wav_from_pcm(raw_pcm: bytes, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(16000)
        wav_file.writeframes(raw_pcm)


async def transcribe_wav_file(wav_path: Path) -> str:
    if not settings.GROQ_API_KEY:
        raise RuntimeError("GROQ_API_KEY is not set.")

    headers = {"Authorization": f"Bearer {settings.GROQ_API_KEY}"}
    data = {"model": "whisper-large-v3-turbo"}

    async with httpx.AsyncClient(timeout=120) as client:
        with wav_path.open("rb") as audio_file:
            files = {"file": ("audio.wav", audio_file, "audio/wav")}
            response = await client.post(
                GROQ_TRANSCRIBE_URL,
                headers=headers,
                data=data,
                files=files,
            )

    if response.status_code >= 400:
        raise httpx.HTTPStatusError(
            f"Groq API error {response.status_code}",
            request=response.request,
            response=response,
        )

    payload = response.json()
    text = payload.get("text")
    if not text:
        raise ValueError("Groq API response missing 'text'")

    return text


@router.websocket("/ws/audio")
async def audio_stream(websocket: WebSocket) -> None:
    await websocket.accept()
    logger.info("WebSocket connection opened: %s", websocket.client)

    buffer = bytearray()
    wav_path: Path | None = None

    try:
        while True:
            message = await websocket.receive()

            if message.get("type") == "websocket.disconnect":
                logger.info("WebSocket disconnect received from client")
                break

            if message.get("bytes") is not None:
                chunk = message.get("bytes") or b""
                if chunk:
                    buffer.extend(chunk)
                continue

            if message.get("text"):
                try:
                    payload = json.loads(message["text"])
                except json.JSONDecodeError:
                    await websocket.send_json({"error": "Invalid JSON message"})
                    continue

                if payload.get("event") == "end":
                    if not buffer:
                        await websocket.send_json({"error": "No audio data received"})
                        break

                    # Use a unique temp file per session to avoid collisions
                    tmp_fd, tmp_path_str = tempfile.mkstemp(suffix=".wav")
                    wav_path = Path(tmp_path_str)
                    # Close the fd; write_wav_from_pcm will open by path
                    import os
                    os.close(tmp_fd)

                    write_wav_from_pcm(bytes(buffer), wav_path)
                    logger.info("Saved WAV file (%d bytes PCM)", len(buffer))

                    try:
                        transcription = await transcribe_wav_file(wav_path)
                        logger.info("Transcription completed")
                        await websocket.send_json({"text": transcription})
                    except Exception as exc:  # noqa: BLE001
                        logger.exception("Transcription failed")
                        await websocket.send_json({"error": f"Transcription failed: {exc}"})
                    break

                await websocket.send_json({"error": "Unknown event"})

        await websocket.close()

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected unexpectedly: %s", websocket.client)

    finally:
        if wav_path is not None:
            try:
                wav_path.unlink()
            except FileNotFoundError:
                pass
            except OSError as exc:
                logger.warning("Could not delete temporary file: %s", exc)
