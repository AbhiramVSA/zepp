from fastapi import APIRouter, Depends

from app.deps.auth import get_current_user
from app.schemas.user import UserRead

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/whoami", response_model=UserRead)
async def whoami(current_user: UserRead = Depends(get_current_user)):
    return current_user
