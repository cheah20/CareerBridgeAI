import uuid
from typing import Annotated

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.core.errors import register_error_handlers
from app.core.security import require_role
from app.schemas.user import CurrentUser, UserRole
from tests.conftest import make_token


def auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


# ---- /me: authentication ----

def test_me_without_token_is_401(client, profiles):
    response = client.get("/me")

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "unauthorized"
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_me_with_garbage_token_is_401(client, profiles):
    response = client.get("/me", headers=auth_header("not-a-jwt"))

    assert response.status_code == 401


@pytest.mark.parametrize(
    "token_options",
    [
        {"expires_in": -60},                          # expired
        {"audience": "anon"},                         # wrong audience
        {"issuer": "https://evil.example/auth/v1"},   # wrong issuer
        {"signed_by_other_key": True},                # forged signature
    ],
)
def test_me_rejects_invalid_tokens(client, profiles, token_options):
    user_id = uuid.uuid4()
    profiles[user_id] = {"role": "job_seeker", "account_status": "active"}

    response = client.get("/me", headers=auth_header(make_token(user_id, **token_options)))

    assert response.status_code == 401


def test_expired_token_asks_to_log_in_again(client, profiles):
    response = client.get("/me", headers=auth_header(make_token(uuid.uuid4(), expires_in=-60)))

    assert "log in again" in response.json()["error"]["message"]


def test_me_returns_role_from_profile(client, profiles):
    user_id = uuid.uuid4()
    profiles[user_id] = {"role": "recruiter", "account_status": "active"}

    response = client.get("/me", headers=auth_header(make_token(user_id)))

    assert response.status_code == 200
    assert response.json() == {"id": str(user_id), "email": "user@example.test", "role": "recruiter"}


def test_me_without_profile_is_401(client, profiles):
    response = client.get("/me", headers=auth_header(make_token(uuid.uuid4())))

    assert response.status_code == 401


def test_inactive_account_is_403(client, profiles):
    user_id = uuid.uuid4()
    profiles[user_id] = {"role": "job_seeker", "account_status": "pending_deletion"}

    response = client.get("/me", headers=auth_header(make_token(user_id)))

    assert response.status_code == 403


# ---- require_role: authorization ----

@pytest.fixture
def admin_only_client():
    """A tiny app with one admin-only route, to test require_role in isolation."""
    test_app = FastAPI()
    register_error_handlers(test_app)

    @test_app.get("/admin-only")
    def admin_only(user: Annotated[CurrentUser, Depends(require_role(UserRole.ADMIN))]):
        return {"ok": True}

    return TestClient(test_app)


@pytest.mark.parametrize(
    ("role", "expected_status"),
    [("admin", 200), ("recruiter", 403), ("job_seeker", 403)],
)
def test_require_role(admin_only_client, profiles, role, expected_status):
    user_id = uuid.uuid4()
    profiles[user_id] = {"role": role, "account_status": "active"}

    response = admin_only_client.get("/admin-only", headers=auth_header(make_token(user_id)))

    assert response.status_code == expected_status
