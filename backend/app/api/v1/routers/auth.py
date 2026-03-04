import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.config.settings import settings
from app.deps.auth import get_current_user
from app.schemas.auth import LoginRequest, RefreshRequest, SignupRequest, TokenResponse
from app.schemas.user import UserRead

router = APIRouter(prefix="/auth", tags=["auth"])

_SUPABASE_TIMEOUT = 30


def _supabase_headers() -> dict[str, str]:
    return {
        "apikey": settings.SUPABASE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


def _extract_error(resp: httpx.Response, fallback: str) -> str:
    if not resp.content:
        return fallback
    try:
        data = resp.json()
        return data.get("error_description") or data.get("msg") or fallback
    except Exception:
        return fallback


def _build_token_response(data: dict) -> TokenResponse:
    user = data.get("user") or {}
    return TokenResponse(
        access_token=data.get("access_token"),
        refresh_token=data.get("refresh_token"),
        token_type=data.get("token_type") or "bearer",
        expires_in=data.get("expires_in"),
        user_id=user.get("id"),
        email=user.get("email"),
    )


@router.post("/signup", response_model=TokenResponse)
async def signup(payload: SignupRequest):
    url = f"{settings.SUPABASE_URL}/auth/v1/signup"

    async with httpx.AsyncClient(timeout=_SUPABASE_TIMEOUT) as client:
        resp = await client.post(
            url,
            headers=_supabase_headers(),
            json={"email": payload.email, "password": payload.password},
        )

    if resp.status_code not in (status.HTTP_200_OK, status.HTTP_201_CREATED):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=_extract_error(resp, "Signup failed"),
        )

    return _build_token_response(resp.json())


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest):
    url = f"{settings.SUPABASE_URL}/auth/v1/token?grant_type=password"

    async with httpx.AsyncClient(timeout=_SUPABASE_TIMEOUT) as client:
        resp = await client.post(
            url,
            headers=_supabase_headers(),
            json={"email": payload.email, "password": payload.password},
        )

    if resp.status_code != status.HTTP_200_OK:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=_extract_error(resp, "Login failed"),
        )

    return _build_token_response(resp.json())


@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshRequest):
    url = f"{settings.SUPABASE_URL}/auth/v1/token?grant_type=refresh_token"

    async with httpx.AsyncClient(timeout=_SUPABASE_TIMEOUT) as client:
        resp = await client.post(
            url,
            headers=_supabase_headers(),
            json={"refresh_token": payload.refresh_token},
        )

    if resp.status_code != status.HTTP_200_OK:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=_extract_error(resp, "Refresh failed"),
        )

    return _build_token_response(resp.json())


@router.get("/whoami", response_model=UserRead)
async def whoami(current_user: UserRead = Depends(get_current_user)):
    return current_user
