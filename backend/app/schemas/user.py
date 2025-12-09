from datetime import datetime

from pydantic import BaseModel, EmailStr


class UserRead(BaseModel):
    id: str
    email: EmailStr | None = None
    is_active: bool
    is_superuser: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserJWT(BaseModel):
    sub: str
    email: EmailStr | None = None


class UserCreate(BaseModel):
    id: str
    email: EmailStr | None = None
