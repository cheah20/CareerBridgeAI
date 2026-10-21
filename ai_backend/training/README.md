# Model training scripts

Scripts used to train the career direction models on the developer's GPU.
Results and the written report are in [docs/ml/](../../docs/ml/).

| File | What it is |
|---|---|
| `finetune_transformer.py` | Trains the larger language model |
| `run_experiments.sh` | Runs several trainings one after another |
| `heat_guard.sh` | Stops training if the GPU gets too hot |
| `watch_progress.sh` | Shows training progress |
| `requirements-train.txt` | Extra Python packages needed only for training |
