"""Blind LLM review of model answers on the real Malaysian CVs."""

import json
import random
import re
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

from app.llm.client import LLMUnavailable, chat_json
from app.llm.redact import redact_personal_info
from app.matching.roles import fields
from app.ml.catalog import DATA_DIR, LABEL_TO_FIELD, friendly
from app.services.resume_text import extract_text

EVAL = DATA_DIR / "eval"
REAL_DIR = EVAL / "real" / "my_cv_samples"

SYSTEM_PROMPT = """You review a career-direction classifier for jobseekers in Malaysia. You get one CV and a list of
candidate career categories (in random order, from several anonymous models). Judge each candidate only by how
well it fits the person's current career and experience in the CV.
Scores: 3 = clearly the right category; 2 = closely related, a reasonable suggestion; 1 = weak link;
0 = wrong. Several candidates may share a score.
Also choose the single best field from the given field list, and the best category from the candidates
(or "none" if no candidate fits).
Reply with JSON: {"scores": {"<candidate>": 0-3, ...}, "best_category": "<candidate or none>",
"best_field": "<field>", "reason": "one short sentence"}"""


def review_one(cv: dict, candidates: list[str], field_list: list[str]) -> dict:
    shown = {f"{friendly(c)} ({LABEL_TO_FIELD.get(c, '')})": c for c in candidates}
    names = list(shown)
    random.Random(cv["title"]).shuffle(names)
    reply = chat_json(
        [{"role": "system", "content": SYSTEM_PROMPT},
         {"role": "user", "content": json.dumps({"cv": cv["text"], "candidates": names, "fields": field_list},
                                                ensure_ascii=False)}],
        purpose="llm_judge", max_tokens=2500, temperature=0.0, essential=False)
    data = reply.data
    scores = {shown[n]: int(s) for n, s in data.get("scores", {}).items() if n in shown}
    best = data.get("best_category", "none")
    return {"title": cv["title"], "scores": scores, "best_category": shown.get(best, "none"),
            "best_field": data.get("best_field", ""), "reason": data.get("reason", ""), "cost_usd": reply.cost_usd}


def main() -> int:
    labels = json.loads((EVAL / "real" / "my_cv_samples_labels.json").read_text(encoding="utf-8"))
    preds = [json.loads(line) for line in (EVAL / "comparison_predictions.jsonl").read_text(encoding="utf-8").splitlines()
             if line and json.loads(line)["set"] == "real58"]
    models = list(dict.fromkeys(p["model"] for p in preds))
    by_cv = defaultdict(dict)
    for p in preds:
        by_cv[p["id"]][p["model"]] = [c for c, _ in p["top3"]]
    field_list = sorted(fields())

    cvs = []
    for row in labels:
        text = re.sub(r"\[[^\]]*\]", "", extract_text((REAL_DIR / row["file"]).read_bytes()).text)
        cvs.append({"title": row["title"], "text": redact_personal_info(text)[:3500], "field": row["field"],
                    "category": row["category"]})

    def run(cv):
        cands = list(dict.fromkeys(c for m in models for c in by_cv[cv["title"]][m]))
        try:
            return review_one(cv, cands, field_list)
        except LLMUnavailable as exc:
            return {"title": cv["title"], "error": str(exc)}

    with ThreadPoolExecutor(max_workers=6) as pool:
        reviews = list(pool.map(run, cvs))
    (EVAL / "llm_judge.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in reviews) + "\n",
                                          encoding="utf-8")

    ok = {r["title"]: r for r in reviews if "error" not in r}
    truth = {cv["title"]: cv for cv in cvs}
    summary = {"reviewed": len(ok), "failed": len(reviews) - len(ok),
               "cost_usd": round(sum(r["cost_usd"] for r in ok.values()), 4), "models": {}}
    # How far the reviewer agrees with the developer-confirmed labels.
    summary["judge_vs_labels"] = {
        "field_agreement": round(sum(ok[t]["best_field"] == truth[t]["field"] for t in ok) / len(ok), 3),
        "category_agreement": round(sum(ok[t]["best_category"] == truth[t]["category"]
                                        for t in ok if truth[t]["category"]) /
                                    max(1, sum(1 for t in ok if truth[t]["category"])), 3)}
    for m in models:
        top1 = [ok[t]["scores"].get(by_cv[t][m][0], 0) for t in ok]
        summary["models"][m] = {
            "mean_score_top1": round(sum(top1) / len(top1), 3),
            "top1_rated_3": round(sum(s == 3 for s in top1) / len(top1), 3),
            "top1_rated_2_or_3": round(sum(s >= 2 for s in top1) / len(top1), 3),
            "top1_wrong_0": round(sum(s == 0 for s in top1) / len(top1), 3),
            "best_of_top3_mean": round(sum(max(ok[t]["scores"].get(c, 0) for c in by_cv[t][m]) for t in ok) / len(ok), 3),
            "top1_matches_judge_best": round(sum(by_cv[t][m][0] == ok[t]["best_category"] for t in ok) / len(ok), 3),
        }
    (EVAL / "llm_judge_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
