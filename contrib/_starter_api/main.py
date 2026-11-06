from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

import llm
import store

app = FastAPI(title="My CareerBridge back end")


class JobIn(BaseModel):
    title: str
    company: str
    location: str
    skills: list[str] = []


class JobUpdate(BaseModel):
    title: str | None = None
    location: str | None = None
    status: str | None = None


# list, with an optional filter
@app.get("/jobs")
def list_jobs(location: str | None = None):
    jobs = store.load()["jobs"]
    if location:
        jobs = [j for j in jobs if location.lower() in j["location"].lower()]
    return jobs


@app.get("/jobs/{job_id}")
def get_job(job_id: int):
    for job in store.load()["jobs"]:
        if job["id"] == job_id:
            return job
    raise HTTPException(404, "Job not found")


@app.post("/jobs", status_code=201)
def add_job(job: JobIn):
    data = store.load()
    new = {"id": max((j["id"] for j in data["jobs"]), default=0) + 1, "status": "draft", **job.model_dump()}
    data["jobs"].append(new)
    store.save(data)
    return new


@app.patch("/jobs/{job_id}")
def update_job(job_id: int, changes: JobUpdate):
    data = store.load()
    for job in data["jobs"]:
        if job["id"] == job_id:
            job.update(changes.model_dump(exclude_none=True))
            store.save(data)
            return job
    raise HTTPException(404, "Job not found")


class Question(BaseModel):
    text: str


# works with or without an api key
@app.post("/ai/summary")
def summary(q: Question):
    answer = llm.ask(f"Summarise this job description in one sentence:\n\n{q.text}")
    if answer is None:
        return {"summary": q.text[:120], "source": "sample"}
    return {"summary": answer, "source": "llm"}
