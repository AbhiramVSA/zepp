from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.config import Settings, get_settings
from app.db.database import engine
from app.models import base  # noqa: F401
from app.routers import auth as auth_router
from app.routers import transcripts as transcripts_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    _settings: Settings = get_settings()
    # Create tables if they do not exist; in production prefer migrations.
    async with engine.begin() as conn:
        await conn.run_sync(base.Base.metadata.create_all)
    yield
    # No teardown required for now


def create_app() -> FastAPI:
    app = FastAPI(title="Voice App API", version="0.1.0", lifespan=lifespan)
    app.include_router(auth_router.router)
    app.include_router(transcripts_router.router)
    return app


app = create_app()
