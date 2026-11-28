from typing import Literal

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import llm
import store

app = FastAPI(title="CareerBridge Recruiter & Jobs API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

RejectionReason = Literal[
    "Missing skill",
    "Not enough experience",
    "Missing certificate",
    "Role filled",
]

ALLOWED_STATUSES = {
    "Applied",
    "Under Review",
    "Shortlisted",
    "Interview",
    "Offer",
    "Hired",
    "Rejected",
    "Withdrawn",
}

# Made-up sample pool for simulator preview (400 profiles total)
SAMPLE_POOL_SIZE = 400
SAMPLE_SHUTOUT_COUNTS = {
    "flutter": 245,
    "dart": 268,
    "rest_api": 192,
    "exp_1_plus": 294,
    "bachelors": 164,
    "kl_selangor": 148,
}


class JobIn(BaseModel):
    title: str
    company: str
    location: str
    min_salary: int = 3000
    work_type: str = "Full-time"
    experience_level: str = "Junior"
    industry: str = "Information Technology"
    description: str = ""
    skills: list[str] = []


class JobUpdate(BaseModel):
    title: str | None = None
    location: str | None = None
    min_salary: int | None = None
    work_type: str | None = None
    experience_level: str | None = None
    industry: str | None = None
    status: str | None = None


class StatusUpdateIn(BaseModel):
    status: str
    rejection_reason: RejectionReason | None = None


class Question(BaseModel):
    text: str


class SimulatorRequest(BaseModel):
    enabled_requirements: list[str] = [
        "flutter",
        "dart",
        "rest_api",
        "exp_1_plus",
        "bachelors",
        "kl_selangor",
    ]


@app.get("/health")
def health():
    return {"status": "ok", "service": "careerbridge-recruiter-api"}


@app.get("/company")
def get_company():
    return store.load().get("company", {})


@app.get("/jobs")
def list_jobs(
    location: str | None = None,
    min_salary: int | None = None,
    work_type: str | None = None,
    experience_level: str | None = None,
    industry: str | None = None,
    status: str | None = None,
):
    jobs = store.load().get("jobs", [])
    if location:
        jobs = [j for j in jobs if location.lower() in j.get("location", "").lower()]
    if min_salary is not None:
        jobs = [j for j in jobs if j.get("min_salary", 0) >= min_salary]
    if work_type:
        jobs = [j for j in jobs if work_type.lower() == j.get("work_type", "").lower()]
    if experience_level:
        jobs = [
            j
            for j in jobs
            if experience_level.lower() in j.get("experience_level", "").lower()
        ]
    if industry:
        jobs = [j for j in jobs if industry.lower() in j.get("industry", "").lower()]
    if status:
        jobs = [j for j in jobs if status.lower() == j.get("status", "").lower()]
    return sorted(jobs, key=lambda j: j.get("match_score", 0), reverse=True)


@app.get("/jobs/{job_id}")
def get_job(job_id: int):
    for job in store.load().get("jobs", []):
        if job["id"] == job_id:
            return job
    raise HTTPException(404, "Job not found")


@app.post("/jobs", status_code=201)
def add_job(job: JobIn):
    data = store.load()
    jobs = data.setdefault("jobs", [])
    new = {
        "id": max((j["id"] for j in jobs), default=0) + 1,
        "status": "draft",
        "match_score": 80,
        "matching_skills": job.skills[:2],
        "missing_skills": job.skills[2:],
        **job.model_dump(),
    }
    jobs.append(new)
    store.save(data)
    return new


@app.patch("/jobs/{job_id}")
def update_job(job_id: int, changes: JobUpdate):
    data = store.load()
    for job in data.get("jobs", []):
        if job["id"] == job_id:
            job.update(changes.model_dump(exclude_none=True))
            store.save(data)
            return job
    raise HTTPException(404, "Job not found")


@app.get("/jobs/{job_id}/applicants")
def list_job_applicants(job_id: int):
    applicants = [
        a for a in store.load().get("applicants", []) if a.get("job_id") == job_id
    ]
    return sorted(applicants, key=lambda a: a.get("match_score", 0), reverse=True)


@app.patch("/applications/{app_id}/status")
def update_application_status(app_id: int, payload: StatusUpdateIn):
    if payload.status not in ALLOWED_STATUSES:
        raise HTTPException(400, "Invalid application status")
    if payload.status == "Rejected" and not payload.rejection_reason:
        raise HTTPException(
            400,
            "Rejection reason is required when status is Rejected (Missing skill, Not enough experience, Missing certificate, Role filled)",
        )
    if payload.status != "Rejected" and payload.rejection_reason is not None:
        raise HTTPException(
            400, "Rejection reason can only be set when status is Rejected"
        )

    data = store.load()
    for applicant in data.get("applicants", []):
        if applicant["id"] == app_id:
            applicant["status"] = payload.status
            applicant["rejection_reason"] = (
                payload.rejection_reason if payload.status == "Rejected" else None
            )
            store.save(data)
            return applicant
    raise HTTPException(404, "Applicant not found")


@app.post("/simulator/counts")
def simulator_counts(req: SimulatorRequest):
    enabled = set(req.enabled_requirements)
    remaining = SAMPLE_POOL_SIZE
    for idx, key in enumerate(req.enabled_requirements):
        shutout = SAMPLE_SHUTOUT_COUNTS.get(key, 120)
        drop_factor = (shutout / SAMPLE_POOL_SIZE) * (0.85 if idx == 0 else 0.42)
        remaining = max(8, round(remaining * (1 - drop_factor)))

    breakdown = [
        {
            "id": key,
            "shutout": count,
            "enabled": key in enabled,
        }
        for key, count in sorted(
            SAMPLE_SHUTOUT_COUNTS.items(), key=lambda x: x[1], reverse=True
        )
    ]

    return {
        "source": "sample_data",
        "pool_size": SAMPLE_POOL_SIZE,
        "fitting_candidates": remaining if enabled else SAMPLE_POOL_SIZE,
        "requirements": breakdown,
    }


# works with or without an api key
@app.post("/ai/summary")
def summary(q: Question):
    answer = llm.ask(f"Summarise this job description in one sentence:\n\n{q.text}")
    if answer is None:
        return {"summary": q.text[:120], "source": "sample"}
    return {"summary": answer, "source": "llm"}