"""Export the dataset with the same train/test split as train.py."""

import json
import re

import pandas as pd
from sklearn.model_selection import train_test_split

from app.ml.catalog import DATA_DIR, KAGGLE_TO_ATLAS, KAGGLE_V1, RESUME_ATLAS_V1
from app.ml.text_prep import clean_resume_text
from app.ml.train import MIN_CHARS, SEED, TEST_SIZE, load_dataset

OUT = DATA_DIR / "kaggle_upload" / "careerbridge-resumes-v2"
MAX_RAW_CHARS = 8000  # Transformers read ~512 tokens; keep enough for head + tail


def main() -> None:
    atlas = pd.read_parquet(RESUME_ATLAS_V1["parquet"]).rename(columns={"Text": "raw", "Category": "label"})
    kaggle = pd.read_csv(KAGGLE_V1["csv"], usecols=["Resume_str", "Category"]).rename(
        columns={"Resume_str": "raw", "Category": "label"})
    kaggle = kaggle.assign(label=kaggle["label"].map(KAGGLE_TO_ATLAS)).dropna(subset=["label"])
    df = pd.concat([atlas[["raw", "label"]], kaggle], ignore_index=True)
    df["raw"] = df["raw"].fillna("")
    # Same filtering and de-duplication as app.ml.train.load_dataset, row for row.
    df["text"] = df["raw"].map(clean_resume_text)
    df = df[df["text"].str.len() >= MIN_CHARS]
    df = df.drop_duplicates(subset="text")
    df = df[~df["text"].str[:400].duplicated()].reset_index(drop=True)

    reference = load_dataset("combined-v2")
    assert df["text"].equals(reference["text"]) and df["label"].equals(reference["label"]), "row order differs"

    train_idx, test_idx = train_test_split(df.index, test_size=TEST_SIZE, stratify=df["label"], random_state=SEED)
    df["raw"] = df["raw"].map(lambda t: re.sub(r"\s+", " ", t).strip()[:MAX_RAW_CHARS])

    OUT.mkdir(parents=True, exist_ok=True)
    df.loc[train_idx, ["raw", "label"]].rename(columns={"raw": "text"}).to_csv(OUT / "train.csv", index=False)
    df.loc[test_idx, ["raw", "label"]].rename(columns={"raw": "text"}).to_csv(OUT / "test.csv", index=False)
    labels = sorted(df["label"].unique())
    (OUT / "labels.json").write_text(json.dumps(labels, indent=2), encoding="utf-8")
    (OUT / "README.md").write_text(
        "# CareerBridge resumes v2\n\nResumeAtlas (MIT) + Kaggle Resume Dataset (CC0), de-duplicated, "
        f"{len(labels)} categories. train.csv {len(train_idx)} rows, test.csv {len(test_idx)} rows "
        f"(stratified split, seed {SEED}, identical to the TF-IDF models). Private dataset for CareerBridge AI.\n",
        encoding="utf-8")
    print(f"Wrote {OUT}: train {len(train_idx)}, test {len(test_idx)}, {len(labels)} labels")


if __name__ == "__main__":
    main()
