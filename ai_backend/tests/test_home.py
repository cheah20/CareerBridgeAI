import uuid

import pytest

from tests.conftest import make_token

AREAS = {"job_seeker": "/seeker/home", "recruiter": "/recruiter/home", "admin": "/admin/home"}


def signed_in(profiles, role: str) -> dict:
    user_id = uuid.uuid4()
    profiles[user_id] = {"role": role, "account_status": "active"}
    return {"Authorization": f"Bearer {make_token(user_id)}"}


@pytest.mark.parametrize("role, path", AREAS.items())
def test_each_role_reaches_its_own_home(client, profiles, role, path):
    response = client.get(path, headers=signed_in(profiles, role))

    assert response.status_code == 200
    assert response.json()["role"] == role


@pytest.mark.parametrize("role", AREAS)
@pytest.mark.parametrize("path", AREAS.values())
def test_other_roles_are_refused(client, profiles, role, path):
    if AREAS[role] == path:
        pytest.skip("own area")
    response = client.get(path, headers=signed_in(profiles, role))

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


@pytest.mark.parametrize("path", AREAS.values())
def test_home_needs_login(client, profiles, path):
    assert client.get(path).status_code == 401


def test_browser_origin_of_the_web_app_is_allowed(client):
    response = client.options("/seeker/home", headers={
        "Origin": "http://localhost:8080", "Access-Control-Request-Method": "GET",
        "Access-Control-Request-Headers": "authorization"})

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:8080"


def test_other_browser_origins_are_not_allowed(client):
    response = client.options("/seeker/home", headers={
        "Origin": "https://evil.example", "Access-Control-Request-Method": "GET"})

    assert "access-control-allow-origin" not in response.headers
