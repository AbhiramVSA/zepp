from datetime import datetime

from pydantic import BaseModel, EmailStr


class UserRead(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    email: EmailStr | None = None
    is_active: bool
    is_superuser: bool
    created_at: datetime


class UserJWT(BaseModel):
    sub: str
    email: EmailStr | None = None
