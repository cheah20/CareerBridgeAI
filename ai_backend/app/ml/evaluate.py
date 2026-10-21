"""Re-check a saved model on its test set (top-1 and top-3 accuracy)."""

import argparse
import json

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

from app.ml import registry
from app.ml.catalog import DATA_DIR, LABEL_TO_FIELD, MODELS_DIR
from app.ml.predict import _load
from app.ml.train import SEED, TEST_SIZE, load_dataset


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("version")
    args = parser.parse_args()

    entry = next(v for v in registry.load()["versions"] if v["version"] == args.version)
    dataset = "kaggle-v1" if entry["dataset"]["name"].startswith("kaggle") else "combined-v2"
    df = load_dataset(dataset)
    _, x_test, _, y_test = train_test_split(df["text"], df["label"], test_size=TEST_SIZE,
                                            stratify=df["label"], random_state=SEED)
    model = _load(args.version)
    if getattr(model, "wants_raw_text", False):
        # Same rows in the same order, with the original wording.
        raw = pd.read_csv(DATA_DIR / "kaggle_upload" / "careerbridge-resumes-v2" / "test.csv")
        assert raw["label"].tolist() == y_test.tolist(), "test split differs from the export"
        x_test = raw["text"]
    proba = model.predict_proba(x_test)
    ranked = model.classes_[np.argsort(-proba, axis=1)]
    y = y_test.to_numpy()

    result = {"top1": float(np.mean(ranked[:, 0] == y)), "top3": float(np.mean((ranked[:, :3] == y[:, None]).any(axis=1)))}
    if dataset == "combined-v2":
        to_field = np.vectorize(lambda label: LABEL_TO_FIELD.get(label, label))
        field_true = to_field(y)
        field_ranked = to_field(ranked)
        result["field_top1"] = float(np.mean(field_ranked[:, 0] == field_true))
        # Top-3 distinct fields among the ranked categories.
        hits = []
        for row, truth in zip(field_ranked, field_true):
            distinct = list(dict.fromkeys(row))[:3]
            hits.append(truth in distinct)
        result["field_top3"] = float(np.mean(hits))

    print(json.dumps({k: round(v, 4) for k, v in result.items()}, indent=2))
    out = MODELS_DIR / args.version / "evaluation.json"
    out.write_text(json.dumps(result, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
