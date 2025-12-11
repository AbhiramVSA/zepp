"""Compatibility entrypoint.

Use ``uvicorn app.main:app`` as the primary entry. This module simply re-exports the app for tools that expect ``api:app``.
"""

from app.main import app  # noqa: F401
