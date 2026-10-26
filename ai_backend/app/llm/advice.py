"""Use the LLM to explain a fit result and generate advice."""

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


# ------------------------------------------------------------------ advice from a structured profile (testing mode)

COACH_PROMPT = """You are the friendly career coach inside CareerBridge AI (Malaysia and Singapore).
You receive the Job Seeker's resume profile (already read by the system) and the system's fit result for
the job title and level they chose.
Tone: warm, encouraging and reassuring. The person may be a student or fresh graduate. Celebrate what is
already good, then give a clear next step. Never say the person did something wrong: resume styles differ
between countries. If the system could not read something (for example dates), say the system may have missed
it and suggest, as an option, a format that is easier to read.
Personal details (name, contact, address) were removed by the system on purpose: never mention them.
Facts: use only what is given; never invent experience, numbers or qualifications. The score is a system fit
indicator, never a chance of being hired.
Keep it short: every list item is one sentence of at most 25 words.
Reply with JSON exactly like:
{"summary": "2 sentences",
 "strengths": ["at most 3"],
 "next_skills": [{"skill": "...", "how": "one practical step"}],
 "resume_tips": ["at most 3 optional suggestions"],
 "interview_questions": [{"question": "...", "tip": "how to prepare, one sentence"}],
 "roadmap": [{"step": 1, "focus": "...", "weeks": 4}]}
Give at most 3 next_skills, 3 interview_questions and 3 roadmap steps."""


def coach_messages(role: dict, level_label: str, assessment: dict, profile: dict) -> list[dict]:
    context = {"target_role": role["title"], "field": role["field"], "chosen_level": level_label,
               "fit": assessment, "resume_profile": profile}
    return [{"role": "system", "content": COACH_PROMPT},
            {"role": "user", "content": "Write the coaching advice as JSON.\n" + json.dumps(context, ensure_ascii=False)}]


def coach(role: dict, level_label: str, assessment: dict, profile: dict, thinking: bool = False,
          user_id: str | None = None) -> LLMReply:
    return chat_json(coach_messages(role, level_label, assessment, profile), purpose="coach_advice",
                     max_tokens=1400, temperature=0.4, thinking=thinking, user_id=user_id)
