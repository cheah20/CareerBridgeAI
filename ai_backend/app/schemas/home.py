"""Response shape for the role home endpoints."""

from datetime import datetime

from pydantic import BaseModel

from app.schemas.user import UserRole


class HomeResponse(BaseModel):
    role: UserRole
    area: str          # e.g. "Job Seeker"
    email: str | None
    server_time: datetime
