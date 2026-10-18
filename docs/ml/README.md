# Model training report

CareerBridge AI career-direction classifier, 18 October 2026.
For the charted version, open [docs/report/index.html](../report/index.html) in a browser (works offline).

**Summary.** v5, a fine-tuned DeBERTa-v3-small exported to ONNX, classifies 88.2% of test resumes correctly against 81.5% for the deployed v2 SVM. Both are measured on the same held-out test set: 2,817 resumes across 45 career categories. v5 is a candidate and has not been deployed yet.

| | v2 SVM (deployed) | v5 Transformer |
|---|---|---|
| Category accuracy (top-1) | 0.815 | **0.882** |
| Macro F1 | 0.809 | **0.868** |
| Category top-3 | 0.938 | 0.938 |
| Field accuracy (17 fields, top-1) | 0.855 | **0.919** |
| Field top-3 | 0.964 | 0.962 |
| Time per resume (CPU) | **≈ 0.014 s** | ≈ 0.31 s |

## Contents

- [All model versions](#all-model-versions)
- [Data and split](#data-and-split)
- [GPU training attempts](#gpu-training-attempts)
- [Results per epoch](#results-per-epoch)
- [Setup](#setup)
- [Issues found and fixed](#issues-found-and-fixed)
- [Error analysis of v5](#error-analysis-of-v5)
- [Deployment trade-off](#deployment-trade-off)
- [Search for Malaysian resume data](#search-for-malaysian-resume-data)
- [Next steps](#next-steps)
- [Reproduce](#reproduce)

## All model versions

| Version | Model | Top-1 | Macro F1 | Top-3 | Field top-1 | Size | Status |
|---|---|---|---|---|---|---|---|
| v1 | Random Forest, TF-IDF (Kaggle only, 24 classes) | 0.718 | 0.658 | — | — | — | previous |
| v2 | Linear SVM, TF-IDF words | 0.815 | 0.809 | 0.938 | 0.855 | 65 MB | **deployed** |
| v3 | DeBERTa-v3-small, ONNX int8 (GPU run A) | 0.784 | — | 0.889 | — | 172 MB | rejected |
| v4 | Linear SVM, TF-IDF words + characters | 0.815 | 0.806 | 0.937 | 0.856 | 223 MB | not recommended |
| v5 | DeBERTa-v3-small, ONNX fp32 (GPU run B) | 0.882 | 0.868 | 0.938 | 0.919 | 542 MB | **candidate** |

v1 used a smaller dataset and is not directly comparable. For v3–v5, top-1 and top-3 were measured with the exported ONNX file the app actually runs.

v4 shows that adding character n-grams does not help TF-IDF models: it matches v2 while taking about 10× longer to train. The TF-IDF approach levels off around 0.81 on this task.

## Data and split

- **Sources.** ResumeAtlas (MIT, 13,389 resumes) and the Kaggle Resume Dataset (CC0, 2,484 resumes). Kaggle categories are mapped onto ResumeAtlas names, and Kaggle's ENGINEERING category is excluded because it overlaps the specific engineering classes.
- **Cleaning.** Resumes under 100 characters are removed, as are exact duplicates and resumes whose first 400 characters duplicate another's. That leaves 14,081 resumes in 45 categories.
- **Split.** Stratified 80/20 with seed 42: 11,264 train and 2,817 test. Every version since v2 uses this same split.
- **Validation.** For the Transformer, 10% of the training split (1,127 resumes) is held out as validation, leaving 10,137 for training.
- **Selection rule.** The test set is used once, at the end. The best epoch and the export format are chosen on the validation set only.
- **Storage.** All data and model files stay on the developer's machine. They are not uploaded to Supabase or Git.

## GPU training attempts

All times are local (UTC+8) on 18 October 2026. Raw logs are in [logs/](logs/).

| Attempt | Time | Setup | Outcome |
|---|---|---|---|
| 0 | ≈ 11:00 | batch 16 | **Crashed at start.** `warmup_ratio` was removed in transformers 5 and was replaced by `warmup_steps`. A dry run of the ONNX export then showed the checkpoint loads in fp16 by default, so weights are now loaded in fp32. |
| 1 | ≈ 11:03 – 11:30 | batch 16 | **Stopped manually.** VRAM was full (7.9 / 8.2 GB), 0.9 GB spilled into Windows shared memory, and the GPU drew only 38–40 W. Epoch 1 had not finished after 30 minutes. See [logs/attempt-1-batch16-status.log](logs/attempt-1-batch16-status.log). |
| A | 11:32 – 12:03 | batch 8 × 2 accumulation | **Completed** in 27.8 min. PyTorch test accuracy 0.872. Exported to int8 with the MatMul and embedding layers quantised, which dropped ONNX test accuracy to 0.784, so it was registered as v3 and rejected. See [logs/run-a-status.log](logs/run-a-status.log). |
| **B** | 12:21 – 12:59 | batch 8 × 2 accumulation | **Completed** in 26.8 min. PyTorch test accuracy 0.882. int8 (MatMul only) matched PyTorch on 86.6% of validation resumes and fp32 on 100%, so fp32 was chosen and registered as v5. See [logs/run-b-progress.log](logs/run-b-progress.log) and [logs/run-b-status.log](logs/run-b-status.log). |

An earlier attempt to fine-tune on Kaggle was abandoned because the notebook session had no GPU attached and ran too slowly. The notebook remains in `ai_backend/notebooks/`.

## Results per epoch

The validation set has 1,127 resumes.

| Epoch | Run A accuracy | Run A macro F1 | Run B accuracy | Run B macro F1 | Run B top-3 |
|---|---|---|---|---|---|
| 1 | 0.662 | 0.568 | 0.721 | 0.629 | 0.847 |
| 2 | 0.841 | 0.800 | 0.863 | 0.831 | 0.918 |
| 3 | 0.875 | 0.861 | 0.874 | 0.858 | 0.931 |
| **4 (kept)** | 0.889 | 0.880 | 0.881 | 0.867 | 0.936 |

Test set, measured once:

| | Run A | Run B (v5) |
|---|---|---|
| Accuracy | 0.8722 | 0.8821 |
| Precision (macro) | 0.8677 | 0.8733 |
| Recall (macro) | 0.8582 | 0.8691 |
| F1 (macro) | 0.8592 | 0.8677 |
| Top-3 accuracy | 0.9329 | 0.9382 |
| Exported ONNX top-1 | 0.7835 (int8) | 0.8821 (fp32) |

The two runs finish within one point of each other, so the result is stable and not down to a lucky seed.

**Training loss (run B).** The trainer reports the sum over the 2 accumulation micro-batches, so the values below are divided by 2. The run starts at about 3.8, which equals ln(45), the loss of a random guess among 45 classes. It ends at about 0.36 after 2,536 optimiser steps.

## Setup

**Hyperparameters**
- Base model: `microsoft/deberta-v3-small`, 142M parameters.
- 4 epochs, learning rate 3e-5, weight decay 0.01, linear schedule with 10% warm-up (253 steps).
- Batch 8 × 2 accumulation steps, for an effective batch of 16 and 2,536 optimiser steps.
- bf16 mixed precision with fp32 master weights.
- Maximum 512 tokens. Long resumes keep the first 382 and last 128 tokens.
- The best epoch is chosen on validation macro F1.

**Hardware and software**
- NVIDIA RTX 4070 Laptop GPU (8 GB, driver 581.15), AMD Ryzen 9 8945H, WSL2 Ubuntu 20.04.
- Training environment `careerbridge-train`: Python 3.12, PyTorch 2.14.1 (CUDA 13.0), transformers 5.20.1, datasets 5.1.0, onnxruntime 1.31.0, onnx 1.23.2.
- App environment `careerbridge-ai`: Python 3.14, onnxruntime 1.31.0, tokenizers 0.23.3. It does not need PyTorch.

**Thermal log, run B (every 5 minutes)**

| Time | Progress | Steps/min | GPU °C | Power W | GPU use | VRAM MiB | CPU load /16 | RAM GB |
|---|---|---|---|---|---|---|---|---|
| 12:23 | 5.1% | 98.7 | 73 | 81.7 | 98% | 6,911 | 1.38 | 3.2 |
| 12:28 | 24.8% | 101.2 | 76 | 85.4 | 95% | 6,978 | 1.37 | 3.2 |
| 12:33 | 43.4% | 97.2 | 74 | 81.9 | 98% | 6,979 | 1.25 | 3.3 |
| 12:38 | 61.9% | 95.9 | 76 | 83.4 | 99% | 6,985 | 1.35 | 3.3 |
| 12:43 | 80.0% | 95.2 | 76 | 83.5 | 96% | 6,980 | 1.07 | 3.4 |
| 12:48 | 100% | 96.6 | 75 | 84.5 | 96% | 6,979 | 1.19 | 3.4 |

A heat guard (`ai_backend/training/heat_guard.sh`) checked the GPU every 5 seconds and would have stopped training at 89 °C. Peak temperature was 76 °C in run B and 78 °C in run A.

## Issues found and fixed

1. **VRAM overflow.** With batch 16, about 0.6 GB spilled into shared system memory, the GPU waited on transfers, and training ran at under 25 steps per minute. Batch 8 with 2 accumulation steps keeps the same effective batch and results, uses 6.9 GB, and runs at about 97 steps per minute.
2. **int8 quantisation.** Quantising the whole network cut test accuracy from 0.872 to 0.784. Quantising only the MatMul layers still matched PyTorch on just 86.6% of validation resumes. v5 therefore ships as fp32 ONNX, which matches PyTorch on 1,127 of 1,127 validation resumes and scores 0.8821 on the test set, identical to PyTorch.
3. **Lost weights in run A.** The first script deleted the PyTorch checkpoint after export. It now keeps the trained model in `models/transformer-candidate/pytorch/` and deletes only the epoch checkpoints.
4. **No visible progress.** The script now writes step, percentage, speed, time left and loss to `data/training_runs/progress.log`. `ai_backend/training/watch_progress.sh` displays that log live, together with GPU temperature and a safety level.

## Error analysis of v5

v5 misclassified 333 of the 2,817 test resumes. The most frequent confusions are between categories that overlap in practice:

| True → predicted | Count |
|---|---|
| Management → PMO | 9 |
| BPO → Management | 8 |
| SQL Developer → Database | 8 |
| Python Developer → React Developer | 7 |
| Finance → Accountant | 6 |
| Python Developer → ETL Developer | 5 |

Spot checks also found label noise. For example, a resume labelled "SQL Developer" opens with "database administrator", and v5 answered Database. Noise like this caps any model's accuracy on this 45-class task. Across categories, 37 of 45 improved over v2. BPO (−0.20 F1) and PMO (−0.19) declined most.

**Confidence is a reliable signal.**

| Model confidence | Share of resumes | Accuracy |
|---|---|---|
| ≥ 0.90 | 85.0% | 94.9% |
| ≥ 0.70 | 91.7% | 92.4% |
| < 0.50 | 3.8% | 31.1% |

**Long resumes are harder.** Resumes of up to 512 tokens are 45% of the test set and score 92.7%. Longer resumes are 55% and score 84.5%, because the middle of a long resume is skipped. Long resumes also come mostly from the Kaggle source, whose labels are noisier, so part of this gap comes from the data rather than from truncation.

## Deployment trade-off

| | v2 SVM | v5 Transformer |
|---|---|---|
| Accuracy | 81.5% | **88.2%** |
| Time per resume (CPU) | **≈ 0.014 s** | ≈ 0.31 s median, 0.45 s worst of 20 |
| Load at backend start-up | **under 1 s** | ≈ 7 s, once |
| Model file | **65 MB** | 542 MB, local only |
| Runtime packages | scikit-learn | onnxruntime + tokenizers |

Users will not notice the extra 0.3 s, because text extraction, OCR and the LLM explanation already take several seconds. The real costs are file size and start-up time.

Deploying and rolling back are each a single command, run from `ai_backend/`:

```bash
python -m app.ml.models_cli deploy v5
python -m app.ml.models_cli rollback
```

## Search for Malaysian resume data

A search of Kaggle, Hugging Face, GitHub and the Malaysian open-data portal found **no public dataset of Malaysian resumes**. Public resume sets have no country field. Related data that does exist:

- **Nemotron-Personas Malaysia** (YTL AI Labs and NVIDIA, September 2026): 1.35 million synthetic personas with occupation, region, age and ethnicity, generated from official Malaysian statistics. Press coverage reports a CC BY 4.0 licence. These are personas, not resumes, but they could seed synthetic Malaysian test resumes.
- **data.gov.my**: aggregate labour statistics such as registrants, vacancies and placements. Useful as context, but contains no resume text.
- **JobStreet feeds and scrapers**: these provide job postings, not resumes. They are paid, and scraping conflicts with JobStreet's terms, so they are not used.

A small, consented set of 30–50 real Malaysian resumes, with personal details removed, remains the most credible way to check v5 on local resumes. It is needed for testing, not retraining.

## Next steps

| Item | Retraining? | Expected effect |
|---|---|---|
| Deploy v5 | No | +6.7 points accuracy in the app |
| Read long resumes in overlapping windows and average the results | No | Estimated +1 to 3 points; to be measured on validation first |
| Show one direction when the model is confident, otherwise the top three | No | 94.9% accuracy on the 85% of resumes shown a single answer |
| Test on 30–50 consented Malaysian resumes | No | First evidence of performance on local resumes |
| Semantic skill matching in the fit score | No (uses a pre-trained embedding model) | Fewer missed skills, e.g. "spreadsheets" ≈ Excel |
| Larger model (DeBERTa-v3-base) | Yes, ≈ 2 h | Possibly +1 to 2 points, 3× slower; deferred |

## Reproduce

Run these from `ai_backend/`:

```bash
# 1. Export the data with the same split as the TF-IDF models (env careerbridge-ai)
python -m app.ml.export_for_kaggle

# 2. Fine-tune on the GPU (env careerbridge-train)
python training/finetune_transformer.py
bash training/heat_guard.sh 89          # optional, in a second terminal
bash training/watch_progress.sh         # optional, live progress

# 3. Register and evaluate (env careerbridge-ai)
python -m app.ml.transformer import models/transformer-candidate
python -m app.ml.evaluate v5
```
