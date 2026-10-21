"""Authentication and role checks for API routes."""

from functools import lru_cache
from typing import Annotated
from uuid import UUID

import httpx
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import Settings, get_settings
from app.schemas.user import CurrentUser, UserRole

_bearer = HTTPBearer(auto_error=False)

_UNAUTHORIZED_HEADERS = {"WWW-Authenticate": "Bearer"}


def _unauthorized(message: str) -> HTTPException:
    return HTTPException(status.HTTP_401_UNAUTHORIZED, message, headers=_UNAUTHORIZED_HEADERS)


@lru_cache
def _jwks_client(jwks_url: str) -> jwt.PyJWKClient:
    # Caches Supabase's public keys so they are not downloaded on every request.
    return jwt.PyJWKClient(jwks_url, cache_keys=True, lifespan=600)


def decode_access_token(token: str, settings: Settings) -> dict:
    """Verify a Supabase access token and return its claims, or raise 401."""
    try:
        signing_key = _jwks_client(settings.supabase_jwks_url).get_signing_key_from_jwt(token)
        return jwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256"],
            audience="authenticated",
            issuer=settings.supabase_issuer,
            options={"require": ["exp", "sub", "aud", "iss"]},
        )
    except jwt.ExpiredSignatureError:
        raise _unauthorized("Session expired. Please log in again.")
    except (jwt.PyJWKClientError, jwt.InvalidTokenError):
        raise _unauthorized("Invalid authentication token.")


def fetch_profile(user_id: UUID, token: str, settings: Settings) -> dict | None:
    """Read the caller's own profile row through the Supabase Data API (RLS applies)."""
    try:
        response = httpx.get(
            f"{settings.supabase_url.rstrip('/')}/rest/v1/profiles",
            params={"id": f"eq.{user_id}", "select": "role,account_status"},
            headers={"apikey": settings.supabase_publishable_key, "Authorization": f"Bearer {token}"},
            timeout=10,
        )
        response.raise_for_status()
    except httpx.HTTPError:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "User service is unavailable. Please try again.")
    rows = response.json()
    return rows[0] if rows else None


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> CurrentUser:
    """Dependency: the verified, active caller. Use on any route that needs login."""
    if credentials is None:
        raise _unauthorized("Login required.")

    token = credentials.credentials
    claims = decode_access_token(token, settings)
    user_id = UUID(claims["sub"])

    profile = fetch_profile(user_id, token, settings)
    if profile is None:
        raise _unauthorized("User profile not found.")
    if profile["account_status"] != "active":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "This account is not active.")

    return CurrentUser(
        id=user_id,
        email=claims.get("email"),
        role=UserRole(profile["role"]),
        account_status=profile["account_status"],
        access_token=token,
    )


def require_role(*allowed: UserRole):
    """Dependency factory: allow only the given roles, e.g. require_role(UserRole.ADMIN)."""

    def checker(user: Annotated[CurrentUser, Depends(get_current_user)]) -> CurrentUser:
        if user.role not in allowed:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You do not have permission to do this.")
        return user

    return checker
