"""Draft Malaysia/Singapore skill lists for roles with too few job ads in the datasets.

Drafts are saved to data/catalog/llm_drafts/<role>.json marked "needs review";
build_skills merges them into the role profiles in a clearly labelled section.

Usage (from ai_backend/, env careerbridge-ai):
    python -m app.llm.fill_catalog --dry-run     # list the roles that would be drafted
    python -m app.llm.fill_catalog               # draft them
"""

import argparse
import json
from datetime import date

from app.llm.client import LLMUnavailable, chat_json
from app.matching.fit import MIN_ADS_FOR_MARKET
from app.matching.roles import load_roles
from app.ml.catalog import DATA_DIR

DRAFTS_DIR = DATA_DIR / "catalog" / "llm_drafts"

SYSTEM_PROMPT = """You help build a job-skills catalogue for Malaysia and Singapore.
For the job title given, list the concrete skills, tools and certifications that employers in Malaysia and
Singapore most often ask for in job ads. Rules:
- Concrete and checkable only (e.g. "AutoCAD", "Microsoft Excel", "CIDB Green Card", "GDPR"); no vague traits.
- At most 3 soft skills, marked type "soft".
- "importance" = your estimate of the share of job ads (0.05 to 0.9) that mention the item.
- Use the names a Malaysian/Singaporean resume would use. Do not invent products or laws.
Reply with JSON in exactly this structure:
{"skills": [{"name": "...", "type": "hard|tool|certification|soft", "importance": 0.6}],
 "local_notes": "one sentence on anything specific to Malaysia/Singapore, or empty"}
Give 12 to 18 items, most important first."""


def draft_for(role: dict) -> dict:
    context = {
        "job_title": role["title"],
        "also_called": role["aka"],
        "field": role["field"],
        "occupation_description": role.get("description", "")[:500],
        "reference_skills_from_esco": role["skills"]["essential"][:15],
        "reference_tools_from_onet": role["skills"]["tools"][:10],
    }
    reply = chat_json(
        [{"role": "system", "content": SYSTEM_PROMPT},
         {"role": "user", "content": "Return the JSON skill list for:\n" + json.dumps(context, ensure_ascii=False)}],
        purpose="catalog_fill", max_tokens=1200, temperature=0.2,
    )
    return {
        "role": role["title"],
        "status": "draft - needs human review",
        "generated": date.today().isoformat(),
        "model_note": "DeepSeek (deepseek-flash)",
        "cost_usd": reply.cost_usd,
        **reply.data,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true", help="redo roles that already have a draft")
    args = parser.parse_args()

    thin = [r for r in load_roles() if r["postings"]["total"] < MIN_ADS_FOR_MARKET]
    todo = [r for r in thin if args.force or not (DRAFTS_DIR / f"{r['id']}.json").exists()]
    print(f"{len(thin)} roles have fewer than {MIN_ADS_FOR_MARKET} job ads; {len(todo)} to draft.")
    if args.dry_run:
        print(", ".join(r["title"] for r in todo))
        return 0

    DRAFTS_DIR.mkdir(parents=True, exist_ok=True)
    total = 0.0
    for role in todo:
        try:
            draft = draft_for(role)
        except LLMUnavailable as exc:
            print(f"Stopped: {exc}")
            return 1
        (DRAFTS_DIR / f"{role['id']}.json").write_text(json.dumps(draft, indent=2, ensure_ascii=False), encoding="utf-8")
        total += draft["cost_usd"]
        print(f"  ✓ {role['title']:<38} {len(draft.get('skills', []))} items  USD {draft['cost_usd']:.4f}")
    print(f"Done. Estimated cost USD {total:.4f}. Rebuild profiles: python -m app.catalog.build_skills")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
