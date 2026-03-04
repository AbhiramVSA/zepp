import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.api import api_router
from app.config.settings import settings
from app.db.database import engine
from app.models import base  # noqa: F401

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _settings = settings
    # Create tables if they do not exist; in production prefer migrations.
    async with engine.begin() as conn:
        await conn.run_sync(base.Base.metadata.create_all)
    yield


def create_app() -> FastAPI:
    app = FastAPI(title="VoiceAI API", version="0.1.0", lifespan=lifespan)
    app.include_router(api_router)
    return app


app = create_app()
