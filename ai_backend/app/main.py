"""CareerBridge AI backend entry point.

Run (from ai_backend/, env careerbridge-ai):
    fastapi dev app/main.py        # http://localhost:8000/docs
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import health, users
from app.core.config import get_settings
from app.core.errors import register_error_handlers

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Backend API for the AI Resume and Career Recommendation System.",
)

# Lets the Flutter web app (a different origin) call this API from the browser.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["Authorization", "Content-Type"],
)

register_error_handlers(app)

app.include_router(health.router)
app.include_router(users.router)
