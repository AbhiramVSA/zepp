import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.config.settings import settings
from app.deps.auth import get_current_user
from app.schemas.auth import LoginRequest, RefreshRequest, TokenResponse, SignupRequest
from app.schemas.user import UserRead

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=TokenResponse)
async def signup(payload: SignupRequest):
    """Register a new user via Supabase Auth."""
    signup_url = f"{settings.SUPABASE_URL}/auth/v1/signup"

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            signup_url,
            headers={
                "apikey": settings.SUPABASE_KEY,
                "Authorization": f"Bearer {settings.SUPABASE_KEY}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={"email": payload.email, "password": payload.password},
        )

    if resp.status_code not in (status.HTTP_200_OK, status.HTTP_201_CREATED):
        error_data = resp.json() if resp.content else {}
        detail = error_data.get("error_description") or error_data.get("msg") or "Signup failed"
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)

    data = resp.json()
    user = data.get("user") or {}
    
    # If email confirmation is required, access_token may be None
    return TokenResponse(
        access_token=data.get("access_token"),
        refresh_token=data.get("refresh_token"),
        token_type=data.get("token_type") or "bearer",
        expires_in=data.get("expires_in"),
        user_id=user.get("id"),
        email=user.get("email"),
    )


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest):
    token_url = f"{settings.SUPABASE_URL}/auth/v1/token?grant_type=password"

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            token_url,
            headers={
                "apikey": settings.SUPABASE_KEY,
                "Authorization": f"Bearer {settings.SUPABASE_KEY}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={"email": payload.email, "password": payload.password},
        )

    if resp.status_code != status.HTTP_200_OK:
        detail = resp.json().get("error_description") if resp.content else "Login failed"
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)

    data = resp.json()
    user = data.get("user") or {}
    return TokenResponse(
        access_token=data.get("access_token"),
        refresh_token=data.get("refresh_token"),
        token_type=data.get("token_type"),
        expires_in=data.get("expires_in"),
        user_id=user.get("id"),
        email=user.get("email"),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshRequest):
    token_url = f"{settings.SUPABASE_URL}/auth/v1/token?grant_type=refresh_token"

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            token_url,
            headers={
                "apikey": settings.SUPABASE_KEY,
                "Authorization": f"Bearer {settings.SUPABASE_KEY}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={"refresh_token": payload.refresh_token},
        )

    if resp.status_code != status.HTTP_200_OK:
        detail = resp.json().get("error_description") if resp.content else "Refresh failed"
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)

    data = resp.json()
    user = data.get("user") or {}
    return TokenResponse(
        access_token=data.get("access_token"),
        refresh_token=data.get("refresh_token"),
        token_type=data.get("token_type"),
        expires_in=data.get("expires_in"),
        user_id=user.get("id"),
        email=user.get("email"),
    )


@router.post("/debug-token")
async def debug_token(token: str):
    """Debug endpoint to test token verification."""
    from jose import jwt
    from app.config.settings import settings
    import base64
    
    result = {"token_length": len(token)}
    
    # Get unverified claims first
    try:
        unverified = jwt.get_unverified_claims(token)
        result["unverified_claims"] = unverified
        result["header"] = jwt.get_unverified_header(token)
    except Exception as e:
        result["decode_error"] = str(e)
        return result
    
    # Try with raw secret
    try:
        payload = jwt.decode(token, settings.SUPABASE_JWT_SECRET, algorithms=["HS256"], options={"verify_aud": False})
        result["raw_secret_success"] = True
        result["payload"] = payload
        return result
    except Exception as e:
        result["raw_secret_error"] = str(e)
    
    # Try with base64 decoded secret
    try:
        decoded_secret = base64.b64decode(settings.SUPABASE_JWT_SECRET)
        payload = jwt.decode(token, decoded_secret, algorithms=["HS256"], options={"verify_aud": False})
        result["base64_secret_success"] = True
        result["payload"] = payload
        return result
    except Exception as e:
        result["base64_secret_error"] = str(e)
    
    return result


@router.get("/whoami", response_model=UserRead)
async def whoami(current_user: UserRead = Depends(get_current_user)):
    return current_user
