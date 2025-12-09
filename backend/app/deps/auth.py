from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.crud import user as crud_user
from app.db.database import get_session
from app.schemas.user import UserJWT, UserRead
from app.utils.security import verify_jwt

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> UserRead:
    if not credentials or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    payload = verify_jwt(
        token=credentials.credentials,
        secret=settings.SUPABASE_JWT_SECRET,
        audience=settings.JWT_AUDIENCE,
    )

    try:
        jwt_user = UserJWT.model_validate(payload)
    except ValidationError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

    user = await crud_user.create_if_not_exists(session, user_id=jwt_user.sub, email=jwt_user.email)
    return UserRead.model_validate(user)
