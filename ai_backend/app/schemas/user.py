"""Response/data shapes related to the signed-in user."""

from enum import StrEnum
from uuid import UUID

from pydantic import BaseModel


class UserRole(StrEnum):
    JOB_SEEKER = "job_seeker"
    RECRUITER = "recruiter"
    ADMIN = "admin"


class CurrentUser(BaseModel):
    """The verified caller: identity from the JWT, role from public.profiles."""

    id: UUID
    email: str | None
    role: UserRole
    account_status: str
    access_token: str  # forwarded to Supabase so RLS applies to backend reads

    model_config = {"frozen": True}


class MeResponse(BaseModel):
    id: UUID
    email: str | None
    role: UserRole
