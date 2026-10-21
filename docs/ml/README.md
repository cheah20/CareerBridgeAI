# Model training report

CareerBridge AI career-direction classifier, 18 October 2026.
For the charted version, open [docs/report/index.html](../report/index.html) in a browser (works offline).

## Part 2 — testing on real Malaysian CVs (18 October 2026, afternoon)

**Summary.** v5's public-test lead came from a formatting shortcut; normalising the text fixed it (v6). On 58 real
Malaysian CVs, v2, v6, v7 and v8 are statistically tied (91–95% with every reasonable answer accepted); only v5 is
clearly worse (61%). An earlier reading that v8 led by 13 points was traced to labelling conventions (see the audit
below). **The small SVM, v2, stays deployed.**

### The formatting shortcut

83% of the training text (ResumeAtlas) is stored lowercased, without punctuation and without stop words; 17% (Kaggle)
is ordinary prose, and prose appears in only 23 of the 45 categories. v5 learned "prose means a Kaggle category",
so real resumes (always prose) could never be classed as Data Science, Python Developer, Civil Engineer and 19 other
categories. On 45 synthetic Malaysian resumes v5 scored 57.8% against 93.3% for v2.
**Fix:** from v6 on, every text is normalised to one form (lowercase, punctuation removed, NLTK stop words removed)
in training and in prediction.

### Synthetic Malaysian resumes

No public dataset of Malaysian resumes exists. Two kinds of synthetic resumes were compared:

| | Rough set (v7) | Template-based set (v8) |
|---|---|---|
| Resumes | 45, one per category | 158, one per CareerBridge role (126 map to the 45 categories) |
| How | One LLM call each, plain text | Random profile drawn in code (level, jobs, part-time, freelance, internships, gaps, career switches, MY/SG, languages), written up by the LLM in one of six layouts modelled on the Malaysian CV pack, the JobStreet template and a career-guide CV; typeset as PDF / Word / JPG and read back with the app's extractor (incl. OCR) |
| Added to training | 45 × 10 = 450 rows | 126 × 4 = 504 rows |

The 58 real CVs were used only as style references and never trained on.

### Results on 58 real Malaysian CVs

Field = 17 CareerBridge fields (all 58 CVs); category = 45 dataset categories (45 CVs with a matching category).

| Model | Training data | Field top-1 | Field top-3 | Category top-1 | Category top-3 | Public test |
|---|---|---|---|---|---|---|
| v2 | SVM, public data | 0.603 | 0.879 | 0.711 | 0.911 | 0.815 |
| v5 | Transformer, public data (shortcut) | 0.414 | 0.603 | 0.511 | 0.622 | 0.882 |
| v6 | Transformer, normalised text | 0.586 | 0.862 | 0.733 | 0.889 | 0.861 |
| v7 | v6 + rough synthetic | 0.586 | 0.776 | 0.711 | 0.889 | 0.870 |
| **v8** | v6 + template-based synthetic | **0.672** | **0.914** | **0.844** | **0.933** | 0.860 |

These single-label scores overstate v8: see the audit below.

**Blind LLM review.** For each real CV, the top-3 answers of all five models were pooled, shuffled and shown without
model names; DeepSeek rated each 0–3 for fit.

| Model | Mean score, first answer | First answer useful (2–3) | Exact (3) | Wrong (0) | Best of top-3 |
|---|---|---|---|---|---|
| v2 | 2.50 | 84.5% | 67.2% | 1.7% | 2.76 |
| v5 | 1.72 | 56.9% | 44.8% | 29.3% | 1.98 |
| v6 | 2.36 | 79.3% | 60.3% | 3.4% | 2.74 |
| v7 | 2.38 | 84.5% | 60.3% | 6.9% | 2.78 |
| v8 | 2.47 | 86.2% | 62.1% | 1.7% | 2.83 |

The reviewer agreed with the developer-confirmed labels on 86% of fields and 78% of categories. By this review v8 and
v2 are close (v8: more useful first answers and the best top-3; v2: more exact first answers); v5 is clearly worst.

**Limits.** Small sample (v8 vs v2 on category top-1: 38 vs 32 of 45 CVs). 13 real CVs (administrative, advertising,
compliance, hospitality, oil and gas, supply chain) have no matching category, which caps field top-1. The 58 CVs
come from one template pack.

### Audit of the results (no LLM calls)

| Check | Result |
|---|---|
| Synthetic resumes copied the real CVs (shared 8-word phrases) | No: 2 of 158, generic phrases only |
| Wrong model file or text setting | No: checksums and text form verified |
| Scores recomputed from the raw predictions | Match |
| Where v8 beat v2 (6 CVs) | Only 1–2 clear wins; 4 depend on conventions such as Marketing → Sales, Writer → Digital Media, Software Engineer → Information Technology, applied by the same person to the synthetic training labels and the real test labels |

**Independent re-scoring.** Each real CV was read and every reasonable category accepted (56 CVs; 2 have no
reasonable category among the 45):

| Model | Accuracy | vs v8 (only-this-right : only-v8-right, McNemar p) |
|---|---|---|
| v2 | 92.9% | 3 : 4, p = 1.0 |
| v5 | 60.7% | v2 vs v5: 20 : 2, p < 0.001 |
| v6 | 91.1% | 1 : 3, p = 0.63 |
| v7 | 91.1% | 1 : 3, p = 0.63 |
| v8 | 94.6% | — |

**Conclusion.** The format fix is a real gain. A benefit from synthetic training data is not shown on these CVs.
v2 stays deployed (65 MB, 0.014 s per CV, same accuracy). Not yet measured: run-to-run variance; the real CVs come
from one template pack; the re-scoring was done by one reviewer who had seen the model answers.

### GPU runs in Part 2

| Run | Time | Load | Training | Peak °C | Avg power | Val acc (epoch 1 → 4) | Test acc |
|---|---|---|---|---|---|---|---|
| v6 | 14:15 – 14:53 | full speed | 25.2 min | 78 | ≈ 85 W | 0.677 → 0.858 | 0.861 |
| v7 (experiment 1) | 15:13 – 16:35 | 1 s pause per step | 68.7 min | 75 | 43.8 W | 0.704 → 0.875 | 0.870 |
| v8 (experiment 2) | 16:35 – 17:58 | 1 s pause per step | 70.2 min | 73 | 43.6 W | 0.677 → 0.860 | 0.860 |

Same hyperparameters as Part 1; identical validation and test sets. The experiments ran unattended with a pause
after each step (half the average power) and an 85 °C heat guard that never triggered. int8 export again fell short
of 99% agreement (95.4–95.6%), so all three ship as fp32 ONNX.

### Issues fixed in Part 2

- **Formatting shortcut** — text normalisation (above).
- **Memory growth** — scoring resumes of many lengths made ONNX Runtime reserve memory per input size (14 GB in one
  run). The memory arena is now off, batches are smaller, one model is loaded at a time; this also protects the backend.
- **Incomplete LLM answers** — 8 of 158 synthetic resumes hit the reasoning token limit; regenerated with a higher token limit.
- **Job chaining** — a waiting script matched its own command line; process checks now match only the training process.

### Limits and next steps

- **Test data.** A search for more real resumes (Malaysian and Singaporean university career centres, Malaysian
  job sites, open datasets on Hugging Face, Kaggle and Mendeley) found no lawful source: public sets either reuse the
  LiveCareer resumes already in the training data, are LLM-generated, or are protected against automated access.
  The 58-CV sample pack remains the only real-CV test set.
- **Unvalidated roles.** Administrative, logistics, supply chain and oil and gas roles have no category in the
  public data and no real CVs to test on; results for them are not claimed.
- **Decision.** v2 stays deployed and work returns to the application. Models will be re-tested when consented real
  resumes are available (for example from users who agree to it). The large synthetic batch is on hold
  (37 resumes generated).

---

# Part 1 — first Transformer runs (18 October 2026, morning)

The rest of this document is the morning's report. Its conclusion that v5 was best held only on the public test
set; Part 2 explains why.

**Summary of Part 1.** v5, a fine-tuned DeBERTa-v3-small exported to ONNX, classifies 88.2% of test resumes correctly against 81.5% for the deployed v2 SVM. Both are measured on the same held-out test set: 2,817 resumes across 45 career categories. (Part 2 found this lead came from a formatting shortcut; v2 stays deployed.)

| | v2 SVM | v5 Transformer |
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
| v5 | DeBERTa-v3-small, ONNX fp32 (GPU run B) | 0.882 | 0.868 | 0.938 | 0.919 | 542 MB | previous (format shortcut) |
| v6 | DeBERTa-v3-small, normalised text | 0.861 | 0.840 | 0.927 | — | 542 MB | candidate |
| v7 | v6 + rough synthetic resumes | 0.870 | 0.857 | 0.929 | — | 542 MB | candidate |
| v8 | v6 + template-based synthetic resumes | 0.860 | 0.840 | 0.933 | — | 542 MB | candidate |

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

An earlier attempt to fine-tune on Kaggle was abandoned because the notebook session had no GPU attached and ran too slowly. The notebook is no longer in the repository; a copy is kept on the developer's computer.

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

Users will not notice the extra 0.3 s, because text extraction, OCR and the LLM explanation already take several seconds. The real trade-offs are file size and start-up time.

Deploying and rolling back are each a single command, run from `ai_backend/`:

```bash
python -m app.ml.models_cli deploy v5
python -m app.ml.models_cli rollback
```

## Search for Malaysian resume data

A search of Kaggle, Hugging Face, GitHub and the Malaysian open-data portal found **no public dataset of Malaysian resumes**. Public resume sets have no country field. Related data that does exist:

- **Nemotron-Personas Malaysia** (YTL AI Labs and NVIDIA, September 2026): 1.35 million synthetic personas with occupation, region, age and ethnicity, generated from official Malaysian statistics. Press coverage reports a CC BY 4.0 licence. These are personas, not resumes, but they could seed synthetic Malaysian test resumes.
- **data.gov.my**: aggregate labour statistics such as registrants, vacancies and placements. Useful as context, but contains no resume text.
- **JobStreet feeds and scrapers**: these provide job postings, not resumes. Scraping conflicts with JobStreet's terms, so they are not used.

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
