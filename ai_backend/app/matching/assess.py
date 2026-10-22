"""Fit assessment from a structured resume profile (replaces the text-only rules in fit.py)."""

import math
import re
from dataclasses import dataclass, field

from app.catalog.skillnames import skill_aliases, text_ngrams
from app.llm.profile_extract import Profile
from app.matching.fit import LEVEL_LABELS, LEVEL_YEARS, MATCH_LEVELS, requirements_for
from app.matching.roles import load_roles

# The same job under different names; experience in one counts fully for the other.
CLOSE_ROLES = [{"ai-engineer", "machine-learning-engineer"},
               {"data-analyst", "business-intelligence-bi-analyst"}]
_LEADS = re.compile(r"\b(lead|head|manager|principal|chief|director|supervisor)\b", re.I)
_LED = re.compile(r"\b(led|lead|leading|managed|manage|supervised|supervise|mentored|coached|headed)\b", re.I)
LEAD_WITHOUT_PROOF = 0.7   # lead level asks for leading people or projects
WEIGHTS = {"skills": 0.60, "experience": 0.25, "education": 0.15}
LISTED_ONLY_CREDIT = 0.85          # skill named in a list but not shown in any job
TYPE_FACTOR = {"part-time": 0.5, "internship": 0.5, "freelance": 0.6}
EDUCATION_RANK = {"spm": 1, "stpm": 2, "certificate": 2, "diploma": 3, "bachelor": 4, "professional": 4,
                  "master": 5, "phd": 6}
# Roles that usually ask for a diploma or less instead of a degree.
DIPLOMA_ROLES = {"clinic-assistant", "call-centre-agent", "customer-service-executive", "admin-executive", "cabin-crew",
                 "chef", "warehouse-supervisor", "site-supervisor", "inventory-executive", "shipping-executive",
                 "front-office-executive", "personal-trainer", "property-negotiator", "insurance-agent-financial-planner",
                 "it-support-executive", "draughtsman", "personal-assistant", "outlet-manager", "event-executive",
                 "travel-consultant", "photographer", "video-editor", "sales-executive", "tuition-teacher"}
# Subjects that fit each CareerBridge field (for the education field check).
FIELD_STUDIES = {
    "Information & Communication Technology": "computer|software|information technology|information system|it\\b|"
                                              "network|cyber|data|engineering|mathematics|multimedia|info-communication",
    "Data & Artificial Intelligence": "data|statistic|mathematics|computer|artificial intelligence|machine learning|"
                                      "information|actuarial|physics|engineering|economics",
    "Engineering": "engineering|mechanical|electrical|electronic|civil|chemical|mechatronic|manufacturing|physics",
    "Accounting & Finance": "accounting|accountancy|finance|commerce|economics|business|actuarial|acca|cpa|cima|"
                            "banking|mathematics",
    "Banking & Insurance": "banking|finance|accounting|economics|business|commerce|insurance|actuarial|mathematics",
    "Business & Management": "business|management|economics|commerce|administration|engineering|supply chain|logistics",
    "Sales & Marketing": "marketing|business|communication|advertising|commerce|mass comm|media|management",
    "Human Resources": "human resource|psychology|business|management|administration|industrial relations",
    "Design, Media & Communications": "design|art|media|communication|multimedia|journalism|film|animation|fashion",
    "Architecture & Construction": "architecture|quantity surveying|construction|civil|building|engineering|surveying|"
                                   "real estate",
    "Healthcare & Wellness": "medicine|medical|nursing|pharmacy|health|biomedical|physiotherapy|nutrition|dietetics|"
                            "radiography|science|sport",
    "Education & Training": "education|teaching|tesl|pendidikan|psychology|science|mathematics|language",
    "Legal": "law|llb|legal|syariah",
    "Hospitality, Food & Tourism": "hospitality|hotel|tourism|culinary|food|event",
    "Logistics, Transport & Aviation": "logistics|supply chain|transport|aviation|aeronautic|maritime|shipping|"
                                       "business|aircraft",
    "Science & Agriculture": "science|chemistry|biology|biotechnology|agriculture|plantation|environment|"
                             "food science|microbiology",
    "Administration & Customer Service": "business|administration|management|office|secretarial|communication",
}
_SENIORITY = re.compile(r"\b(senior|sr|junior|jr|lead|head|chief|principal|assistant|associate|trainee|intern|"
                        r"executive|manager|officer|specialist|i{1,3}|1|2|3)\b", re.IGNORECASE)


@dataclass
class Part:
    score: float | None          # 0-1, None = could not be judged
    weight: float
    reasons: list[str] = field(default_factory=list)


@dataclass
class Assessment:
    role: str
    level: str
    score: int
    label: str
    parts: dict[str, Part]
    core_found: list[str]
    core_missing: list[str]
    bonus_found: list[str]
    bonus_missing: list[str]
    soft_skills: list[str]
    relevant_years: float | None
    total_years: float | None
    suggested_level: str | None
    notes: list[str] = field(default_factory=list)
    skills_detail: list[dict] = field(default_factory=list)  # one row per required skill, for the skill explorer

    def to_dict(self) -> dict:
        return {"role": self.role, "level": self.level, "score": self.score, "label": self.label,
                "parts": {k: {"score": None if p.score is None else round(p.score, 3), "weight": round(p.weight, 3),
                              "reasons": p.reasons} for k, p in self.parts.items()},
                "core_found": self.core_found, "core_missing": self.core_missing, "bonus_found": self.bonus_found,
                "bonus_missing": self.bonus_missing, "soft_skills": self.soft_skills,
                "relevant_years": self.relevant_years, "total_years": self.total_years,
                "suggested_level": self.suggested_level, "notes": self.notes, "skills_detail": self.skills_detail}


# ------------------------------------------------------------------ skills

def _work_text(profile: Profile, markdown: str) -> str:
    """Text that shows skills being used: job titles, job highlights and the experience section."""
    section = re.search(r"^## [^\n]*(experience|employment|history|career)[^\n]*\n(.*?)(?=^## |\Z)", markdown,
                        re.IGNORECASE | re.MULTILINE | re.DOTALL)
    jobs = " ".join(f"{j.title} {' '.join(j.highlights)}" for j in profile.experience)
    return jobs + " " + (section.group(2) if section else "")


def _evidence(aliases: set[str], profile: Profile, markdown: str) -> dict | None:
    """Where a skill shows up: a job line first, otherwise the first resume line that names it."""
    for job in profile.experience:
        for line in job.highlights:
            if aliases & text_ngrams(line):
                return {"where": job.organisation or job.title, "text": line}
    section = "Resume"
    for line in markdown.split("\n"):
        line = line.strip()
        if line.startswith("## "):
            section = line[3:].strip()
        elif line and aliases & text_ngrams(line):
            return {"where": section, "text": line.lstrip("- ").strip()}
    for skill in profile.skills:
        if aliases & text_ngrams(skill):
            return {"where": "Skills", "text": skill}
    return None


def _skills(profile: Profile, markdown: str, role: dict, level: str) -> tuple[Part, list, list, list, list, list]:
    reqs = requirements_for(role, level)
    if not reqs:
        return Part(None, WEIGHTS["skills"], ["This job title has no skill list yet."]), [], [], [], [], []
    n_core = max(3, math.ceil(0.4 * len(reqs)))
    core, bonus = reqs[:n_core], reqs[n_core:]
    everything = text_ngrams(markdown) | {p for s in profile.skills for p in text_ngrams(s)}
    at_work = text_ngrams(_work_text(profile, markdown))

    def credit(name: str) -> float:
        aliases = skill_aliases(name)
        if aliases & at_work:
            return 1.0
        return LISTED_ONLY_CREDIT if aliases & everything else 0.0

    def coverage(group):
        total = sum(w for _, w, _ in group) or 1
        return sum(w * credit(n) for n, w, _ in group) / total

    score = 0.7 * coverage(core) + 0.3 * (coverage(bonus) if bonus else coverage(core))
    core_found = [n for n, _, _ in core if credit(n)]
    core_missing = [n for n, _, _ in core if not credit(n)]
    bonus_found = [n for n, _, _ in bonus if credit(n)]
    bonus_missing = [n for n, _, _ in bonus if not credit(n)]
    reasons = [f"{len(core_found)} of {len(core)} core skills and {len(bonus_found)} of {len(bonus)} bonus skills found."]
    detail = []
    for i, (name, weight, source) in enumerate(reqs):
        c = credit(name)
        detail.append({"name": name, "core": i < n_core,
                       "share": round(100 * weight) if source == "market" else None,  # % of job ads asking for it
                       "found": None if not c else ("work" if c == 1.0 else "listed"),
                       "evidence": _evidence(skill_aliases(name), profile, markdown) if c else None})
    return Part(score, WEIGHTS["skills"], reasons), core_found, core_missing, bonus_found, bonus_missing, detail


# ------------------------------------------------------------------ experience

def _tokens(title: str) -> set[str]:
    """Title words without seniority, cut short so Science and Scientist match."""
    return {w[:5] for w in re.findall(r"[a-z]+", _SENIORITY.sub(" ", title.lower()))}


def _overlap(job: set[str], role: dict) -> float:
    return max(len(job & _tokens(n)) / (len(_tokens(n)) or 1) for n in [role["title"], *role["aka"]])


def _title_relevance(job_title: str, role: dict) -> float:
    """1.0 same role, 0.6 same field, 0 other work."""
    job = _tokens(job_title)
    if not job:
        return 0.0
    close = next((g for g in CLOSE_ROLES if role["id"] in g), {role["id"]})
    matches = [r for r in load_roles() if _overlap(job, r) >= 0.6]
    if any(r["id"] in close for r in matches):
        return 1.0
    if any(r["field"] == role["field"] for r in matches):
        return 0.6
    return 0.0


def _skills_in(text: str, role: dict, level: str) -> int:
    phrases = text_ngrams(text)
    return sum(1 for name, _, _ in requirements_for(role, level) if skill_aliases(name) & phrases)


def _merged_years(spans: list[tuple[int, int]]) -> float:
    """Calendar years covered by month spans (overlaps counted once)."""
    covered: set[int] = set()
    for start, length in spans:
        covered.update(range(start, start + length))
    return round(len(covered) / 12, 1)


def _experience(profile: Profile, role: dict, level: str) -> tuple[Part, float | None, float | None, str | None]:
    weighted_months, spans, undated = 0.0, [], 0
    for job in profile.experience:
        months = job.months()
        if months is None:
            undated += 1
            continue
        relevance = _title_relevance(job.title, role)
        if relevance < 0.6 and _skills_in(f"{job.title} {' '.join(job.highlights)}", role, level) >= 2:
            relevance = 0.6  # different title, but the duties use this role's skills (e.g. Clerk -> Admin Executive)
        factor = 1.0 if level == "entry" else TYPE_FACTOR.get(job.type, 1.0)
        weighted_months += months * relevance * factor
        start = job.start or ""
        y, m = (int(start[:4]), int(start[5:7]) if len(start) >= 7 else 1)
        spans.append((y * 12 + m, months))
    if not spans:
        if level == "entry":
            return Part(None, WEIGHTS["experience"], ["Not needed for this level."]), None, None, None
        reason = ("We could not read the dates of your work history, so experience is not counted in this score."
                  if profile.experience else "No work experience was found, so experience is not counted in this score.")
        return Part(None, WEIGHTS["experience"], [reason]), None, None, None

    total = _merged_years(spans)
    relevant = round(min(weighted_months / 12, total), 1)
    low, high = LEVEL_YEARS[level]
    if level == "entry" or relevant >= low:
        score = 1.0
    else:
        score = max(0.15, relevant / low)
    suggested = next((lv for lv, (lo, hi) in LEVEL_YEARS.items() if lo <= relevant < hi), "lead")
    led = any(_LEADS.search(j.title) or any(_LED.search(h) for h in j.highlights) for j in profile.experience)
    if suggested == "lead" and not any(_LEADS.search(j.title) for j in profile.experience):
        suggested = "senior"  # many years alone do not make a lead role; that needs leading people or teams
    lead_note = level == "lead" and relevant > 0 and not led
    if lead_note:
        score = min(score, LEAD_WITHOUT_PROOF)
    if relevant == 0:
        reasons = [f"Your {total:g} years of work are in a different area, so they are not counted as {role['title']} "
                   "experience yet. They still show reliability and skills you can carry over."]
        suggested = level
    else:
        reasons = [f"About {relevant:g} years of experience related to {role['title']} (about {total:g} years of work in total)."]
    if undated:
        reasons.append(f"{undated} job(s) had no readable dates and were not counted.")
    if lead_note:
        reasons.append("Lead roles also look for leading people or projects. Add where you led a team or a project.")
    if suggested != level:
        reasons.append(f"Your related experience matches {LEVEL_LABELS[suggested]} more closely than {LEVEL_LABELS[level]}.")
    return Part(score, WEIGHTS["experience"], reasons), relevant, total, suggested if suggested != level else None


# ------------------------------------------------------------------ education

def _education(profile: Profile, role: dict) -> Part:
    if not profile.education:
        return Part(None, WEIGHTS["education"], ["No education was found, so education is not counted in this score."])
    expected = 3 if role["id"] in DIPLOMA_ROLES else 4
    pattern = re.compile(FIELD_STUDIES.get(role["field"], "$^"), re.IGNORECASE)
    role_words = _tokens(role["title"])
    best, best_reason = 0.0, ""
    for e in profile.education:
        rank = EDUCATION_RANK.get(str(e.get("level") or "").lower(), 1)
        level_score = min(1.0, rank / expected)
        subject = str(e.get("field") or "")
        if not subject:
            relevance, why = 0.8, "field of study not stated"
        elif pattern.search(subject) or role_words & _tokens(subject):
            relevance, why = 1.0, f"{subject} is related to this field"
        else:
            relevance, why = 0.6, f"{subject} is less related to this field"
        if level_score * relevance > best:
            best = level_score * relevance
            best_reason = f"{e.get('level') or 'Qualification'}: {why}."
    return Part(best, WEIGHTS["education"], [best_reason])


# ------------------------------------------------------------------ overall

def assess(profile: Profile, clean_markdown: str, role: dict, level: str) -> Assessment:
    if level not in LEVEL_YEARS:
        raise ValueError(f"Unknown level: {level}")
    skills, core_found, core_missing, bonus_found, bonus_missing, detail = _skills(profile, clean_markdown, role, level)
    experience, relevant, total, suggested = _experience(profile, role, level)
    education = _education(profile, role)
    parts = {"skills": skills, "experience": experience, "education": education}

    known = {k: p for k, p in parts.items() if p.score is not None}
    weight_sum = sum(p.weight for p in known.values()) or 1
    for p in known.values():
        p.weight = p.weight / weight_sum  # re-weight over the parts that could be judged
    for p in parts.values():
        if p.score is None:
            p.weight = 0.0
    # Experience and education only count as far as the skills are relevant to this role.
    gate = min(1.0, (skills.score or 0) / 0.3)
    overall = 0.0
    for k, p in known.items():
        overall += p.score * p.weight * (1.0 if k == "skills" else gate)
    score = round(100 * overall)
    notes = []
    if gate < 1:
        notes.append("Experience and education count only partly because few of this role's key skills were found.")
    soft = sorted(set(profile.soft_skills))
    return Assessment(role=role["title"], level=level, score=score,
                      label=next(lbl for t, lbl in MATCH_LEVELS if score >= t), parts=parts,
                      core_found=core_found, core_missing=core_missing, bonus_found=bonus_found,
                      bonus_missing=bonus_missing, soft_skills=soft, relevant_years=relevant, total_years=total,
                      suggested_level=suggested, notes=notes, skills_detail=detail)
