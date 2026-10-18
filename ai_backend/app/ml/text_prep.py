"""Turn resume text into the clean form the model is trained on.

The same function is used for training and for predictions, so a resume
uploaded later is processed exactly like the training data.
"""

import re

_URL = re.compile(r"https?://\S+|www\.\S+")
_EMAIL = re.compile(r"\S+@\S+\.\S+")
_PHONE = re.compile(r"\+?\d[\d\s().-]{7,}\d")
# Keep letters, digits and the symbols used in skill names (C++, C#, .NET, Node.js).
_NOT_KEPT = re.compile(r"[^a-z0-9+#.]+")
_LONE_DOTS = re.compile(r"(?<![a-z0-9])\.|\.(?![a-z0-9])")


def clean_resume_text(text: str) -> str:
    text = text.lower()
    text = _URL.sub(" ", text)
    text = _EMAIL.sub(" ", text)
    text = _PHONE.sub(" ", text)
    text = _NOT_KEPT.sub(" ", text)
    text = _LONE_DOTS.sub(" ", text)
    return " ".join(text.split())
