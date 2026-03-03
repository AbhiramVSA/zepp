from datetime import datetime
from typing import Any
import hashlib

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transcript import Transcript
from app.schemas.transcript import TranscriptCreate


async def create(session: AsyncSession, user_id: str, payload: TranscriptCreate) -> Transcript:
    """
    Create a new transcript for the given user.
    The created_at and updated_at fields are auto-populated by the database.
    """
    transcript = Transcript(
        user_id=user_id,
        text=payload.text,
        confidence=payload.confidence,
        duration_seconds=payload.duration_seconds,
        meta=payload.meta,
        audio_url=payload.audio_url,
    )
    session.add(transcript)
    await session.commit()
    await session.refresh(transcript)
    return transcript


def _filters(user_id: str, start_date: datetime | None, end_date: datetime | None, q: str | None):
    """Build common filter conditions for transcript queries."""
    conditions: list[Any] = [Transcript.user_id == user_id]
    if start_date:
        conditions.append(Transcript.created_at >= start_date)
    if end_date:
        conditions.append(Transcript.created_at <= end_date)
    if q:
        like = f"%{q}%"
        conditions.append(or_(Transcript.text.ilike(like)))
    return and_(*conditions)


async def get_by_user(
    session: AsyncSession,
    user_id: str,
    limit: int = 50,
    offset: int = 0,
    start_date: datetime | None = None,
    end_date: datetime | None = None,
    q: str | None = None,
) -> list[Transcript]:
    """
    Fetch transcripts for a user with pagination.
    Results are ordered by created_at DESC for consistent pagination.
    """
    stmt = (
        select(Transcript)
        .where(_filters(user_id, start_date, end_date, q))
        .order_by(Transcript.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def count_by_user(
    session: AsyncSession,
    user_id: str,
    start_date: datetime | None = None,
    end_date: datetime | None = None,
    q: str | None = None,
) -> int:
    """Count total transcripts matching filters for a user."""
    stmt = select(func.count()).select_from(Transcript).where(_filters(user_id, start_date, end_date, q))
    result = await session.execute(stmt)
    return int(result.scalar_one())


async def get_by_id(session: AsyncSession, transcript_id, user_id: str) -> Transcript | None:
    """
    Fetch a single transcript by ID, enforcing user ownership.
    Returns None if not found or not owned by user.
    """
    stmt = select(Transcript).where(Transcript.id == transcript_id, Transcript.user_id == user_id)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def get_last_updated(
    session: AsyncSession,
    user_id: str,
    start_date: datetime | None = None,
    end_date: datetime | None = None,
    q: str | None = None,
) -> datetime | None:
    """
    Get the most recent updated_at timestamp for a user's transcripts.
    Used for If-Modified-Since conditional request handling.
    Returns None if user has no transcripts.
    """
    stmt = (
        select(func.max(Transcript.updated_at))
        .where(_filters(user_id, start_date, end_date, q))
    )
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def get_transcripts_modified_since(
    session: AsyncSession,
    user_id: str,
    since: datetime,
    limit: int = 50,
    offset: int = 0,
) -> list[Transcript]:
    """
    Fetch transcripts that have been updated since the given timestamp.
    Used to return only changed records when client has partial cache.
    """
    stmt = (
        select(Transcript)
        .where(
            Transcript.user_id == user_id,
            Transcript.updated_at > since,
        )
        .order_by(Transcript.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


def compute_etag(transcripts: list[Transcript], total: int) -> str:
    """
    Compute an ETag based on transcript IDs, updated_at timestamps, and total count.
    This provides a content-based hash for If-None-Match validation.
    
    The ETag changes when:
    - Any transcript is added, deleted, or modified
    - The total count changes (even if page content is unchanged)
    """
    if not transcripts:
        return f'"empty-{total}"'
    
    # Build a deterministic string from transcript metadata
    parts = [f"{t.id}:{t.updated_at.isoformat()}" for t in transcripts]
    content = f"{total}:{','.join(parts)}"
    hash_digest = hashlib.md5(content.encode(), usedforsecurity=False).hexdigest()[:16]
    return f'"{hash_digest}"'
