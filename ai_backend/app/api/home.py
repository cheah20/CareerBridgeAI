"""Home data for each role's area."""

from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.security import require_role
from app.schemas.home import HomeResponse
from app.schemas.user import CurrentUser, UserRole

router = APIRouter(tags=["home"])


def _home(user: CurrentUser, area: str) -> HomeResponse:
    return HomeResponse(role=user.role, area=area, email=user.email, server_time=datetime.now(UTC))


@router.get("/seeker/home", response_model=HomeResponse)
def seeker_home(user: Annotated[CurrentUser, Depends(require_role(UserRole.JOB_SEEKER))]) -> HomeResponse:
    return _home(user, "Job Seeker")


@router.get("/recruiter/home", response_model=HomeResponse)
def recruiter_home(user: Annotated[CurrentUser, Depends(require_role(UserRole.RECRUITER))]) -> HomeResponse:
    return _home(user, "Recruiter")


@router.get("/admin/home", response_model=HomeResponse)
def admin_home(user: Annotated[CurrentUser, Depends(require_role(UserRole.ADMIN))]) -> HomeResponse:
    return _home(user, "Admin")
