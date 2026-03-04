import base64
import hashlib
import logging
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any

from cachetools import TTLCache
from fastapi import HTTPException, status
from jose import JWTError, jwt

logger = logging.getLogger(__name__)

# Cache for verified tokens: token_hash -> (payload, expiry_time)
# Max 1000 tokens, 5 minute TTL (tokens are re-verified after TTL)
_token_cache: TTLCache[str, dict[str, Any]] = TTLCache(maxsize=1000, ttl=300)


def _get_token_hash(token: str) -> str:
    """Generate a hash of the token for cache key (avoids storing raw tokens)."""
    return hashlib.sha256(token.encode()).hexdigest()[:32]


@lru_cache(maxsize=10)
def _prepare_secret(secret: str) -> tuple[str, bytes | str]:
    """
    Determine and cache the correct secret format.
    Returns tuple of (format_type, prepared_secret).
    
    This is called once per unique secret and cached forever,
    eliminating the need to try both formats on every request.
    """
    # Try base64 decoding first (more common for Supabase)
    try:
        decoded = base64.b64decode(secret)
        # Verify it's valid by checking if it decodes to reasonable bytes
        if len(decoded) >= 32:  # JWT secrets should be at least 256 bits
            return ("base64", decoded)
    except Exception:
        pass
    
    # Fall back to raw string
    return ("raw", secret)


def _try_decode_with_secret(
    token: str, 
    secret: bytes | str, 
    options: dict
) -> dict[str, Any] | None:
    """Attempt to decode token with given secret. Returns payload or None."""
    try:
        return jwt.decode(token, secret, algorithms=["HS256"], options=options)
    except JWTError:
        return None


def verify_jwt(token: str, secret: str, audience: str | None = None) -> dict[str, Any]:
    """
    Verify a JWT token with caching for performance.
    
    Optimizations:
    1. Token cache - verified tokens cached for 5 minutes
    2. Secret format cache - correct format determined once per secret
    3. Minimal logging - only log failures, not every verification
    """
    # Check token cache first (fast path)
    token_hash = _get_token_hash(token)
    cached_payload = _token_cache.get(token_hash)
    if cached_payload is not None:
        # Re-check expiry even for cached tokens
        return _check_expiry(cached_payload)
    
    # Get the prepared secret (cached per secret)
    secret_format, prepared_secret = _prepare_secret(secret)
    
    options = {"verify_aud": False}  # Skip audience verification
    
    try:
        # Try with the cached/prepared secret format first
        payload = _try_decode_with_secret(token, prepared_secret, options)
        
        if payload is None:
            # Fallback: try the other format (in case secret changed)
            fallback_secret = secret if secret_format == "base64" else _try_base64_decode(secret)
            if fallback_secret:
                payload = _try_decode_with_secret(token, fallback_secret, options)
        
        if payload is None:
            raise JWTError("Token verification failed")
        
        # Verify expiry
        result = _check_expiry(payload)
        
        # Cache the verified payload
        _token_cache[token_hash] = result
        
        return result
        
    except JWTError as exc:
        logger.warning("JWT verification failed for token hash %s", token_hash[:8])
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid token"
        ) from exc


def _try_base64_decode(secret: str) -> bytes | None:
    """Attempt base64 decode, return None on failure."""
    try:
        return base64.b64decode(secret)
    except Exception:
        return None


def _check_expiry(payload: dict[str, Any]) -> dict[str, Any]:
    """Check if token is expired."""
    exp = payload.get("exp")
    if exp is not None:
        exp_time = datetime.fromtimestamp(exp, tz=timezone.utc)
        if exp_time < datetime.now(timezone.utc):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="Token expired"
            )
    return payload


def invalidate_token_cache(token: str | None = None) -> None:
    """
    Invalidate token cache. Call on logout or token revocation.
    
    Args:
        token: Specific token to invalidate. If None, clears entire cache.
    """
    if token is None:
        _token_cache.clear()
    else:
        token_hash = _get_token_hash(token)
        _token_cache.pop(token_hash, None)
