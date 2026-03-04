from datetime import datetime
from email.utils import format_datetime, parsedate_to_datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status
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
    response: Response,
    current_user: Annotated[UserRead, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    start_date: datetime | None = Query(None),
    end_date: datetime | None = Query(None),
    q: str | None = Query(None, description="Full-text search on transcript text"),
    if_modified_since: str | None = Header(None, alias="If-Modified-Since"),
    if_none_match: str | None = Header(None, alias="If-None-Match"),
):
    last_updated = await crud_transcript.get_last_updated(
        session,
        user_id=current_user.id,
        start_date=start_date,
        end_date=end_date,
        q=q,
    )

    # If-Modified-Since: return 304 if data hasn't changed
    if if_modified_since and last_updated:
        try:
            client_timestamp = parsedate_to_datetime(if_modified_since)
            if last_updated <= client_timestamp:
                return Response(status_code=status.HTTP_304_NOT_MODIFIED)
        except (ValueError, TypeError):
            pass

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

    etag = crud_transcript.compute_etag(items, total)

    # If-None-Match: return 304 if ETag matches
    if if_none_match:
        client_etag = if_none_match.strip('"')
        server_etag = etag.strip('"')
        if client_etag == server_etag:
            return Response(status_code=status.HTTP_304_NOT_MODIFIED)

    if last_updated:
        response.headers["Last-Modified"] = format_datetime(last_updated, usegmt=True)
    response.headers["ETag"] = etag
    response.headers["Cache-Control"] = "private, max-age=60, must-revalidate"

    items_read = [TranscriptRead.model_validate(item) for item in items]
    return TranscriptList(
        items=items_read,
        total=total,
        limit=limit,
        offset=offset,
        last_updated=last_updated,
        etag=etag,
    )


@router.get("/{transcript_id}", response_model=TranscriptRead)
async def get_transcript(
    transcript_id: str,
    response: Response,
    current_user: Annotated[UserRead, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
    if_none_match: str | None = Header(None, alias="If-None-Match"),
):
    transcript = await crud_transcript.get_by_id(session, transcript_id=transcript_id, user_id=current_user.id)
    if not transcript:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transcript not found")

    etag = f'"{transcript.id}-{transcript.updated_at.isoformat()}"'

    if if_none_match:
        client_etag = if_none_match.strip('"')
        server_etag = etag.strip('"')
        if client_etag == server_etag:
            return Response(status_code=status.HTTP_304_NOT_MODIFIED)

    response.headers["ETag"] = etag
    response.headers["Last-Modified"] = format_datetime(transcript.updated_at, usegmt=True)
    response.headers["Cache-Control"] = "private, max-age=300, must-revalidate"

    return TranscriptRead.model_validate(transcript)
