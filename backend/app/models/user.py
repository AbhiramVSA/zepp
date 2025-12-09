from sqlalchemy import Boolean, Column, String, func
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import TIMESTAMP

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)  # Supabase sub
    email = Column(String, unique=True, index=True, nullable=True)
    is_active = Column(Boolean, nullable=False, server_default="true")
    is_superuser = Column(Boolean, nullable=False, server_default="false")
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    transcripts = relationship("Transcript", back_populates="user", cascade="all, delete-orphan")
