"""Synthetic Malaysian-style resumes for checking models on local resume formats.

No public dataset of Malaysian resumes exists, so this generates one fictional resume
per career category with the LLM, varying length, layout and seniority. It is a test
set only: it is never used for training, and it does not replace real resumes.

Usage (from ai_backend/, env careerbridge-ai):
    python -m app.ml.synthetic_my_testset generate          # about USD 0.10 in total
    python -m app.ml.synthetic_my_testset evaluate v2 v5    # compare model versions
Output: data/eval/my_synthetic_v1.jsonl (local only)
"""

import argparse
import json
from datetime import date

import numpy as np

from app.llm.client import LLMUnavailable, chat_json
from app.ml.catalog import DATA_DIR, LABEL_TO_FIELD, friendly
from app.ml.predict import _load
from app.ml.text_prep import clean_resume_text

LABELS_FILE = DATA_DIR / "kaggle_upload" / "careerbridge-resumes-v2" / "labels.json"
OUT = DATA_DIR / "eval" / "my_synthetic_v1.jsonl"

# Categories whose names alone are ambiguous.
HINTS = {
    "Apparel": "fashion and apparel (merchandising, garment production, fashion design or retail)",
    "Arts": "arts (fine art, performing arts, art teaching or arts administration)",
    "Automobile": "automotive (vehicle service, automotive engineering or car dealership operations)",
    "BPO": "business process outsourcing (shared-services centre, call centre, back-office operations)",
    "Blockchain": "blockchain development (smart contracts, Web3, crypto platforms)",
    "Building and Construction": "building and construction (quantity surveying, site management, contracts)",
    "Database": "database administration (DBA: backups, tuning, Oracle/SQL Server/MySQL)",
    "Designing": "graphic or product design",
    "Digital Media": "digital media (content, social media, video, digital marketing)",
    "Food and Beverages": "food and beverage (chef, F&B outlet operations)",
    "Health and Fitness": "health and fitness (personal trainer, fitness coach, gym management)",
    "Healthcare": "healthcare (nursing, clinical or hospital work)",
    "Management": "general management (department or business unit manager)",
    "PMO": "project management office (PMO analyst, project coordinator, project governance)",
    "SAP Developer": "SAP development or SAP functional consulting (ABAP, S/4HANA, FICO, MM)",
    "Testing": "software testing / QA (manual and automated testing)",
    "Web Designing": "web design (UI, HTML/CSS, WordPress, Figma)",
}
LENGTHS = ["short (about 150 words)", "medium (about 350 words)", "long (about 650 words)"]
LAYOUTS = ["clear section headings with bullet points", "a profile paragraph followed by sections",
           "compact layout with skills listed first", "chronological layout with detailed bullet points"]
LEVELS = ["fresh graduate with internship experience", "junior, 1-3 years of experience",
          "mid-level, 4-7 years of experience", "senior, 8+ years of experience"]

SYSTEM_PROMPT = """You write realistic, fictional resumes of people working in Malaysia, for testing a resume classifier.
Rules:
- Plain English text as a real Malaysian jobseeker would type it: normal capitalisation and punctuation.
- Use a fictional person with a Malaysian name; Malaysian cities, employers and universities (UTeM, UTM, UM, UiTM,
  USM, UPM, Taylor's, Sunway, etc.); local details where natural (SPM, EPF, SST, CIDB, MIA, Board of Engineers,
  Malaysian Nursing Board, HRDF), but no IC numbers.
- Do not write the category name as a label or heading; the person's own job titles and skills should show it.
- Follow the requested length, layout and seniority.
Reply with JSON: {"job_title": "...", "resume_text": "..."}"""


def generate() -> None:
    labels = json.loads(LABELS_FILE.read_text(encoding="utf-8"))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    rows, total = [], 0.0
    for i, label in enumerate(labels):
        spec = {
            "career_category": HINTS.get(label, friendly(label)),
            "field": LABEL_TO_FIELD.get(label, ""),
            "length": LENGTHS[i % len(LENGTHS)],
            "layout": LAYOUTS[i % len(LAYOUTS)],
            "seniority": LEVELS[i % len(LEVELS)],
        }
        try:
            reply = chat_json(
                [{"role": "system", "content": SYSTEM_PROMPT},
                 {"role": "user", "content": "Write the resume for:\n" + json.dumps(spec)}],
                purpose="synthetic_testset", max_tokens=1800, temperature=0.9,
            )
        except LLMUnavailable as exc:
            print(f"  {label}: skipped ({exc})")
            continue
        total += reply.cost_usd
        rows.append({"label": label, "job_title": reply.data.get("job_title", ""),
                     "text": reply.data["resume_text"], "spec": spec, "generated": date.today().isoformat()})
        print(f"  {i + 1:2d}/{len(labels)} {label:<26} → {rows[-1]['job_title']}  ({len(rows[-1]['text'].split())} words)")
    OUT.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n", encoding="utf-8")
    print(f"Saved {len(rows)} resumes to {OUT}  (cost USD {total:.4f})")


def evaluate(versions: list[str]) -> None:
    rows = [json.loads(line) for line in OUT.read_text(encoding="utf-8").splitlines() if line.strip()]
    y = np.array([r["label"] for r in rows])
    for version in versions:
        model = _load(version)
        texts = [r["text"] if getattr(model, "wants_raw_text", False) else clean_resume_text(r["text"]) for r in rows]
        proba = model.predict_proba(texts)
        ranked = np.asarray(model.classes_)[np.argsort(-proba, axis=1)]
        top1 = float(np.mean(ranked[:, 0] == y))
        top3 = float(np.mean((ranked[:, :3] == y[:, None]).any(axis=1)))
        to_field = np.vectorize(lambda label: LABEL_TO_FIELD.get(label, label))
        field1 = float(np.mean(to_field(ranked[:, 0]) == to_field(y)))
        print(f"{version}: top-1 {top1:.3f}  top-3 {top3:.3f}  field top-1 {field1:.3f}  (n={len(rows)})")
        misses = [(t, str(p)) for t, p in zip(y, ranked[:, 0]) if t != p]
        print("   wrong:", ", ".join(f"{t}→{p}" for t, p in misses) or "none")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("generate")
    ev = sub.add_parser("evaluate")
    ev.add_argument("versions", nargs="+")
    args = parser.parse_args()
    generate() if args.action == "generate" else evaluate(args.versions)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
