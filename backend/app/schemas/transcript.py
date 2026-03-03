from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class TranscriptBase(BaseModel):
    text: str = Field(min_length=1)
    confidence: float | None = None
    duration_seconds: float | None = None
    meta: dict[str, Any] | None = None
    audio_url: str | None = None


class TranscriptCreate(TranscriptBase):
    pass


class TranscriptRead(TranscriptBase):
    """
    Read schema for transcripts, includes updated_at for conditional fetching.
    Clients use updated_at to determine if cached data is stale.
    """
    id: UUID
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TranscriptList(BaseModel):
    """
    Paginated list response with metadata for conditional caching.
    
    - last_updated: The most recent updated_at among returned items.
      Clients store this and send as If-Modified-Since on subsequent requests.
    - etag: Content-based hash for If-None-Match validation.
    """
    items: list[TranscriptRead]
    total: int
    limit: int
    offset: int
    last_updated: datetime | None = None
    etag: str | None = None


class TranscriptListMetadata(BaseModel):
    """
    Lightweight metadata-only response for checking if data has changed.
    Used when client has cached data and only needs to verify freshness.
    """
    total: int
    last_updated: datetime | None = None
    etag: str | None = None
