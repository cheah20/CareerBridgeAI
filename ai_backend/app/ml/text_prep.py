"""Turn resume text into the clean form the model is trained on."""

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


# NLTK's English stop-word list.
_STOP_WORDS = frozenset("""
i me my myself we our ours ourselves you you're you've you'll you'd your yours yourself yourselves he him his
himself she she's her hers herself it it's its itself they them their theirs themselves what which who whom this
that that'll these those am is are was were be been being have has had having do does did doing a an the and but
if or because as until while of at by for with about against between into through during before after above below
to from up down in out on off over under again further then once here there when where why how all any both each
few more most other some such no nor not only own same so than too very s t can will just don don't should
should've now d ll m o re ve y ain aren aren't couldn couldn't didn didn't doesn doesn't hadn hadn't hasn hasn't
haven haven't isn isn't ma mightn mightn't mustn mustn't needn needn't shan shan't shouldn shouldn't wasn wasn't
weren weren't won won't wouldn wouldn't
""".split())
_PUNCT = re.compile(r"[^\w\s+#]|_")


def normalise_resume_text(text: str) -> str:
    """One text form for the Transformer: lowercase, punctuation deleted, stop words removed."""
    text = text.lower()
    text = _URL.sub(" ", text)
    text = _EMAIL.sub(" ", text)
    text = _PUNCT.sub("", text)
    return " ".join(w for w in text.split() if w not in _STOP_WORDS)
