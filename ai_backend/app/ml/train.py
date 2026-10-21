"""Train LR, KNN, Random Forest and SVM, and save the best one."""

import argparse
import json
import time
from datetime import UTC, datetime

import joblib
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    precision_recall_fscore_support,
)
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import FeatureUnion, Pipeline
from sklearn.svm import LinearSVC

from app.ml import registry
from app.ml.catalog import KAGGLE_TO_ATLAS, KAGGLE_V1, RESUME_ATLAS_V1, friendly, model_dir
from app.ml.text_prep import clean_resume_text

SEED = 42
TEST_SIZE = 0.2
CV_FOLDS = 5
MIN_CHARS = 100


DATASETS = {
    "kaggle-v1": {"name": KAGGLE_V1["name"], "licence": KAGGLE_V1["licence"], "sha256_prefix": KAGGLE_V1["sha256_prefix"]},
    "combined-v2": {
        "name": "resume-atlas-v1 + kaggle-resume-dataset-v1",
        "licence": "MIT + CC0",
        "sha256_prefix": f"{RESUME_ATLAS_V1['sha256_prefix']} + {KAGGLE_V1['sha256_prefix']}",
    },
}


def load_dataset(name: str = "combined-v2") -> pd.DataFrame:
    kaggle = pd.read_csv(KAGGLE_V1["csv"], usecols=["Resume_str", "Category"]).rename(
        columns={"Resume_str": "text", "Category": "label"})
    if name == "kaggle-v1":
        df = kaggle
    else:
        atlas = pd.read_parquet(RESUME_ATLAS_V1["parquet"]).rename(columns={"Text": "text", "Category": "label"})
        kaggle = kaggle.assign(label=kaggle["label"].map(KAGGLE_TO_ATLAS)).dropna(subset=["label"])
        df = pd.concat([atlas[["text", "label"]], kaggle], ignore_index=True)
    df["text"] = df["text"].fillna("").map(clean_resume_text)
    df = df[df["text"].str.len() >= MIN_CHARS]
    df = df.drop_duplicates(subset="text")
    # Near-duplicates (same opening) would leak between train and test sets.
    df = df[~df["text"].str[:400].duplicated()]
    return df.reset_index(drop=True)


def candidates() -> dict[str, object]:
    """The four algorithms required by the specification."""
    return {
        "Logistic Regression": LogisticRegression(max_iter=3000, C=10, class_weight="balanced"),
        "KNN": KNeighborsClassifier(n_neighbors=7, metric="cosine", weights="distance"),
        "Random Forest": RandomForestClassifier(
            n_estimators=400, class_weight="balanced_subsample", n_jobs=4, random_state=SEED
        ),
        # LinearSVC has no probabilities; calibration adds them for top-3 suggestions.
        "SVM (linear)": CalibratedClassifierCV(LinearSVC(C=0.5, class_weight="balanced"), cv=3),
    }


FEATURES = "word"  # set from --features


def _word_tfidf() -> TfidfVectorizer:
    return TfidfVectorizer(stop_words="english", sublinear_tf=True, ngram_range=(1, 2),
                           min_df=2, max_df=0.9, max_features=60_000)


def pipeline(classifier) -> Pipeline:
    if FEATURES == "word+char":
        # Character n-grams catch spelling variants like "Node.js" and "NodeJS".
        features = FeatureUnion([
            ("word", _word_tfidf()),
            ("char", TfidfVectorizer(analyzer="char_wb", ngram_range=(3, 5), sublinear_tf=True,
                                     min_df=3, max_features=150_000)),
        ])
    else:
        features = _word_tfidf()
    return Pipeline([("tfidf", features), ("clf", classifier)])


def scores(y_true, y_pred) -> dict[str, float]:
    p, r, f1, _ = precision_recall_fscore_support(y_true, y_pred, average="macro", zero_division=0)
    return {
        "accuracy": round(accuracy_score(y_true, y_pred), 4),
        "precision_macro": round(p, 4),
        "recall_macro": round(r, 4),
        "f1_macro": round(f1, 4),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--deploy", action="store_true", help="deploy the new version after training")
    parser.add_argument("--dataset", choices=sorted(DATASETS), default="combined-v2")
    parser.add_argument("--features", choices=["word", "word+char"], default="word")
    args = parser.parse_args()

    started_at = datetime.now(UTC)
    global FEATURES
    FEATURES = args.features
    df = load_dataset(args.dataset)
    dataset = DATASETS[args.dataset]
    x_train, x_test, y_train, y_test = train_test_split(
        df["text"], df["label"], test_size=TEST_SIZE, stratify=df["label"], random_state=SEED
    )
    print(f"Dataset {dataset['name']}: {len(df)} resumes, {df['label'].nunique()} categories "
          f"(train {len(x_train)}, test {len(x_test)})\n")

    folds = StratifiedKFold(n_splits=CV_FOLDS, shuffle=True, random_state=SEED)
    results, fitted = {}, {}
    for name, clf in candidates().items():
        print(f"Training {name} …", flush=True)
        cv = cross_validate(
            pipeline(clf), x_train, y_train, cv=folds, n_jobs=4,
            scoring=["accuracy", "precision_macro", "recall_macro", "f1_macro"],
        )
        model = pipeline(clf)
        t0 = time.perf_counter()
        model.fit(x_train, y_train)
        train_seconds = time.perf_counter() - t0
        test = scores(y_test, model.predict(x_test))
        results[name] = {
            "cv_f1_macro_mean": round(cv["test_f1_macro"].mean(), 4),
            "cv_f1_macro_std": round(cv["test_f1_macro"].std(), 4),
            "cv_accuracy_mean": round(cv["test_accuracy"].mean(), 4),
            "test": test,
            "train_seconds": round(train_seconds, 2),
        }
        fitted[name] = model

    # Pick the winner on cross-validation (not the test set), then report test scores.
    best = max(results, key=lambda n: results[n]["cv_f1_macro_mean"])
    best_model = fitted[best]

    reg = registry.load()
    version = registry.next_version(reg)
    out = model_dir(version)
    out.mkdir(parents=True, exist_ok=True)
    joblib.dump(best_model, out / "model.joblib")

    y_pred = best_model.predict(x_test)
    proba = best_model.predict_proba(x_test)
    top3_labels = best_model.classes_[proba.argsort(axis=1)[:, ::-1][:, :3]]
    top3 = float((top3_labels == y_test.to_numpy()[:, None]).any(axis=1).mean())
    labels = sorted(df["label"].unique())
    per_class = classification_report(y_test, y_pred, labels=labels, output_dict=True, zero_division=0)
    pd.DataFrame(confusion_matrix(y_test, y_pred, labels=labels), index=labels, columns=labels).to_csv(
        out / "confusion_matrix.csv"
    )

    previous = registry.deployed_entry(reg)
    entry = {
        "version": version,
        "created_at": started_at.isoformat(timespec="seconds"),
        "algorithm": best,
        "dataset": dataset,
        "features": FEATURES,
        "dataset_size": {"train": len(x_train), "test": len(x_test), "categories": len(labels)},
        "metrics": {**results[best]["test"], "top3_accuracy": round(top3, 4)},
        "cv_f1_macro": results[best]["cv_f1_macro_mean"],
        "train_seconds": results[best]["train_seconds"],
        "compared_with": previous["version"] if previous else None,
        "status": "candidate",
        "file": f"{version}/model.joblib",
    }
    reg["versions"].append(entry)
    if args.deploy or reg["deployed"] is None:
        registry.set_deployed(reg, version)
    registry.save(reg)

    (out / "metrics.json").write_text(
        json.dumps({"comparison": results, "best": best, "per_class": per_class}, indent=2), encoding="utf-8"
    )
    (out / "report.md").write_text(_report(version, entry, results, best, per_class, labels, previous), encoding="utf-8")

    print("\n" + _comparison_table(results, best))
    print(f"\nTop-3 accuracy ({best}): {top3:.3f}")
    print(f"\nBest: {best}  →  saved as {version} ({entry['status'] if reg['deployed'] != version else 'deployed'})")
    print(f"Report: {out / 'report.md'}")


def _comparison_table(results, best) -> str:
    rows = ["| Model | CV macro F1 (mean ± sd) | Test accuracy | Test precision | Test recall | Test F1 | Train time |",
            "|---|---|---|---|---|---|---|"]
    for name, r in sorted(results.items(), key=lambda kv: -kv[1]["cv_f1_macro_mean"]):
        t = r["test"]
        mark = " **(best)**" if name == best else ""
        rows.append(
            f"| {name}{mark} | {r['cv_f1_macro_mean']:.3f} ± {r['cv_f1_macro_std']:.3f} | {t['accuracy']:.3f} | "
            f"{t['precision_macro']:.3f} | {t['recall_macro']:.3f} | {t['f1_macro']:.3f} | {r['train_seconds']:.1f}s |"
        )
    return "\n".join(rows)


def _report(version, entry, results, best, per_class, labels, previous) -> str:
    lines = [
        f"# Career classification model — {version}",
        "",
        f"- **Created:** {entry['created_at']}",
        f"- **Selected algorithm:** {best} (highest cross-validated macro F1)",
        f"- **Dataset:** {entry['dataset']['name']} ({entry['dataset']['licence']}, sha256 {entry['dataset']['sha256_prefix']}…)",
        f"- **Split:** {entry['dataset_size']['train']} train / {entry['dataset_size']['test']} test, "
        f"stratified, seed {SEED}; {CV_FOLDS}-fold cross-validation on the training set",
        f"- **Features:** TF-IDF of cleaned resume text (word unigrams + bigrams{' + character 3–5-grams' if FEATURES == 'word+char' else ''})",
        f"- **Compared with previous deployed model:** {previous['version'] + ' (macro F1 ' + str(previous['metrics']['f1_macro']) + ')' if previous else 'none (first model)'}",
        "",
        "## Model comparison",
        "",
        _comparison_table(results, best),
        "",
        "Macro averages give every career category equal weight, so small categories (e.g. BPO) count as much as large ones.",
        "",
        f"## Per-category results ({best}, test set)",
        "",
        "| Category | Precision | Recall | F1 | Resumes in test |",
        "|---|---|---|---|---|",
    ]
    for label in labels:
        c = per_class[label]
        lines.append(f"| {friendly(label)} | {c['precision']:.2f} | {c['recall']:.2f} | {c['f1-score']:.2f} | {int(c['support'])} |")
    lines += [
        "",
        "## Notes and limitations",
        "",
        "- The dataset comes from one source (livecareer.com, mostly US resumes); results on Malaysian resumes may differ and must be checked with real, consented samples.",
        "- Resume headlines often name the job, which makes some categories easy; scores may be optimistic outside this dataset.",
        "- The prediction is a career-direction suggestion for decision support, not a hiring decision.",
    ]
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    main()
