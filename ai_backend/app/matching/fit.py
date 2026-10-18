"""Score how well a resume fits the job title and experience level a Job Seeker chose.

Rule-based and explainable (requirements §4): the score is a system-defined fit
indicator, not a hiring probability.

    overall = 70% skills + 20% experience + 10% education
"""

import re
from dataclasses import dataclass, field
from datetime import date

from app.catalog.skillnames import skill_aliases, text_ngrams

LEVEL_YEARS = {  # expected years of experience per level (min, max)
    "entry": (0, 1),
    "junior": (1, 3),
    "mid": (3, 6),
    "senior": (6, 10),
    "lead": (10, 40),
}
LEVEL_LABELS = {
    "entry": "Internship / Fresh Graduate",
    "junior": "Junior",
    "mid": "Mid-level",
    "senior": "Senior",
    "lead": "Lead / Manager",
}
WEIGHTS = {"skills": 0.7, "experience": 0.2, "education": 0.1}

# Match levels — PROVISIONAL defaults; requirements §5 leaves thresholds TBD.
MATCH_LEVELS = [(80, "Strong Match"), (65, "Good Match"), (45, "Partial Match"), (0, "Low Match")]

MAX_REQUIREMENTS = 15
MIN_ADS_FOR_MARKET = 20   # below this, the role's skills come from ESCO / O*NET instead


@dataclass(frozen=True)
class Requirement:
    name: str
    weight: float
    source: str           # market | tool | essential | optional | llm
    present: bool


@dataclass
class FitResult:
    role: str
    level: str
    score: int
    label: str
    parts: dict[str, float]
    matched: list[Requirement]
    missing: list[Requirement]
    soft_skills_found: list[str]
    years_estimate: float | None
    notes: list[str] = field(default_factory=list)


def match_label(score: float) -> str:
    return next(label for threshold, label in MATCH_LEVELS if score >= threshold)


# ------------------------------------------------------------------ requirements

def requirements_for(role: dict, level: str) -> list[tuple[str, float, str]]:
    """(skill name, weight, source) for this role and level, strongest first."""
    skills = role["skills"]
    reqs: list[tuple[str, float, str]] = []
    if role["postings"]["total"] >= MIN_ADS_FOR_MARKET:
        for s in skills["market_core"] + skills["market_common"]:
            reqs.append((s["name"], s["by_level"].get(level, s["share"]), "market"))
    else:
        reqs += [(name, 0.30, "essential") for name in skills["essential"][:10]]
        reqs += [(name, 0.10, "optional") for name in skills["optional"][:5]]
    reqs += [(s["name"], s["weight"], "llm") for s in skills.get("llm_drafted", [])]
    tool_weight = 0.12 if reqs else 0.25
    reqs += [(name, tool_weight, "tool") for name in skills["tools"][:8]]

    seen, unique = set(), []
    for name, weight, source in sorted(reqs, key=lambda r: -r[1]):
        key = name.lower()
        if key not in seen:
            seen.add(key)
            unique.append((name, weight, source))
    return unique[:MAX_REQUIREMENTS]


def has_skill(name: str, resume_phrases: set[str]) -> bool:
    return bool(skill_aliases(name) & resume_phrases)


# ------------------------------------------------------------------ experience & education

_MONTHS = "jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec"
_RANGE = re.compile(
    rf"(?:(?:{_MONTHS})[a-z]*\.?\s+)?((?:19|20)\d{{2}})\s*(?:-|–|—|to|until)\s*"
    rf"(?:(?:{_MONTHS})[a-z]*\.?\s+)?((?:19|20)\d{{2}}|present|current|now|date|today)",
    re.IGNORECASE,
)
_HEADING = re.compile(r"^\s*(work experience|professional experience|experience|employment history|work history|"
                      r"education|academic|qualifications|skills|projects|certifications|awards|references)\s*:?\s*$",
                      re.IGNORECASE | re.MULTILINE)


def experience_section(text: str) -> str:
    """The text under an experience heading, or the whole text minus education."""
    parts = _HEADING.split(text)
    if len(parts) < 3:
        return text
    chunks = {}
    for i in range(1, len(parts) - 1, 2):
        chunks.setdefault(parts[i].lower(), "")
        chunks[parts[i].lower()] += parts[i + 1]
    experience = "".join(v for k, v in chunks.items() if "experience" in k or "employment" in k or "history" in k)
    if experience:
        return experience
    return parts[0] + "".join(v for k, v in chunks.items() if k not in ("education", "academic", "qualifications"))


def estimate_years(text: str, today: date | None = None) -> float | None:
    """Total years covered by date ranges in the experience section (overlaps merged)."""
    this_year = (today or date.today()).year
    spans = []
    for start, end in _RANGE.findall(experience_section(text)):
        s = int(start)
        e = this_year if not end[0].isdigit() else int(end)
        if 1970 <= s <= e <= this_year:
            spans.append((s, max(e, s + 0.5)))
    if not spans:
        return None
    spans.sort()
    total, (cur_s, cur_e) = 0.0, spans[0]
    for s, e in spans[1:]:
        if s <= cur_e:
            cur_e = max(cur_e, e)
        else:
            total += cur_e - cur_s
            cur_s, cur_e = s, e
    return round(total + cur_e - cur_s, 1)


def experience_score(years: float | None, level: str) -> tuple[float, str | None]:
    low, high = LEVEL_YEARS[level]
    if years is None:
        return (0.6 if level == "entry" else 0.4), "No work dates were found. Add start and end dates to each job."
    if low <= years <= high or (level == "entry" and years <= 1):
        return 1.0, None
    closest = min(LEVEL_YEARS, key=lambda lv: 0 if LEVEL_YEARS[lv][0] <= years <= LEVEL_YEARS[lv][1]
                  else min(abs(years - LEVEL_YEARS[lv][0]), abs(years - LEVEL_YEARS[lv][1])))
    note = (f"Your resume shows about {years:g} years of experience, which is closer to "
            f"{LEVEL_LABELS[closest]} than {LEVEL_LABELS[level]}.")
    if years < low:
        return max(0.2, years / low), note
    return 0.85, note


_DEGREES = [
    (1.0, r"\b(ph\.?d|doctorate|master|msc|m\.sc|mba|m\.eng)\b"),
    (1.0, r"\b(bachelor|degree|bsc|b\.sc|b\.eng|beng|ba|b\.a|bcs|bba)\b"),
    (0.7, r"\b(diploma|advanced diploma|higher national)\b"),
    (0.5, r"\b(stpm|a-level|a level|foundation|matriculation|certificate)\b"),
]


def education_score(text: str) -> tuple[float, str | None]:
    lower = text.lower()
    for score, pattern in _DEGREES:
        if re.search(pattern, lower):
            return score, None
    return 0.3, "No qualification was found. Add your education (degree, diploma or certificate)."


# ------------------------------------------------------------------ main

def score_fit(resume_text: str, role: dict, level: str) -> FitResult:
    if level not in LEVEL_YEARS:
        raise ValueError(f"Unknown level: {level}")
    phrases = text_ngrams(resume_text)
    notes = []

    reqs = requirements_for(role, level)
    checked = [Requirement(n, round(w, 3), src, has_skill(n, phrases)) for n, w, src in reqs]
    total_weight = sum(r.weight for r in checked) or 1
    skills = sum(r.weight for r in checked if r.present) / total_weight

    years = estimate_years(resume_text)
    experience, note = experience_score(years, level)
    if note:
        notes.append(note)
    education, note = education_score(resume_text)
    if note:
        notes.append(note)

    if len(resume_text) < 300:
        notes.append("The resume has very little text, so the score may be unreliable. Add more detail about your skills and work.")
    if role["postings"]["total"] < MIN_ADS_FOR_MARKET:
        notes.append("Few job ads exist for this title, so requirements come from occupation databases.")

    parts = {"skills": round(skills, 3), "experience": round(experience, 3), "education": round(education, 3)}
    # Experience and education only count as far as the background is relevant to this role:
    # years as a data analyst say little about fit for nursing.
    relevance = min(1.0, skills / 0.5)
    overall = round(100 * (parts["skills"] * WEIGHTS["skills"]
                           + relevance * (parts["experience"] * WEIGHTS["experience"]
                                          + parts["education"] * WEIGHTS["education"])))
    if relevance < 1:
        notes.append("Experience and education count only partly because few of the role's key skills were found.")
    soft_found = [s["name"] for s in role["skills"].get("soft", []) if has_skill(s["name"], phrases)]
    return FitResult(
        role=role["title"],
        level=level,
        score=overall,
        label=match_label(overall),
        parts=parts,
        matched=[r for r in checked if r.present],
        missing=[r for r in checked if not r.present],
        soft_skills_found=soft_found,
        years_estimate=years,
        notes=notes,
    )
