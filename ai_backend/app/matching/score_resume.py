"""Terminal tool: score a resume against a chosen job title and level.

Usage (from ai_backend/, env careerbridge-ai):
    python -m app.matching.score_resume resume.pdf --role "Data Analyst" --level junior
    python -m app.matching.score_resume --list-roles
Levels: entry, junior, mid, senior, lead
"""

import argparse
import sys
from pathlib import Path

from app.matching.fit import LEVEL_LABELS, score_fit
from app.matching.roles import UnknownRole, fields, find_role
from app.services.resume_text import UnsupportedFile, extract_text


def main() -> int:
    parser = argparse.ArgumentParser(description="Score a resume against a job title and experience level.")
    parser.add_argument("file", type=Path, nargs="?")
    parser.add_argument("--role", help='job title, e.g. "Data Analyst"')
    parser.add_argument("--level", choices=list(LEVEL_LABELS), default="junior")
    parser.add_argument("--list-roles", action="store_true", help="show all fields and job titles")
    args = parser.parse_args()

    if args.list_roles:
        for field_name, titles in fields().items():
            print(f"{field_name}\n  " + ", ".join(titles))
        return 0
    if not args.file or not args.role:
        parser.error("give a resume file and --role (or use --list-roles)")

    try:
        role = find_role(args.role)
        extracted = extract_text(args.file.read_bytes())
    except (UnknownRole, UnsupportedFile, FileNotFoundError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    result = score_fit(extracted.text, role, args.level)
    print(f"Resume   : {args.file.name} (read with {extracted.method})")
    print(f"Target   : {result.role} · {LEVEL_LABELS[result.level]}")
    print(f"Match    : {result.score}% — {result.label}   (fit indicator, not a hiring prediction)")
    print(f"           skills {result.parts['skills']:.0%} · experience {result.parts['experience']:.0%} · "
          f"education {result.parts['education']:.0%}")
    if result.years_estimate is not None:
        print(f"Experience found: about {result.years_estimate:g} years")
    print("\nMatching skills : " + (", ".join(r.name for r in result.matched) or "—"))
    print("Missing skills  : " + (", ".join(f"{r.name} ({r.weight:.0%})" for r in result.missing[:10]) or "—"))
    print("                  (%) = share of job ads at this level that ask for it")
    if result.soft_skills_found:
        print("Soft skills     : " + ", ".join(result.soft_skills_found))
    for note in result.notes:
        print(f"Note: {note}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
