import json
import sys

import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline

from metrics import classification_scores

# change these to your own file, columns and the label you care about
DATA = sys.argv[1] if len(sys.argv) > 1 else "example.csv"
TEXT, LABEL, POSITIVE = "text", "label", "fake"

df = pd.read_csv(DATA)
X_train, X_test, y_train, y_test = train_test_split(
    df[TEXT], df[LABEL], test_size=0.25, random_state=42, stratify=df[LABEL]
)

methods = {
    "Logistic Regression": make_pipeline(TfidfVectorizer(lowercase=True), LogisticRegression(max_iter=1000)),
    "Random Forest": make_pipeline(TfidfVectorizer(lowercase=True), RandomForestClassifier(n_estimators=200, random_state=42)),
}

results = {}
for name, model in methods.items():
    model.fit(X_train, y_train)
    results[name] = classification_scores(y_test, model.predict(X_test), POSITIVE)

print(f"{'Method':<22}{'Accuracy':>10}{'Precision':>11}{'Recall':>9}{'F1':>7}")
for name, s in results.items():
    print(f"{name:<22}{s['accuracy']:>10.3f}{s['precision']:>11.3f}{s['recall']:>9.3f}{s['f1']:>7.3f}")

# words that push a text most towards the positive label
lr = methods["Logistic Regression"]
words = lr[0].get_feature_names_out()
weights = lr[1].coef_[0] if lr[1].classes_[1] == POSITIVE else -lr[1].coef_[0]
top = [w for _, w in sorted(zip(weights, words), reverse=True)[:10]]
print("\nTop signals:", ", ".join(top))

json.dump({"results": results, "top_signals": top}, open("results.json", "w"), indent=2)
print("Saved results.json")
