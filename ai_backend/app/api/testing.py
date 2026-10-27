"""Testing mode: the Job Seeker analysis without login, results kept in the local logbook."""

import logging
import threading
import time
import uuid
from collections.abc import Callable
from datetime import UTC, datetime
from typing import Annotated, Literal

from fastapi import APIRouter, BackgroundTasks, Body, Depends, File, Form, HTTPException, Request, UploadFile, status
from pydantic import BaseModel, BeforeValidator, Field

from app.llm.advice import coach
from app.llm.client import LLMUnavailable, budget_status, user_status
from app.llm.profile_extract import extract_profile, from_dict
from app.matching.assess import assess
from app.matching.fit import LEVEL_LABELS, score_fit
from app.matching.roles import load_roles
from app.ml.predict import NoDeployedModel, suggest_careers
from app.services import logbook
from app.services.resume_markdown import to_markdown, without_personal_details
from app.services.resume_text import MAX_FILE_BYTES, UnsupportedFile, extract_text

MIN_DIRECTION = 0.05
# Testing mode has no login, so every AI request counts for this one local tester.
TESTER_ID = "local-tester"

logger = logging.getLogger(__name__)
_LOCAL_HOSTS = {"127.0.0.1", "::1", "localhost", "testclient"}


def local_only(request: Request) -> None:
    if request.client is None or request.client.host not in _LOCAL_HOSTS:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Testing mode is only available on this computer.")


router = APIRouter(prefix="/testing", tags=["testing"], dependencies=[Depends(local_only)])


RELATED_ROLES = 4


def _with_skills(profile_dict: dict, extra: list[str]) -> dict:
    return dict(profile_dict, skills=list(profile_dict.get("skills", [])) + list(extra))


def enrich(entry: dict) -> dict:
    """Add skill gains, level scores and related roles (rules only, no AI)."""
    if entry.get("format") != 2 or not entry.get("profile") or entry["assessment"].get("basic_mode"):
        return entry
    role, level, md = _role(entry["role"]["id"]), entry["level"], entry["clean_markdown"]
    profile, base = entry["profile"], entry["assessment"]["score"]
    for row in entry["assessment"].get("skills_detail", []):
        if not row["found"]:
            row["gain"] = assess(from_dict(_with_skills(profile, [row["name"]])), md, role, level).score - base
    entry["level_scores"] = {lv: assess(from_dict(profile), md, role, lv).score for lv in LEVEL_LABELS}
    others = [r for r in load_roles() if r["field"] == role["field"] and r["id"] != role["id"]]
    scored = sorted(((assess(from_dict(profile), md, r, level), r) for r in others), key=lambda x: -x[0].score)
    entry["related_roles"] = [{"id": r["id"], "title": r["title"], "score": a.score, "label": a.label,
                               "to_add": a.core_missing[:4]} for a, r in scored[:RELATED_ROLES]]
    return entry


def _role(role_id: str) -> dict:
    role = next((r for r in load_roles() if r["id"] == role_id), None)
    if role is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unknown job title.")
    return role


@router.get("/catalog")
def catalog() -> dict:
    """Fields, their job titles and the experience levels, for the selection menus."""
    by_field: dict[str, list[dict]] = {}
    for role in load_roles():
        by_field.setdefault(role["field"], []).append({"id": role["id"], "title": role["title"]})
    return {"levels": [{"id": k, "label": v} for k, v in LEVEL_LABELS.items()],
            "fields": [{"field": f, "roles": sorted(r, key=lambda x: x["title"])} for f, r in sorted(by_field.items())]}


def _check_choice(role_id: str, level: str) -> dict:
    role = _role(role_id)
    if level not in LEVEL_LABELS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unknown experience level.")
    return role


def _run(data: bytes, file_name: str, role: dict, level: str, use_llm: bool,
         step: Callable[[str], None] = lambda _: None) -> dict:
    """The whole analysis of one resume. `step` is told which part is running."""
    timings = {}
    t0 = time.perf_counter()
    step("Reading the file")
    try:
        extracted = extract_text(data)
    except UnsupportedFile as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(exc))
    markdown = to_markdown(extracted.text)
    clean = without_personal_details(markdown)
    timings["read_ms"] = round((time.perf_counter() - t0) * 1000)

    # Read the resume with AI; use the simple rules if the AI is down.
    t0 = time.perf_counter()
    profile, profile_error = None, None
    step("Reading the details with AI")
    try:
        profile = extract_profile(clean, user_id=TESTER_ID)
    except LLMUnavailable as exc:
        profile_error = str(exc)
    timings["profile_ms"] = round((time.perf_counter() - t0) * 1000)

    step("Scoring the fit")
    t0 = time.perf_counter()
    if profile is not None:
        result = assess(profile, clean, role, level).to_dict()
    else:
        fit = score_fit(clean, role, level)
        result = {"role": fit.role, "level": level, "score": fit.score, "label": fit.label, "basic_mode": True,
                  "parts": {k: {"score": v, "weight": w, "reasons": []} for (k, v), w in
                            zip(fit.parts.items(), (0.7, 0.2, 0.1))},
                  "core_found": [r.name for r in fit.matched], "core_missing": [r.name for r in fit.missing],
                  "bonus_found": [], "bonus_missing": [], "soft_skills": fit.soft_skills_found,
                  "relevant_years": fit.years_estimate, "total_years": fit.years_estimate,
                  "suggested_level": None, "notes": fit.notes}
    timings["score_ms"] = round((time.perf_counter() - t0) * 1000)

    step("Finding career directions")
    t0 = time.perf_counter()
    try:
        version, suggestions = suggest_careers(extracted.text, top=3)
        # A direction under 5% is noise, not a suggestion ("Arts 1%" for an AI engineer).
        suggestions = suggestions[:1] + [x for x in suggestions[1:] if x.probability >= MIN_DIRECTION]
        directions = {"model_version": version,
                      "items": [{"name": s.name, "label": str(s.label), "probability": s.probability} for s in suggestions]}
    except NoDeployedModel as exc:
        directions = {"model_version": None, "items": [], "error": str(exc)}
    timings["directions_ms"] = round((time.perf_counter() - t0) * 1000)

    entry = {
        "format": 2,
        "id": logbook.new_id(),
        "created_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "file": {"name": file_name, "kind": str(extracted.kind), "method": extracted.method,
                 "pages": extracted.pages, "ocr_pages": extracted.ocr_pages, "warnings": extracted.warnings,
                 "words": len(extracted.text.split())},
        "markdown": markdown,             # full content, kept like the original file
        "clean_markdown": clean,          # personal details removed; what scoring and the AI see
        "profile": profile.to_dict() if profile else None,
        "profile_error": profile_error,
        "role": {"id": role["id"], "title": role["title"], "field": role["field"]},
        "level": level, "level_label": LEVEL_LABELS[level],
        "assessment": result,
        "directions": directions,
        "advice_requested": use_llm, "advice": None, "advice_error": None,
        "feedback": [],
        "timings": timings,
    }
    step("Saving the result")
    enrich(entry)
    logbook.save(entry, data, file_name)
    return entry




@router.post("/analyse")
async def analyse(
    file: Annotated[UploadFile, File()],
    role_id: Annotated[str, Form()],
    level: Annotated[str, Form()],
    use_llm: Annotated[bool, Form()] = False,
) -> dict:
    """Analyse and wait for the result."""
    role = _check_choice(role_id, level)
    data = await file.read(MAX_FILE_BYTES + 1)
    return _run(data, file.filename or "resume", role, level, use_llm)


# Background tasks
# Pending -> Processing -> Completed or Failed. Kept in memory: a server restart clears them.

_TASKS: dict[str, dict] = {}
_TASKS_LOCK = threading.Lock()
MAX_TASKS = 50


def _set_task(task_id: str, **fields) -> None:
    with _TASKS_LOCK:
        _TASKS[task_id].update(fields, updated_at=datetime.now(UTC).isoformat(timespec="seconds"))


def _work(task_id: str, data: bytes, file_name: str, role: dict, level: str, use_llm: bool) -> None:
    _set_task(task_id, status="processing", step="Starting")
    try:
        entry = _run(data, file_name, role, level, use_llm, step=lambda text: _set_task(task_id, step=text))
    except HTTPException as exc:
        _set_task(task_id, status="failed", step=None, error=str(exc.detail))
    except Exception:
        logger.exception("Resume analysis task %s failed", task_id)
        _set_task(task_id, status="failed", step=None,
                  error="Something went wrong while reading this resume. Please try again, or try another file.")
    else:
        _set_task(task_id, status="completed", step=None, entry_id=entry["id"], entry=entry)


@router.post("/tasks")
async def start_analysis(
    background: BackgroundTasks,
    file: Annotated[UploadFile, File()],
    role_id: Annotated[str, Form()],
    level: Annotated[str, Form()],
    use_llm: Annotated[bool, Form()] = False,
) -> dict:
    """Start an analysis in the background; poll GET /testing/tasks/{id} for its status."""
    role = _check_choice(role_id, level)
    data = await file.read(MAX_FILE_BYTES + 1)
    if len(data) > MAX_FILE_BYTES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "The file is larger than 10 MB.")
    now = datetime.now(UTC).isoformat(timespec="seconds")
    task = {"id": uuid.uuid4().hex, "status": "pending", "step": "Waiting to start", "error": None,
            "file_name": file.filename or "resume", "created_at": now, "updated_at": now}
    with _TASKS_LOCK:
        while len(_TASKS) >= MAX_TASKS:  # drop the oldest
            _TASKS.pop(next(iter(_TASKS)))
        _TASKS[task["id"]] = task
    background.add_task(_work, task["id"], data, task["file_name"], role, level, use_llm)
    return dict(task)


@router.get("/tasks/{task_id}")
def task_status(task_id: str) -> dict:
    with _TASKS_LOCK:
        task = _TASKS.get(task_id)
        if task is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "This task was not found. Please analyse the resume again.")
        return dict(task)


@router.get("/usage")
def usage() -> dict:
    """How many AI requests the tester has left today, and whether the monthly AI limit is close."""
    budget = budget_status()
    return {**user_status(TESTER_ID), "monthly_used": budget["used"], "monthly_alert": budget["alert"],
            "monthly_limited": budget["limited"]}


@router.post("/logbook/{entry_id}/advice")
def advice(entry_id: str) -> dict:
    """Write the AI coaching advice for a saved analysis (requested after the score is shown)."""
    entry = logbook.get_entry(entry_id)
    if entry is None or entry.get("format") != 2:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Logbook entry not found.")
    if entry["profile"] is None:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "The resume could not be read in detail, so advice is not available.")
    role = _role(entry["role"]["id"])
    t0 = time.perf_counter()
    try:
        entry["advice"] = coach(role, entry["level_label"], entry["assessment"], from_dict(entry["profile"]).to_dict(),
                                thinking=True, user_id=TESTER_ID).data
        entry["advice_error"] = None
        entry["advice_stale"] = False
    except LLMUnavailable as exc:
        entry["advice_error"] = str(exc)
    entry["advice_requested"] = True
    entry["timings"]["advice_ms"] = round((time.perf_counter() - t0) * 1000)
    logbook.update(entry)
    return {"advice": entry["advice"], "advice_error": entry["advice_error"], "advice_ms": entry["timings"]["advice_ms"]}


def _saved(entry_id: str) -> dict:
    entry = logbook.get_entry(entry_id)
    if entry is None or entry.get("format") != 2:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Logbook entry not found.")
    return entry


@router.post("/logbook/{entry_id}/whatif")
def whatif(entry_id: str, level: Annotated[str, Body()], skills: Annotated[list[str], Body()] = []) -> dict:
    """Preview the score for another level or extra skills. Not saved."""
    entry = _saved(entry_id)
    if level not in LEVEL_LABELS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unknown experience level.")
    if entry["profile"] is None:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "The resume could not be read in detail.")
    profile = from_dict(_with_skills(entry["profile"], [s for s in skills if isinstance(s, str)][:20]))
    return assess(profile, entry["clean_markdown"], _role(entry["role"]["id"]), level).to_dict()


def _blank_to_none(value):
    if isinstance(value, str):
        value = value.strip()
    return value or None


Text = Annotated[str, Field(min_length=1, max_length=80)]
Optional120 = Annotated[Annotated[str, Field(max_length=120)] | None, BeforeValidator(_blank_to_none)]
DateText = Annotated[Annotated[str, Field(pattern=r"^((19|20)\d{2}(-(0?[1-9]|1[0-2]))?|present)$")] | None,
                     BeforeValidator(_blank_to_none)]


class JobIn(BaseModel):
    title: Annotated[str, Field(min_length=1, max_length=120)]
    organisation: Optional120 = None
    start: DateText = None
    end: DateText = None
    type: Literal["full-time", "part-time", "internship", "freelance", "contract", "unknown"] = "unknown"
    highlights: list[Annotated[str, Field(max_length=300)]] = Field(default_factory=list, max_length=3)


class EducationIn(BaseModel):
    level: Literal["SPM", "STPM", "Certificate", "Diploma", "Bachelor", "Master", "PhD", "Professional", "Other"]
    field: Optional120 = None
    institution: Optional120 = None
    end_year: int | None = Field(None, ge=1950, le=2100)


class ProfileIn(BaseModel):
    headline: Optional120 = None
    skills: list[Text] = Field(default_factory=list, max_length=80)
    soft_skills: list[Text] = Field(default_factory=list, max_length=30)
    experience: list[JobIn] = Field(default_factory=list, max_length=20)
    education: list[EducationIn] = Field(default_factory=list, max_length=10)
    certifications: list[Text] = Field(default_factory=list, max_length=30)
    languages: list[Text] = Field(default_factory=list, max_length=15)


def _unique(items: list[str]) -> list[str]:
    seen, out = set(), []
    for item in (i.strip() for i in items):
        if item and item.lower() not in seen:
            seen.add(item.lower())
            out.append(item)
    return out


@router.put("/logbook/{entry_id}/profile")
def edit_profile(entry_id: str, profile: Annotated[ProfileIn, Body(embed=True)]) -> dict:
    """Save the Job Seeker's corrections to what was read from the resume, then score again."""
    entry = _saved(entry_id)
    data = profile.model_dump()
    for key in ("skills", "soft_skills", "certifications", "languages"):
        data[key] = _unique(data[key])
    data["uncertain"] = (entry.get("profile") or {}).get("uncertain", [])
    entry.setdefault("profile_original", entry.get("profile"))  # first version read from the file
    entry["profile"] = from_dict(data).to_dict()
    entry["profile_error"] = None
    entry["profile_edited_at"] = datetime.now(UTC).isoformat(timespec="seconds")
    entry["assessment"] = assess(from_dict(entry["profile"]), entry["clean_markdown"], _role(entry["role"]["id"]),
                                 entry["level"]).to_dict()
    entry.pop("rescored_from", None)
    if entry.get("advice"):
        entry["advice_stale"] = True  # tips were written for the old details
    enrich(entry)
    logbook.update(entry)
    return entry


@router.post("/logbook/{entry_id}/feedback")
def feedback(entry_id: str, section: Annotated[str, Body(max_length=40)], helpful: Annotated[bool, Body()],
             note: Annotated[str, Body(max_length=500)] = "") -> dict:
    """A tester's thumbs up or down on part of the result, kept in the logbook for the evaluation."""
    entry = _saved(entry_id)
    entry.setdefault("feedback", []).append({"section": section, "helpful": helpful, "note": note.strip(),
                                             "at": datetime.now(UTC).isoformat(timespec="seconds")})
    logbook.update(entry)
    return {"saved": len(entry["feedback"])}


@router.get("/logbook")
def logbook_list() -> list[dict]:
    return logbook.list_entries()


@router.get("/logbook/{entry_id}")
def logbook_entry(entry_id: str) -> dict:
    entry = logbook.get_entry(entry_id)
    if entry is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Logbook entry not found.")
    if entry.get("format") == 2 and "level_scores" not in entry:
        # Older entries: re-score with the current rules to fill the newer views (not saved).
        if entry.get("profile") and not entry["assessment"].get("basic_mode"):
            saved_score = entry["assessment"]["score"]
            entry["assessment"] = assess(from_dict(entry["profile"]), entry["clean_markdown"],
                                         _role(entry["role"]["id"]), entry["level"]).to_dict()
            if entry["assessment"]["score"] != saved_score:
                entry["rescored_from"] = saved_score
        enrich(entry)
    return entry
