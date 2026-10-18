"""Use the LLM to explain a fit result and generate advice (requirements §4, §5).

The LLM receives the system's own score and skill lists and explains them; it
never computes the score and must not present it as a hiring probability.
"""

import json

from app.llm.client import LLMReply, chat_json
from app.llm.redact import redact_personal_info
from app.matching.fit import LEVEL_LABELS, FitResult

MAX_RESUME_CHARS = 6000

SYSTEM_PROMPT = """You are the career advisor inside CareerBridge AI, a job platform for Malaysia and Singapore.
Rules:
- Use only the information provided. Do not invent experience, qualifications, employers or numbers.
- The match score was calculated by the system. It is a fit indicator, NOT a probability of being hired; never describe it as a hiring chance.
- If information is missing from the resume, say what is missing and how to add it.
- Be specific, practical and encouraging. Use plain English suitable for students and fresh graduates.
- Suggestions must suit the Malaysian / Singaporean job market.
Reply with a single JSON object in exactly this structure:
{"summary": "2-3 sentences on how well the resume fits the role and level",
 "strengths": ["..."],
 "gaps": [{"skill": "...", "why_it_matters": "...", "how_to_improve": "..."}],
 "resume_improvements": ["concrete edits to the resume"],
 "interview_questions": [{"question": "...", "what_it_tests": "..."}],
 "learning_roadmap": [{"step": 1, "focus": "...", "activities": "...", "weeks": 2}]}
Give 3-5 strengths, 3-5 gaps, 3-5 resume improvements, 5 interview questions and 3-5 roadmap steps."""


def build_messages(role: dict, fit: FitResult, resume_text: str, known_names: list[str] | None = None) -> list[dict]:
    context = {
        "target_role": role["title"],
        "field": role["field"],
        "experience_level": LEVEL_LABELS[fit.level],
        "role_description": role.get("description", "")[:600],
        "essential_skills_for_role": role["skills"]["essential"][:12],
        "match": {
            "score_percent": fit.score,
            "label": fit.label,
            "parts": fit.parts,
            "matched_skills": [r.name for r in fit.matched],
            "missing_skills": [{"skill": r.name, "share_of_job_ads": r.weight} for r in fit.missing],
            "soft_skills_found": fit.soft_skills_found,
            "years_of_experience_found": fit.years_estimate,
            "system_notes": fit.notes,
        },
        "resume_text": redact_personal_info(resume_text, known_names)[:MAX_RESUME_CHARS],
    }
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": "Explain this result and give advice as JSON.\n" + json.dumps(context, ensure_ascii=False)},
    ]


def explain_fit(role: dict, fit: FitResult, resume_text: str, known_names: list[str] | None = None) -> LLMReply:
    return chat_json(build_messages(role, fit, resume_text, known_names), purpose="fit_explanation", max_tokens=2200)
