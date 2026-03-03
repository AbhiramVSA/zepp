import uuid

from sqlalchemy import Column, Float, ForeignKey, Index, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class Transcript(Base):
    """
    Transcript model representing a single transcription record.
    
    The updated_at column enables conditional fetching via If-Modified-Since
    and ETag headers, allowing clients to skip re-downloading unchanged data.
    """
    __tablename__ = "transcripts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    text = Column(Text, nullable=False)
    confidence = Column(Float, nullable=True)
    duration_seconds = Column(Float, nullable=True)
    meta = Column("metadata", JSONB, nullable=True)
    audio_url = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False, index=True)
    # updated_at tracks the last modification time for conditional fetching.
    # Automatically set on insert and updated on any row modification via onupdate.
    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
        index=True,
    )

    user = relationship("User", back_populates="transcripts")

    __table_args__ = (
        Index("ix_transcripts_user_created_desc", user_id, created_at.desc()),
        Index("ix_transcripts_user_updated_desc", user_id, updated_at.desc()),
    )
