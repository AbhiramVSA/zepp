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
    model_config = {"from_attributes": True}

    id: UUID
    user_id: str
    created_at: datetime
    updated_at: datetime


class TranscriptList(BaseModel):
    items: list[TranscriptRead]
    total: int
    limit: int
    offset: int
    last_updated: datetime | None = None
    etag: str | None = None
