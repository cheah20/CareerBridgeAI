"""Run the fine-tuned Transformer (ONNX int8) on CPU, no PyTorch needed."""

import argparse
import json
import re
import shutil
from datetime import UTC, datetime
from pathlib import Path

import numpy as np
import onnxruntime as ort
from tokenizers import Tokenizer

from app.ml import registry
from app.ml.catalog import KAGGLE_V1, MODELS_DIR, RESUME_ATLAS_V1
from app.ml.text_prep import normalise_resume_text

MAX_RAW_CHARS = 8000  # same cut as app.ml.export_for_kaggle


class TransformerModel:
    """Same interface as the sklearn pipelines: classes_ and predict_proba(texts)."""

    wants_raw_text = True  # trained on original wording, not on clean_resume_text output

    def __init__(self, folder: Path):
        self.config = json.loads((folder / "config.json").read_text(encoding="utf-8"))
        self.classes_ = np.array(self.config["labels"])
        self.tokenizer = Tokenizer.from_file(str(folder / "tokenizer.json"))
        self.tokenizer.no_truncation()
        self.tokenizer.no_padding()
        options = ort.SessionOptions()
        options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        options.enable_cpu_mem_arena = False  # resumes vary in length; an arena keeps every size and grows to many GB
        self.session = ort.InferenceSession(str(folder / "model.onnx"), options, providers=["CPUExecutionProvider"])

    def _ids(self, text: str) -> list[int]:
        c = self.config
        text = re.sub(r"\s+", " ", str(text)).strip()[:MAX_RAW_CHARS]
        if c.get("text_form") == "normalised":  # v6+: same text form as in training
            text = normalise_resume_text(text)
        ids = self.tokenizer.encode(text, add_special_tokens=False).ids
        if len(ids) > c["max_len"] - 2:
            ids = ids[:c["head"]] + ids[-c["tail"]:]  # keep the start and the end of long resumes
        return [c["cls_id"]] + ids + [c["sep_id"]]

    def predict_proba(self, texts, batch_size: int = 4) -> np.ndarray:
        out = []
        texts = list(texts)
        for start in range(0, len(texts), batch_size):
            rows = [self._ids(t) for t in texts[start:start + batch_size]]
            width = max(map(len, rows))
            ids = np.full((len(rows), width), self.config["pad_id"], dtype=np.int64)
            mask = np.zeros((len(rows), width), dtype=np.int64)
            for i, row in enumerate(rows):
                ids[i, :len(row)] = row
                mask[i, :len(row)] = 1
            logits = self.session.run(None, {"input_ids": ids, "attention_mask": mask})[0].astype(np.float64)
            logits -= logits.max(axis=1, keepdims=True)
            probs = np.exp(logits)
            out.append(probs / probs.sum(axis=1, keepdims=True))
        return np.vstack(out)


def import_candidate(folder: Path) -> str:
    """Copy a trained candidate into models/vN and register it (not deployed)."""
    metrics = json.loads((folder / "metrics.json").read_text(encoding="utf-8"))
    config = json.loads((folder / "config.json").read_text(encoding="utf-8"))
    reg = registry.load()
    version = registry.next_version(reg)
    target = MODELS_DIR / version
    target.mkdir(parents=True)
    for name in ("model.onnx", "tokenizer.json", "config.json", "metrics.json"):
        shutil.copy2(folder / name, target / name)
    test = metrics["test"]
    reg["versions"].append({
        "version": version,
        "created_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "algorithm": f"Transformer ({config['model_name'].split('/')[-1]}, ONNX {config.get('onnx_precision', 'int8')})",
        "dataset": {"name": f"{RESUME_ATLAS_V1['name']} + {KAGGLE_V1['name']}",
                    "licence": f"{RESUME_ATLAS_V1['licence']} + {KAGGLE_V1['licence']}",
                    "sha256_prefix": f"{RESUME_ATLAS_V1['sha256_prefix']} + {KAGGLE_V1['sha256_prefix']}"},
        "dataset_size": {"train": None, "test": None, "categories": len(config["labels"])},
        "metrics": {k: round(test[k], 4) for k in ("accuracy", "precision_macro", "recall_macro", "f1_macro",
                                                   "top3_accuracy")},
        "cv_f1_macro": round(metrics["validation"].get("eval_f1_macro", float("nan")), 4),
        "train_seconds": round(metrics["train_seconds"], 2),
        "compared_with": reg["deployed"],
        "status": "candidate",
        "file": f"{version}/model.onnx",
    })
    registry.save(reg)
    return version


def main() -> int:
    parser = argparse.ArgumentParser(description="Import a fine-tuned Transformer as a model version.")
    parser.add_argument("action", choices=["import"])
    parser.add_argument("folder", type=Path)
    args = parser.parse_args()
    version = import_candidate(args.folder)
    print(f"Imported as {version} (not deployed). Evaluate: python -m app.ml.evaluate {version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
