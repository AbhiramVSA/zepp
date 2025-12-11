import base64
import logging
from datetime import datetime, timezone
from typing import Any, Dict

from fastapi import HTTPException, status
from jose import JWTError, jwt

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)


def verify_jwt(token: str, secret: str, audience: str | None = None) -> Dict[str, Any]:
    logger.info(f"Verifying JWT token (length: {len(token)})")
    logger.debug(f"Secret length: {len(secret)}, first 20 chars: {secret[:20]}...")
    
    try:
        # Supabase JWTs use HS256 with the JWT secret from dashboard
        # The audience can be empty string or None
        options = {"verify_aud": False}  # Always skip audience verification
        
        # Try with the raw secret string first (Supabase may use it directly)
        try:
            payload = jwt.decode(
                token, 
                secret, 
                algorithms=["HS256"], 
                options=options
            )
            logger.info("JWT verified successfully with raw secret")
            return _check_expiry(payload)
        except JWTError as e1:
            logger.debug(f"Raw secret failed: {e1}")
            
            # Try to decode the secret as base64
            try:
                decoded_secret = base64.b64decode(secret)
                payload = jwt.decode(
                    token, 
                    decoded_secret, 
                    algorithms=["HS256"], 
                    options=options
                )
                logger.info("JWT verified successfully with base64-decoded secret")
                return _check_expiry(payload)
            except Exception as e2:
                logger.debug(f"Base64-decoded secret failed: {e2}")
                raise e1  # Re-raise original error
                
    except JWTError as exc:
        logger.warning("JWT verification failed: %s", exc)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc


def _check_expiry(payload: Dict[str, Any]) -> Dict[str, Any]:
    exp = payload.get("exp")
    if exp is not None and datetime.fromtimestamp(exp, tz=timezone.utc) < datetime.now(timezone.utc):
        logger.info("JWT expired")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")
    return payload
