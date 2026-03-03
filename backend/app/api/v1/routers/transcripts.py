from datetime import datetime
from email.utils import parsedate_to_datetime, format_datetime
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
    """
    Create a new transcript for the authenticated user.
    Returns the created transcript with server-assigned ID and timestamps.
    """
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
    """
    List transcripts for the authenticated user with pagination.
    
    Supports conditional fetching for efficient caching:
    
    - If-Modified-Since: Returns 304 Not Modified if no transcripts have been
      updated since the specified timestamp.
    - If-None-Match: Returns 304 Not Modified if the ETag matches, indicating
      the content hasn't changed.
    
    Response headers:
    - Last-Modified: Timestamp of most recently updated transcript
    - ETag: Content-based hash for cache validation
    - Cache-Control: Caching directives for clients
    
    The response includes last_updated and etag fields in the body for clients
    that cannot access response headers (e.g., some mobile HTTP libraries).
    """
    # Get the latest updated_at timestamp for conditional request handling
    last_updated = await crud_transcript.get_last_updated(
        session,
        user_id=current_user.id,
        start_date=start_date,
        end_date=end_date,
        q=q,
    )
    
    # Handle If-Modified-Since conditional request
    # If client's cached data is still fresh, return 304 to save bandwidth
    if if_modified_since and last_updated:
        try:
            client_timestamp = parsedate_to_datetime(if_modified_since)
            # Use UTC comparison; allow 1 second tolerance for rounding
            if last_updated <= client_timestamp:
                response.status_code = status.HTTP_304_NOT_MODIFIED
                return Response(status_code=status.HTTP_304_NOT_MODIFIED)
        except (ValueError, TypeError):
            # Invalid header format, ignore and proceed with full response
            pass
    
    # Fetch items and count
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
    
    # Compute ETag from content
    etag = crud_transcript.compute_etag(items, total)
    
    # Handle If-None-Match conditional request
    # Client sends previously received ETag; if unchanged, return 304
    if if_none_match:
        # Strip quotes and compare
        client_etag = if_none_match.strip('"')
        server_etag = etag.strip('"')
        if client_etag == server_etag:
            response.status_code = status.HTTP_304_NOT_MODIFIED
            return Response(status_code=status.HTTP_304_NOT_MODIFIED)
    
    # Set cache headers for client-side caching
    if last_updated:
        response.headers["Last-Modified"] = format_datetime(last_updated, usegmt=True)
    response.headers["ETag"] = etag
    # Allow private caching, must revalidate after 60 seconds
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
    """
    Get a single transcript by ID.
    
    Enforces user ownership: users can only access their own transcripts.
    Supports ETag-based conditional fetching via If-None-Match header.
    """
    transcript = await crud_transcript.get_by_id(session, transcript_id=transcript_id, user_id=current_user.id)
    if not transcript:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transcript not found")
    
    # Compute single-item ETag from ID and updated_at
    etag = f'"{transcript.id}-{transcript.updated_at.isoformat()}"'
    
    # Handle conditional request
    if if_none_match:
        client_etag = if_none_match.strip('"')
        server_etag = etag.strip('"')
        if client_etag == server_etag:
            return Response(status_code=status.HTTP_304_NOT_MODIFIED)
    
    response.headers["ETag"] = etag
    response.headers["Last-Modified"] = format_datetime(transcript.updated_at, usegmt=True)
    response.headers["Cache-Control"] = "private, max-age=300, must-revalidate"
    
    return TranscriptRead.model_validate(transcript)
