"""Read a resume into structured fields with the LLM."""

import json
import re
from dataclasses import dataclass, field
from datetime import date

from app.llm.client import chat_json

MAX_CHARS = 12000

SYSTEM_PROMPT = """You read resumes for CareerBridge AI and turn them into structured data.
The resume text comes from a PDF, Word file or OCR and may have odd line breaks. The person's name and
contact details were removed on purpose; do not mention them.
Rules:
- Copy facts only. Never invent or infer jobs, dates, degrees, skills or employers.
- Dates: "YYYY-MM" when month and year are given, "YYYY" when only the year is given, "present" for a
  current job. Use null when a date is missing or is a template placeholder such as "00/0000" or "20XX".
- Job type: "full-time", "part-time", "internship", "freelance", "contract" or "unknown" (use "unknown"
  unless the resume says it or the title makes it clear, e.g. "Intern").
- Skills: hard skills, tools, software, methods and domain knowledge named in the resume, including ones
  named inside job duties. Short names ("SQL", "Financial reporting"). No soft skills here.
- Soft skills: only ones the resume states or clearly shows (e.g. "presented to senior executives" ->
  "Presentation").
- Education level: "SPM", "STPM", "Certificate", "Diploma", "Bachelor", "Master", "PhD", "Professional"
  (e.g. ACCA, CPA) or "Other". Field: the subject, e.g. "Computer Science", "Marketing".
Reply with JSON exactly like:
{"headline": "current or target job title, or null",
 "skills": ["..."],
 "soft_skills": ["..."],
 "experience": [{"title": "...", "organisation": "... or null", "start": "YYYY-MM|YYYY|null",
                 "end": "YYYY-MM|YYYY|present|null", "type": "...", "highlights": ["at most 3 short facts"]}],
 "education": [{"level": "...", "field": "... or null", "institution": "... or null", "end_year": 2020}],
 "certifications": ["..."],
 "languages": ["..."],
 "uncertain": ["anything you could not read clearly, in a few words"]}"""


@dataclass(frozen=True)
class Job:
    title: str
    organisation: str | None
    start: str | None
    end: str | None
    type: str
    highlights: list[str] = field(default_factory=list)

    def months(self, today: date | None = None) -> int | None:
        """Length of the job in months, or None when the dates are not known."""
        start = _parse(self.start)
        end = _today(today) if (self.end or "").lower() == "present" else _parse(self.end)
        if start is None or end is None or end < start:
            return None
        return (end[0] - start[0]) * 12 + (end[1] - start[1]) + 1


@dataclass(frozen=True)
class Profile:
    headline: str | None
    skills: list[str]
    soft_skills: list[str]
    experience: list[Job]
    education: list[dict]
    certifications: list[str]
    languages: list[str]
    uncertain: list[str]

    def to_dict(self) -> dict:
        return {"headline": self.headline, "skills": self.skills, "soft_skills": self.soft_skills,
                "experience": [j.__dict__ for j in self.experience], "education": self.education,
                "certifications": self.certifications, "languages": self.languages, "uncertain": self.uncertain}


def _today(today: date | None) -> tuple[int, int]:
    t = today or date.today()
    return t.year, t.month


def _parse(value: str | None) -> tuple[int, int] | None:
    m = re.fullmatch(r"((?:19|20)\d{2})(?:-(\d{1,2}))?", (value or "").strip())
    if not m:
        return None
    month = int(m.group(2)) if m.group(2) else 1
    return int(m.group(1)), min(max(month, 1), 12)


def _strings(value) -> list[str]:
    return [str(v).strip() for v in (value or []) if str(v).strip()]


def from_dict(data: dict) -> Profile:
    jobs = [Job(title=str(j.get("title") or "").strip(), organisation=j.get("organisation"), start=j.get("start"),
                end=j.get("end"), type=str(j.get("type") or "unknown"), highlights=_strings(j.get("highlights"))[:3])
            for j in data.get("experience") or [] if (j.get("title") or "").strip()]
    return Profile(headline=data.get("headline"), skills=_strings(data.get("skills")),
                   soft_skills=_strings(data.get("soft_skills")), experience=jobs,
                   education=[e for e in data.get("education") or [] if isinstance(e, dict)],
                   certifications=_strings(data.get("certifications")), languages=_strings(data.get("languages")),
                   uncertain=_strings(data.get("uncertain")))


def extract_profile(clean_markdown: str) -> Profile:
    reply = chat_json(
        [{"role": "system", "content": SYSTEM_PROMPT},
         {"role": "user", "content": f"Today is {date.today():%d %B %Y}. Read this resume into JSON.\n\n"
                                     + clean_markdown[:MAX_CHARS]}],
        purpose="profile_extract", essential=True, max_tokens=3000, temperature=0.0, thinking=False)
    return from_dict(reply.data)


def profile_json(profile: Profile) -> str:
    return json.dumps(profile.to_dict(), ensure_ascii=False, indent=1)
