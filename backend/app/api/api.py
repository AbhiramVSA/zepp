from fastapi import APIRouter

from app.api.v1.routers import audio_ws, auth, transcripts

api_router = APIRouter()

api_router.include_router(audio_ws.router)
api_router.include_router(auth.router)
api_router.include_router(transcripts.router)


@api_router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
