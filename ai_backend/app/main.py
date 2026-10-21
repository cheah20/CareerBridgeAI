"""CareerBridge AI backend entry point."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import health, home, testing, users
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
app.include_router(home.router)

if settings.testing_mode:  # local testing only; see app/api/testing.py
    app.include_router(testing.router)

    @app.on_event("startup")
    def _warm_up() -> None:
        """Load the OCR engine and the career model in the background so the first analysis is not slow."""
        import threading

        def load() -> None:
            from app.ml.predict import _load, deployed_version
            from app.services.resume_text import _get_ocr
            _get_ocr()
            _load(deployed_version())

        threading.Thread(target=load, daemon=True).start()
