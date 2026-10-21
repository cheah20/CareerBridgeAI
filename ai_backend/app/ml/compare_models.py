"""Compare model versions on Malaysian-format resumes, at category and field level."""

import argparse
import gc
import json
from datetime import datetime
from pathlib import Path

import numpy as np

from app.ml.catalog import DATA_DIR, LABEL_TO_FIELD
from app.ml.catalog import MODELS_DIR
from app.ml.predict import _load
from app.ml.transformer import TransformerModel
from app.ml.role_labels import ROLE_TO_LABEL
from app.ml.text_prep import clean_resume_text
from app.services.resume_text import extract_text

REAL_DIR = DATA_DIR / "eval" / "real" / "my_cv_samples"
SEEN = {"candidate-synth1": {"synth45"}, "candidate-synth2": {"batch1"}}


def load_sets() -> dict[str, list[dict]]:
    real = []
    for row in json.loads((DATA_DIR / "eval" / "real" / "my_cv_samples_labels.json").read_text(encoding="utf-8")):
        text = extract_text((REAL_DIR / row["file"]).read_bytes()).text
        real.append({"id": row["title"], "text": text, "field": row["field"], "category": row["category"]})
    batch1 = [{"id": r["file"], "text": r["extracted_text"], "field": r["profile"]["field"],
               "category": ROLE_TO_LABEL.get(r["profile"]["role_id"])}
              for r in map(json.loads, (DATA_DIR / "synthetic" / "batch1" / "rendered.jsonl").read_text(encoding="utf-8").splitlines())]
    synth45 = [{"id": r["label"], "text": r["text"], "field": LABEL_TO_FIELD.get(r["label"]), "category": r["label"]}
               for r in map(json.loads, (DATA_DIR / "eval" / "my_synthetic_v1.jsonl").read_text(encoding="utf-8").splitlines())]
    return {"real58": real, "batch1": batch1, "synth45": synth45}


def score(model, rows: list[dict]) -> tuple[dict, list[dict]]:
    texts = [r["text"] if getattr(model, "wants_raw_text", False) else clean_resume_text(r["text"]) for r in rows]
    proba = model.predict_proba(texts)
    classes = np.asarray(model.classes_)
    order = np.argsort(-proba, axis=1)
    preds, cat1, cat3, f1, f3 = [], [], [], [], []
    for r, idx, p in zip(rows, order, proba):
        ranked = [str(classes[i]) for i in idx[:10]]
        fields = list(dict.fromkeys(LABEL_TO_FIELD.get(c, c) for c in ranked))
        f1.append(fields[0] == r["field"])
        f3.append(r["field"] in fields[:3])
        if r["category"]:
            cat1.append(ranked[0] == r["category"])
            cat3.append(r["category"] in ranked[:3])
        preds.append({"id": r["id"], "true_field": r["field"], "true_category": r["category"],
                      "top3": [(c, round(float(p[i]), 3)) for c, i in zip(ranked[:3], idx[:3])],
                      "fields_top3": fields[:3]})
    metrics = {"n": len(rows), "field_top1": float(np.mean(f1)), "field_top3": float(np.mean(f3)),
               "n_with_category": len(cat1),
               "category_top1": float(np.mean(cat1)) if cat1 else None,
               "category_top3": float(np.mean(cat3)) if cat3 else None}
    return metrics, preds


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("versions", nargs="+", help="registry versions or model folders under models/")
    args = parser.parse_args()
    sets = load_sets()
    results, out_preds = {}, []
    for version in args.versions:
        # One model in memory at a time (each fp32 Transformer is ~570 MB plus working memory).
        folder = MODELS_DIR / version
        model = TransformerModel(folder) if (folder / "model.onnx").exists() else _load(version)
        results[version] = {}
        for name, rows in sets.items():
            m, preds = score(model, rows)
            m["seen_in_training"] = name in SEEN.get(version, set())
            results[version][name] = m
            out_preds += [{"model": version, "set": name, **p} for p in preds]
        del model
        gc.collect()
        print(f"done {version}", flush=True)

    print(f"\n{'model':<18}" + "".join(f"{s + ' field':>15}{s + ' cat':>13}" for s in sets))
    for version, by_set in results.items():
        cells = []
        for s in sets:
            m = by_set[s]
            mark = "*" if m["seen_in_training"] else " "
            cat = f"{m['category_top1']:.3f}" if m["category_top1"] is not None else "-"
            cells.append(f"{m['field_top1']:>14.3f}{mark}{cat:>12}{mark}")
        print(f"{version:<18}" + "".join(cells))
    print("* = model was trained on these resumes (not a fair test)")
    eval_dir = DATA_DIR / "eval"
    (eval_dir / "comparison.json").write_text(json.dumps({"created": datetime.now().isoformat(timespec="seconds"),
                                                          "results": results}, indent=2), encoding="utf-8")
    (eval_dir / "comparison_predictions.jsonl").write_text(
        "\n".join(json.dumps(p, ensure_ascii=False) for p in out_preds) + "\n", encoding="utf-8")
    print("saved", eval_dir / "comparison.json", "and comparison_predictions.jsonl")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
