import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request

from app.api.api import api_router
from app.config.settings import settings
from app.db.database import engine
from app.models import base  # noqa: F401

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _settings = settings
    # Create tables if they do not exist; in production prefer migrations.
    async with engine.begin() as conn:
        await conn.run_sync(base.Base.metadata.create_all)
    yield
    # No teardown required for now


def create_app() -> FastAPI:
    app = FastAPI(title="Voice App API", version="0.1.0", lifespan=lifespan)
    
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        logger.info(f"Request: {request.method} {request.url}")
        auth_header = request.headers.get("Authorization", "None")
        logger.debug(f"Auth header present: {auth_header[:50] if auth_header and len(auth_header) > 50 else auth_header}...")
        response = await call_next(request)
        logger.info(f"Response: {response.status_code}")
        return response
    
    app.include_router(api_router)
    return app


app = create_app()
