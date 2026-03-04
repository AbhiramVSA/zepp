"""Tests for Pydantic schema validation."""

import pytest
from pydantic import ValidationError

from app.schemas.auth import LoginRequest, RefreshRequest, SignupRequest, TokenResponse
from app.schemas.transcript import TranscriptBase, TranscriptCreate, TranscriptList, TranscriptRead
from app.schemas.user import UserJWT, UserRead


class TestLoginRequest:
    def test_valid(self):
        req = LoginRequest(email="test@example.com", password="secret")
        assert req.email == "test@example.com"
        assert req.password == "secret"

    def test_invalid_email(self):
        with pytest.raises(ValidationError):
            LoginRequest(email="not-an-email", password="secret")

    def test_empty_password(self):
        with pytest.raises(ValidationError):
            LoginRequest(email="test@example.com", password="")


class TestSignupRequest:
    def test_valid(self):
        req = SignupRequest(email="test@example.com", password="secret123")
        assert req.password == "secret123"

    def test_short_password(self):
        with pytest.raises(ValidationError):
            SignupRequest(email="test@example.com", password="abc")


class TestRefreshRequest:
    def test_valid(self):
        req = RefreshRequest(refresh_token="some-token")
        assert req.refresh_token == "some-token"

    def test_empty_token(self):
        with pytest.raises(ValidationError):
            RefreshRequest(refresh_token="")


class TestTokenResponse:
    def test_all_fields_optional(self):
        resp = TokenResponse()
        assert resp.access_token is None
        assert resp.user_id is None

    def test_with_values(self):
        resp = TokenResponse(
            access_token="tok",
            refresh_token="ref",
            token_type="bearer",
            expires_in=3600,
            user_id="u1",
            email="test@example.com",
        )
        assert resp.expires_in == 3600


class TestTranscriptCreate:
    def test_valid(self):
        t = TranscriptCreate(text="hello world")
        assert t.text == "hello world"
        assert t.confidence is None

    def test_empty_text(self):
        with pytest.raises(ValidationError):
            TranscriptCreate(text="")

    def test_with_metadata(self):
        t = TranscriptCreate(text="hello", meta={"lang": "en"}, confidence=0.95)
        assert t.meta == {"lang": "en"}
        assert t.confidence == 0.95


class TestTranscriptRead:
    def test_from_dict(self):
        data = {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "user-1",
            "text": "hello",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z",
        }
        t = TranscriptRead(**data)
        assert str(t.id) == "550e8400-e29b-41d4-a716-446655440000"
        assert t.user_id == "user-1"


class TestTranscriptList:
    def test_empty_list(self):
        result = TranscriptList(items=[], total=0, limit=50, offset=0)
        assert result.total == 0
        assert result.etag is None


class TestUserRead:
    def test_from_dict(self):
        data = {
            "id": "user-1",
            "email": "test@example.com",
            "is_active": True,
            "is_superuser": False,
            "created_at": "2024-01-01T00:00:00Z",
        }
        u = UserRead(**data)
        assert u.id == "user-1"
        assert u.is_active is True


class TestUserJWT:
    def test_minimal(self):
        u = UserJWT(sub="user-1")
        assert u.sub == "user-1"
        assert u.email is None

    def test_with_email(self):
        u = UserJWT(sub="user-1", email="test@example.com")
        assert u.email == "test@example.com"
