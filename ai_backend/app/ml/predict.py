"""Suggest career directions for a resume with the deployed model."""

import argparse
import sys
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import joblib

from app.ml import registry
from app.ml.catalog import MODELS_DIR, friendly
from app.ml.text_prep import clean_resume_text
from app.services.resume_text import UnsupportedFile, extract_text


@dataclass(frozen=True)
class CareerSuggestion:
    label: str         # dataset category, e.g. INFORMATION-TECHNOLOGY
    name: str          # shown to users, e.g. Information Technology
    probability: float


class NoDeployedModel(RuntimeError):
    pass


@lru_cache(maxsize=4)
def _load(version: str):
    folder = MODELS_DIR / version
    if (folder / "model.onnx").exists():
        from app.ml.transformer import TransformerModel
        return TransformerModel(folder)
    return joblib.load(folder / "model.joblib")


def deployed_version() -> str:
    version = registry.load()["deployed"]
    if not version:
        raise NoDeployedModel("No model is deployed yet. Run: python -m app.ml.train")
    return version


def suggest_careers(resume_text: str, top: int = 3) -> tuple[str, list[CareerSuggestion]]:
    """Return (model version, top career directions with probabilities)."""
    version = deployed_version()
    model = _load(version)
    text = resume_text if getattr(model, "wants_raw_text", False) else clean_resume_text(resume_text)
    probabilities = model.predict_proba([text])[0]
    ranked = sorted(zip(model.classes_, probabilities), key=lambda p: -p[1])[:top]
    return version, [CareerSuggestion(label, friendly(label), round(float(p), 3)) for label, p in ranked]


def main() -> int:
    parser = argparse.ArgumentParser(description="Suggest career directions for a resume file.")
    parser.add_argument("file", type=Path)
    parser.add_argument("--top", type=int, default=3)
    args = parser.parse_args()

    try:
        extracted = extract_text(args.file.read_bytes())
        version, suggestions = suggest_careers(extracted.text, args.top)
    except (FileNotFoundError, UnsupportedFile, NoDeployedModel) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    print(f"Resume : {args.file.name} (read with {extracted.method})")
    print(f"Model  : {version}")
    print("Career directions (fit indicator, not a hiring prediction):")
    for i, s in enumerate(suggestions, 1):
        bar = "█" * round(s.probability * 30)
        print(f"  {i}. {s.name:<30} {s.probability:6.1%}  {bar}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
