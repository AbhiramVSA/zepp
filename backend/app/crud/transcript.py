import hashlib
from datetime import datetime
from typing import Any

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transcript import Transcript
from app.schemas.transcript import TranscriptCreate


async def create(session: AsyncSession, user_id: str, payload: TranscriptCreate) -> Transcript:
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
    conditions: list[Any] = [Transcript.user_id == user_id]
    if start_date:
        conditions.append(Transcript.created_at >= start_date)
    if end_date:
        conditions.append(Transcript.created_at <= end_date)
    if q:
        conditions.append(or_(Transcript.text.ilike(f"%{q}%")))
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
    stmt = select(func.count()).select_from(Transcript).where(_filters(user_id, start_date, end_date, q))
    result = await session.execute(stmt)
    return int(result.scalar_one())


async def get_by_id(session: AsyncSession, transcript_id: str, user_id: str) -> Transcript | None:
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
    stmt = (
        select(func.max(Transcript.updated_at))
        .where(_filters(user_id, start_date, end_date, q))
    )
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


def compute_etag(transcripts: list[Transcript], total: int) -> str:
    if not transcripts:
        return f'"empty-{total}"'

    parts = [f"{t.id}:{t.updated_at.isoformat()}" for t in transcripts]
    content = f"{total}:{','.join(parts)}"
    hash_digest = hashlib.md5(content.encode(), usedforsecurity=False).hexdigest()[:16]
    return f'"{hash_digest}"'
