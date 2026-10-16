"""Shared test setup: fake Supabase settings and a local ES256 key pair.

Tests never call the real Supabase project. Tokens are signed with a key pair
generated here, and the JWKS lookup / profile lookup are replaced with fakes.
"""

import os
import time
import uuid

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import ec

TEST_SUPABASE_URL = "https://test-project.supabase.co"

# Environment variables take priority over ai_backend/.env.
os.environ["SUPABASE_URL"] = TEST_SUPABASE_URL
os.environ["SUPABASE_PUBLISHABLE_KEY"] = "sb_publishable_test"

from fastapi.testclient import TestClient  # noqa: E402

from app.core import security  # noqa: E402
from app.core.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402

get_settings.cache_clear()

_PRIVATE_KEY = ec.generate_private_key(ec.SECP256R1())
_OTHER_PRIVATE_KEY = ec.generate_private_key(ec.SECP256R1())


class _FakeSigningKey:
    key = _PRIVATE_KEY.public_key()


class _FakeJwksClient:
    def get_signing_key_from_jwt(self, token):
        return _FakeSigningKey()


def make_token(
    user_id: uuid.UUID,
    *,
    expires_in: int = 3600,
    audience: str = "authenticated",
    issuer: str = f"{TEST_SUPABASE_URL}/auth/v1",
    signed_by_other_key: bool = False,
) -> str:
    now = int(time.time())
    claims = {
        "sub": str(user_id),
        "email": "user@example.test",
        "aud": audience,
        "iss": issuer,
        "role": "authenticated",
        "iat": now,
        "exp": now + expires_in,
    }
    key = _OTHER_PRIVATE_KEY if signed_by_other_key else _PRIVATE_KEY
    return jwt.encode(claims, key, algorithm="ES256", headers={"kid": "test-key"})


@pytest.fixture
def profiles(monkeypatch):
    """Fake public.profiles: tests put {user_id: {"role":..., "account_status":...}} here."""
    rows: dict[uuid.UUID, dict] = {}
    monkeypatch.setattr(security, "_jwks_client", lambda url: _FakeJwksClient())
    monkeypatch.setattr(security, "fetch_profile", lambda user_id, token, settings: rows.get(user_id))
    return rows


@pytest.fixture
def client():
    return TestClient(app)
