"""Endpoints about the signed-in user."""

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.security import get_current_user
from app.schemas.user import CurrentUser, MeResponse

router = APIRouter(tags=["users"])


@router.get("/me", response_model=MeResponse)
def read_me(user: Annotated[CurrentUser, Depends(get_current_user)]) -> MeResponse:
    """Who am I? The frontend calls this after login to route the user by role."""
    return MeResponse(id=user.id, email=user.email, role=user.role)
