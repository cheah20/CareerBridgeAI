"""Application settings loaded from environment variables / ai_backend/.env."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# ai_backend/ — so .env is found no matter which folder the server starts from.
BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "CareerBridge AI API"
    app_version: str = "0.1.0"

    supabase_url: str
    supabase_publishable_key: str
    # Backend-only key that bypasses RLS. Not needed until later phases.
    supabase_secret_key: str = ""

    # Browser origins allowed to call the API (Flutter web dev server by default).
    cors_origins: list[str] = ["http://localhost:8080"]

    @property
    def supabase_issuer(self) -> str:
        return f"{self.supabase_url.rstrip('/')}/auth/v1"

    @property
    def supabase_jwks_url(self) -> str:
        return f"{self.supabase_issuer}/.well-known/jwks.json"


@lru_cache
def get_settings() -> Settings:
    return Settings()
