from sklearn.metrics import accuracy_score, precision_recall_fscore_support


# for models that sort text into labels (for example fake or real)
def classification_scores(true, pred, positive) -> dict:
    p, r, f, _ = precision_recall_fscore_support(true, pred, pos_label=positive, average="binary", zero_division=0)
    return {"accuracy": accuracy_score(true, pred), "precision": p, "recall": r, "f1": f}


# for skill lists: each argument is a list of skill lists, one per job description
def skill_scores(true: list[list[str]], pred: list[list[str]]) -> dict:
    hit = found = wanted = 0
    for t, p in zip(true, pred):
        t, p = {s.lower() for s in t}, {s.lower() for s in p}
        hit += len(t & p)
        found += len(p)
        wanted += len(t)
    precision = hit / found if found else 0.0
    recall = hit / wanted if wanted else 0.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    return {"precision": precision, "recall": recall, "f1": f1}


# for recommendations: share of the top k results that really fit
def precision_at_k(ranked: list[list[str]], relevant: list[set[str]], k: int = 5) -> float:
    scores = [len(set(r[:k]) & rel) / k for r, rel in zip(ranked, relevant)]
    return sum(scores) / len(scores) if scores else 0.0
