"""Tests for JWT verification and token caching."""

from datetime import datetime, timezone
from unittest.mock import patch

import pytest
from fastapi import HTTPException
from jose import jwt

from app.utils.security import (
    _check_expiry,
    _get_token_hash,
    _prepare_secret,
    _try_decode_with_secret,
    invalidate_token_cache,
    verify_jwt,
)

# Test secret (base64-encoded 256-bit key)
TEST_SECRET_RAW = "super-secret-key-for-testing-that-is-long-enough-ok"
TEST_ALGORITHM = "HS256"


def _make_token(payload: dict, secret: str = TEST_SECRET_RAW) -> str:
    return jwt.encode(payload, secret, algorithm=TEST_ALGORITHM)


class TestGetTokenHash:
    def test_returns_consistent_hash(self):
        h1 = _get_token_hash("abc")
        h2 = _get_token_hash("abc")
        assert h1 == h2

    def test_different_tokens_give_different_hashes(self):
        h1 = _get_token_hash("token-a")
        h2 = _get_token_hash("token-b")
        assert h1 != h2

    def test_hash_is_32_chars(self):
        h = _get_token_hash("anything")
        assert len(h) == 32


class TestPrepareSecret:
    def test_raw_secret_returned_for_short_string(self):
        fmt, secret = _prepare_secret("short")
        assert fmt == "raw"
        assert secret == "short"

    def test_returns_tuple(self):
        result = _prepare_secret(TEST_SECRET_RAW)
        assert isinstance(result, tuple)
        assert len(result) == 2


class TestTryDecodeWithSecret:
    def test_valid_token_decodes(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        result = _try_decode_with_secret(token, TEST_SECRET_RAW, {"verify_aud": False})
        assert result is not None
        assert result["sub"] == "user-1"

    def test_wrong_secret_returns_none(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        result = _try_decode_with_secret(token, "wrong-secret", {"verify_aud": False})
        assert result is None

    def test_malformed_token_returns_none(self):
        result = _try_decode_with_secret("not.a.token", TEST_SECRET_RAW, {"verify_aud": False})
        assert result is None


class TestCheckExpiry:
    def test_non_expired_token_passes(self):
        payload = {"sub": "user-1", "exp": 9999999999}
        result = _check_expiry(payload)
        assert result == payload

    def test_expired_token_raises(self):
        payload = {"sub": "user-1", "exp": 1000000000}  # Year 2001
        with pytest.raises(HTTPException) as exc_info:
            _check_expiry(payload)
        assert exc_info.value.status_code == 401
        assert "expired" in exc_info.value.detail.lower()

    def test_no_exp_claim_passes(self):
        payload = {"sub": "user-1"}
        result = _check_expiry(payload)
        assert result == payload


class TestVerifyJwt:
    def setup_method(self):
        invalidate_token_cache()
        _prepare_secret.cache_clear()

    def test_valid_token(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        result = verify_jwt(token, TEST_SECRET_RAW)
        assert result["sub"] == "user-1"

    def test_expired_token_raises_401(self):
        token = _make_token({"sub": "user-1", "exp": 1000000000})
        with pytest.raises(HTTPException) as exc_info:
            verify_jwt(token, TEST_SECRET_RAW)
        assert exc_info.value.status_code == 401

    def test_invalid_token_raises_401(self):
        with pytest.raises(HTTPException) as exc_info:
            verify_jwt("garbage.token.here", TEST_SECRET_RAW)
        assert exc_info.value.status_code == 401

    def test_wrong_secret_raises_401(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        with pytest.raises(HTTPException) as exc_info:
            verify_jwt(token, "completely-wrong-secret-string-that-is-long")
        assert exc_info.value.status_code == 401

    def test_caching_returns_same_payload(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        result1 = verify_jwt(token, TEST_SECRET_RAW)
        result2 = verify_jwt(token, TEST_SECRET_RAW)
        assert result1 == result2


class TestInvalidateTokenCache:
    def setup_method(self):
        invalidate_token_cache()
        _prepare_secret.cache_clear()

    def test_invalidate_specific_token(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        verify_jwt(token, TEST_SECRET_RAW)
        invalidate_token_cache(token)
        # Should still work (re-verifies), just not from cache
        result = verify_jwt(token, TEST_SECRET_RAW)
        assert result["sub"] == "user-1"

    def test_invalidate_all(self):
        token = _make_token({"sub": "user-1", "exp": 9999999999})
        verify_jwt(token, TEST_SECRET_RAW)
        invalidate_token_cache()
        # Should still work
        result = verify_jwt(token, TEST_SECRET_RAW)
        assert result["sub"] == "user-1"
