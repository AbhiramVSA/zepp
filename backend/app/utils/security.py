import logging
from datetime import datetime, timezone
from typing import Any, Dict

from fastapi import HTTPException, status
from jose import JWTError, jwt

logger = logging.getLogger(__name__)


def verify_jwt(token: str, secret: str, audience: str | None = None) -> Dict[str, Any]:
    try:
        payload = jwt.decode(token, secret, algorithms=["HS256"], audience=audience)
    except JWTError as exc:
        logger.warning("JWT verification failed: %s", exc)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc

    exp = payload.get("exp")
    if exp is not None and datetime.fromtimestamp(exp, tz=timezone.utc) < datetime.now(timezone.utc):
        logger.info("JWT expired")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")

    return payload
