"""Terminal tool: the full Job Seeker analysis in one command."""

import argparse
import sys
import textwrap
from pathlib import Path

from app.llm.advice import explain_fit
from app.llm.client import LLMUnavailable, budget_status
from app.matching.fit import LEVEL_LABELS, score_fit
from app.matching.roles import UnknownRole, find_role
from app.ml.predict import NoDeployedModel, suggest_careers
from app.services.resume_text import UnsupportedFile, extract_text

WRAP = textwrap.TextWrapper(width=96, subsequent_indent="     ")


def section(title: str) -> None:
    print(f"\n━━ {title} " + "━" * max(0, 80 - len(title)))


def main() -> int:
    parser = argparse.ArgumentParser(description="Full resume analysis for a chosen job title and level.")
    parser.add_argument("file", type=Path)
    parser.add_argument("--role", required=True)
    parser.add_argument("--level", choices=list(LEVEL_LABELS), default="junior")
    parser.add_argument("--name", action="append", default=[], help="name to hide before sending to the LLM")
    parser.add_argument("--no-llm", action="store_true", help="skip the AI explanation (no API cost)")
    args = parser.parse_args()

    try:
        role = find_role(args.role)
        extracted = extract_text(args.file.read_bytes())
    except (UnknownRole, UnsupportedFile, FileNotFoundError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    fit = score_fit(extracted.text, role, args.level)
    section(f"{fit.role} · {LEVEL_LABELS[fit.level]}")
    print(f"{fit.score}% — {fit.label}   (system fit indicator, not a hiring prediction)")
    print(f"skills {fit.parts['skills']:.0%} · experience {fit.parts['experience']:.0%} · education {fit.parts['education']:.0%}")
    print("✓ " + (", ".join(r.name for r in fit.matched) or "no listed skills found"))
    print("✗ " + (", ".join(r.name for r in fit.missing[:8]) or "—"))
    for note in fit.notes:
        print(WRAP.fill(f"  • {note}"))

    section("Other directions your resume suits (ML model)")
    try:
        version, suggestions = suggest_careers(extracted.text, top=3)
        for s in suggestions:
            print(f"  {s.name:<34} {s.probability:6.1%}")
        print(f"  (model {version})")
    except NoDeployedModel as exc:
        print(f"  {exc}")

    if args.no_llm:
        return 0
    try:
        reply = explain_fit(role, fit, extracted.text, known_names=args.name)
    except LLMUnavailable as exc:
        print(f"\nAI explanation unavailable: {exc} The score and skill lists above are still valid.")
        return 0

    advice = reply.data
    section("Summary")
    print(WRAP.fill(advice.get("summary", "")))
    section("Strengths")
    for x in advice.get("strengths", []):
        print(WRAP.fill(f"  + {x}"))
    section("Gaps and how to close them")
    for g in advice.get("gaps", []):
        print(WRAP.fill(f"  - {g.get('skill')}: {g.get('why_it_matters')} → {g.get('how_to_improve')}"))
    section("Improve your resume")
    for x in advice.get("resume_improvements", []):
        print(WRAP.fill(f"  • {x}"))
    section("Interview practice")
    for i, q in enumerate(advice.get("interview_questions", []), 1):
        print(WRAP.fill(f"  {i}. {q.get('question')}  [{q.get('what_it_tests')}]"))
    section("Learning roadmap")
    for step in advice.get("learning_roadmap", []):
        print(WRAP.fill(f"  {step.get('step')}. {step.get('focus')} ({step.get('weeks')} wk): {step.get('activities')}"))

    b = budget_status()
    print(f"\nAI cost: USD {reply.cost_usd:.4f}{' (cached)' if reply.cached else ''} · "
          f"month: USD {b['spent_usd']:.4f} of {b['budget_usd']:.2f} ({b['used']:.1%})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
