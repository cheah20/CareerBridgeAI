"""Fine-tune DeBERTa-v3-small as a resume career classifier on the local GPU."""

import argparse
import json
import os
import shutil
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd
import torch
from datasets import Dataset
from sklearn.metrics import accuracy_score, classification_report, precision_recall_fscore_support
from sklearn.model_selection import train_test_split
from transformers import (AutoModelForSequenceClassification, AutoTokenizer, DataCollatorWithPadding, Trainer,
                          TrainerCallback, TrainingArguments)

BACKEND = Path(__file__).resolve().parents[2] / "ai_backend"
sys.path.insert(0, str(BACKEND))
from app.ml.text_prep import normalise_resume_text  # noqa: E402  (plain-Python module, no app settings needed)

DATA = BACKEND / "data" / "kaggle_upload" / "careerbridge-resumes-v2"
OUT = BACKEND / "models" / "transformer-candidate"
WORK = BACKEND / "data" / "training_runs" / "deberta"
PROGRESS = BACKEND / "data" / "training_runs" / "progress.log"

MODEL_NAME = "microsoft/deberta-v3-small"
MAX_LEN, HEAD, TAIL = 512, 382, 128   # long resumes: keep the start and the end
EPOCHS, LR, SEED = 4, 3e-5, 42
BATCH, ACCUM = 8, 2   # effective batch 16; batch 8 fits in 8 GB VRAM without spilling into shared memory


def note(line: str) -> None:
    with PROGRESS.open("a") as f:
        f.write(time.strftime("%H:%M:%S ") + line + "\n")


class Throttle(TrainerCallback):
    """Short pause after each step to keep the GPU cooler."""

    def __init__(self, seconds: float):
        self.seconds = seconds

    def on_step_end(self, args, state, control, **kwargs):
        time.sleep(self.seconds)


class ProgressLog(TrainerCallback):
    """One line every 10 steps: step, %, speed, time left, loss, readable with tail -f."""

    def __init__(self):
        self.start = time.time()
        self.loss = None
        PROGRESS.parent.mkdir(parents=True, exist_ok=True)
        PROGRESS.write_text("")

    def _write(self, line):
        note(line)

    def on_log(self, args, state, control, logs=None, **kwargs):
        if logs and "loss" in logs:
            self.loss = logs["loss"]

    def on_step_end(self, args, state, control, **kwargs):
        step, total = state.global_step, state.max_steps
        if step % 10 and step != total:
            return
        spent = time.time() - self.start
        left = spent / step * (total - step)
        loss = f"{self.loss:.3f}" if self.loss is not None else "-"
        self._write(f"epoch {state.epoch:4.2f}/{EPOCHS} | step {step}/{total} ({100 * step / total:5.1f}%) | "
                    f"{step / spent * 60:5.1f} steps/min | {left / 60:5.1f} min left | loss {loss}")

    def on_evaluate(self, args, state, control, metrics=None, **kwargs):
        m = metrics or {}
        self._write(f"== validation after epoch {round(state.epoch)}: accuracy {m.get('eval_accuracy', 0):.4f}, "
                    f"macro F1 {m.get('eval_f1_macro', 0):.4f}, top-3 {m.get('eval_top3_accuracy', 0):.4f}")


def main() -> None:
    global OUT
    parser = argparse.ArgumentParser(description="Fine-tune DeBERTa-v3-small on the resume dataset.")
    parser.add_argument("--extra", type=Path, help="JSONL of extra training resumes with 'label' and 'text'")
    parser.add_argument("--extra-repeat", type=int, default=1, help="times each extra resume is repeated")
    parser.add_argument("--out", type=Path, default=OUT, help="output folder (relative to ai_backend/)")
    parser.add_argument("--throttle", type=float, default=0.0,
                        help="seconds to pause after each step (lower GPU load and temperature; slower)")
    cli = parser.parse_args()
    OUT = cli.out if cli.out.is_absolute() else BACKEND / cli.out
    assert torch.cuda.is_available(), "No GPU found"
    print("GPU:", torch.cuda.get_device_name(0))
    OUT.mkdir(parents=True, exist_ok=True)

    train_df = pd.read_csv(DATA / "train.csv")
    test_df = pd.read_csv(DATA / "test.csv")
    labels = json.loads((DATA / "labels.json").read_text())
    # Same text format for every source.
    for df in (train_df, test_df):
        df["text"] = df["text"].map(normalise_resume_text)
    label2id = {label: i for i, label in enumerate(labels)}
    train_df["y"] = train_df["label"].map(label2id)
    test_df["y"] = test_df["label"].map(label2id)
    tr_df, val_df = train_test_split(train_df, test_size=0.1, stratify=train_df["y"], random_state=SEED)
    extra_info = None
    if cli.extra:
        # Extra resumes go into training only, so runs compare fairly.
        rows = [json.loads(line) for line in (BACKEND / cli.extra).read_text(encoding="utf-8").splitlines() if line.strip()]
        extra = pd.DataFrame([{"text": normalise_resume_text(r["text"]), "label": r["label"]} for r in rows
                              if r.get("label") in label2id])
        extra["y"] = extra["label"].map(label2id)
        skipped = len(rows) - len(extra)
        tr_df = pd.concat([tr_df] + [extra] * cli.extra_repeat, ignore_index=True).sample(frac=1, random_state=SEED)
        extra_info = {"file": str(cli.extra), "resumes": len(extra), "repeat": cli.extra_repeat, "skipped": skipped}
        print(f"extra: {len(extra)} resumes x {cli.extra_repeat} added to training ({skipped} skipped: unknown label)")
    print(len(tr_df), "train /", len(val_df), "validation /", len(test_df), "test /", len(labels), "labels")

    tok = AutoTokenizer.from_pretrained(MODEL_NAME)

    def encode(batch):
        ids = tok(batch["text"], add_special_tokens=False, truncation=False)["input_ids"]
        out = []
        for x in ids:
            if len(x) > MAX_LEN - 2:
                x = x[:HEAD] + x[-TAIL:]
            out.append([tok.cls_token_id] + x + [tok.sep_token_id])
        return {"input_ids": out, "attention_mask": [[1] * len(x) for x in out], "labels": batch["y"]}

    def to_ds(df):
        return Dataset.from_pandas(df[["text", "y"]].reset_index(drop=True)).map(
            encode, batched=True, remove_columns=["text", "y"])

    ds_train, ds_val, ds_test = to_ds(tr_df), to_ds(val_df), to_ds(test_df)

    def metrics(pred):
        logits, y = pred
        p = logits.argmax(-1)
        pr, rc, f1, _ = precision_recall_fscore_support(y, p, average="macro", zero_division=0)
        top3 = np.mean([t in row for t, row in zip(y, np.argsort(-logits, axis=1)[:, :3])])
        return {"accuracy": accuracy_score(y, p), "precision_macro": pr, "recall_macro": rc, "f1_macro": f1,
                "top3_accuracy": top3}

    model = AutoModelForSequenceClassification.from_pretrained(
        MODEL_NAME, num_labels=len(labels), id2label=dict(enumerate(labels)), label2id=label2id,
        dtype=torch.float32)  # fp32 master weights; bf16 is only used inside autocast
    warmup = int(0.1 * EPOCHS * -(-len(ds_train) // (BATCH * ACCUM)))  # 10% of all optimiser steps
    args = TrainingArguments(
        output_dir=str(WORK), num_train_epochs=EPOCHS, learning_rate=LR, weight_decay=0.01, warmup_steps=warmup,
        per_device_train_batch_size=BATCH, gradient_accumulation_steps=ACCUM, per_device_eval_batch_size=16,
        bf16=True, disable_tqdm=True,
        eval_strategy="epoch", save_strategy="epoch", save_total_limit=1, load_best_model_at_end=True,
        metric_for_best_model="f1_macro", logging_steps=50, report_to="none", seed=SEED,
        dataloader_num_workers=2)
    trainer = Trainer(model=model, args=args, train_dataset=ds_train, eval_dataset=ds_val,
                      data_collator=DataCollatorWithPadding(tok), compute_metrics=metrics, callbacks=[ProgressLog()] + ([Throttle(cli.throttle)] if cli.throttle else []))
    start = time.time()
    trainer.train()
    train_seconds = time.time() - start
    print(f"training took {train_seconds / 60:.1f} min")

    # Keep the trained PyTorch model, so ONNX can be re-exported without retraining.
    trainer.save_model(str(OUT / "pytorch"))
    tok.save_pretrained(str(OUT / "pytorch"))
    shutil.rmtree(WORK, ignore_errors=True)  # epoch checkpoints with optimiser state (~1.7 GB)

    # Final, one-time evaluation on the held-out test set.
    note("testing on the held-out test set ...")
    pred = trainer.predict(ds_test)
    logits = pred.predictions.astype(np.float32)
    test_metrics = metrics((logits, pred.label_ids))
    report = classification_report(pred.label_ids, logits.argmax(-1), labels=list(range(len(labels))),
                                   target_names=labels, output_dict=True, zero_division=0)
    val_pred = trainer.predict(ds_val, metric_key_prefix="eval")
    val_metrics = val_pred.metrics
    val_top1 = val_pred.predictions.argmax(-1)
    note(f"test (PyTorch): accuracy {test_metrics['accuracy']:.4f}, macro F1 {test_metrics['f1_macro']:.4f}, "
         f"top-3 {test_metrics['top3_accuracy']:.4f}")
    print(json.dumps({k: round(float(v), 4) for k, v in test_metrics.items()}, indent=2))

    # Export to ONNX (fp32), plus an int8 version of the MatMul layers only.
    from onnxruntime.quantization import QuantType, quantize_dynamic
    import onnxruntime as ort

    note("exporting ONNX ...")
    model = trainer.model.eval().float().to("cpu")
    dummy = tok("sample resume text", return_tensors="pt")
    fp32, int8 = OUT / "model_fp32.onnx", OUT / "model_int8.onnx"
    torch.onnx.export(model, (dummy["input_ids"], dummy["attention_mask"]), str(fp32),
                      input_names=["input_ids", "attention_mask"], output_names=["logits"], opset_version=17,
                      dynamic_axes={"input_ids": {0: "batch", 1: "seq"}, "attention_mask": {0: "batch", 1: "seq"},
                                    "logits": {0: "batch"}}, dynamo=False)
    quantize_dynamic(str(fp32), str(int8), weight_type=QuantType.QInt8, op_types_to_quantize=["MatMul"])
    tok.backend_tokenizer.save(str(OUT / "tokenizer.json"))

    # Pick the export that agrees best with PyTorch on the validation set.
    def onnx_top1(path):
        sess = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
        out = []
        for i in range(0, len(ds_val), 16):
            rows = ds_val[i:i + 16]["input_ids"]
            width = max(map(len, rows))
            ids = np.full((len(rows), width), tok.pad_token_id, dtype=np.int64)
            mask = np.zeros((len(rows), width), dtype=np.int64)
            for j, row in enumerate(rows):
                ids[j, :len(row)], mask[j, :len(row)] = row, 1
            out.append(sess.run(None, {"input_ids": ids, "attention_mask": mask})[0].argmax(-1))
            if i % 320 == 0:
                note(f"  checking {path.name}: {i}/{len(ds_val)}")
        return np.concatenate(out)

    agreement = {}
    for name, path in (("int8", int8), ("fp32", fp32)):
        agreement[name] = float(np.mean(onnx_top1(path) == val_top1))
        note(f"{name} ONNX agrees with PyTorch on {agreement[name]:.2%} of {len(ds_val)} validation resumes")
    chosen = "int8" if agreement["int8"] >= 0.99 else "fp32"
    shutil.copy2(int8 if chosen == "int8" else fp32, OUT / "model.onnx")
    fp32.unlink()
    int8.unlink()
    note(f"chosen: {chosen} ({(OUT / 'model.onnx').stat().st_size / 1e6:.0f} MB)")

    (OUT / "config.json").write_text(json.dumps({
        "model_name": MODEL_NAME, "labels": labels, "max_len": MAX_LEN, "head": HEAD, "tail": TAIL,
        "cls_id": tok.cls_token_id, "sep_id": tok.sep_token_id, "pad_id": tok.pad_token_id,
        "onnx_precision": chosen, "text_form": "normalised"}, indent=2))
    (OUT / "metrics.json").write_text(json.dumps({
        "test": {k: float(v) for k, v in test_metrics.items()},
        "validation": {k: float(v) for k, v in val_metrics.items() if isinstance(v, (int, float))},
        "per_class": report, "train_seconds": train_seconds, "epochs": EPOCHS, "learning_rate": LR,
        "onnx_precision": chosen, "onnx_validation_agreement": agreement, "extra_training_data": extra_info,
        "throttle_seconds_per_step": cli.throttle,
        "gpu": torch.cuda.get_device_name(0)}, indent=2))
    note("DONE")
    print("Saved to", OUT, sorted(os.listdir(OUT)))


if __name__ == "__main__":
    main()
