from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.crud import transcript as crud_transcript
from app.db.database import get_session
from app.deps.auth import get_current_user
from app.schemas.transcript import TranscriptCreate, TranscriptList, TranscriptRead
from app.schemas.user import UserRead

router = APIRouter(prefix="/transcripts", tags=["transcripts"])


@router.post("/", response_model=TranscriptRead, status_code=status.HTTP_201_CREATED)
async def create_transcript(
    payload: TranscriptCreate,
    current_user: Annotated[UserRead, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
):
    transcript = await crud_transcript.create(session, user_id=current_user.id, payload=payload)
    return TranscriptRead.model_validate(transcript)


@router.get("/history", response_model=TranscriptList)
async def list_transcripts(
    current_user: Annotated[UserRead, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    start_date: datetime | None = Query(None),
    end_date: datetime | None = Query(None),
    q: str | None = Query(None, description="Full-text search on transcript text"),
):
    items = await crud_transcript.get_by_user(
        session,
        user_id=current_user.id,
        limit=limit,
        offset=offset,
        start_date=start_date,
        end_date=end_date,
        q=q,
    )
    total = await crud_transcript.count_by_user(
        session,
        user_id=current_user.id,
        start_date=start_date,
        end_date=end_date,
        q=q,
    )
    items_read = [TranscriptRead.model_validate(item) for item in items]
    return TranscriptList(items=items_read, total=total, limit=limit, offset=offset)


@router.get("/{transcript_id}", response_model=TranscriptRead)
async def get_transcript(
    transcript_id: str,
    current_user: Annotated[UserRead, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
):
    transcript = await crud_transcript.get_by_id(session, transcript_id=transcript_id, user_id=current_user.id)
    if not transcript:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transcript not found")
    return TranscriptRead.model_validate(transcript)
