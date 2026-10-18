"""Skill-name normalisation shared by the catalogue builder and resume matching."""

import re

# A dot is kept only inside a word ("node.js", "asp.net"), not at the end of a sentence ("sql.").
TOKEN = r"(?u)[a-z0-9](?:[a-z0-9+#]|\.(?=[a-z0-9]))*"
_TOKEN = re.compile(TOKEN)

# "Microsoft Excel" is also written "Excel"; "Adobe Photoshop" as "Photoshop".
_VENDORS = {"microsoft", "adobe", "autodesk", "atlassian", "apache", "ibm", "oracle", "google", "amazon", "intuit", "sap"}
# Fragments that are too vague to count as a skill on their own after splitting a long name.
_TOO_GENERIC = {"management", "preparation", "documentation", "maintenance", "control", "planning", "compliance",
                "supervision", "systems", "principles", "practice", "practices", "skills", "knowledge", "work",
                "evaluation", "coordination", "administration"}


def skill_key(text: str) -> str:
    """Normalise a skill name for matching: lowercase, no brackets, simple tokens."""
    text = re.sub(r"\([^)]*\)", " ", str(text).lower())
    text = re.sub(r"\s+software$", "", text.strip())  # "Tableau software" -> "tableau" (only at the end)
    return " ".join(_TOKEN.findall(text))


def skill_aliases(name: str) -> set[str]:
    """Other ways a resume may write the same skill."""
    key = skill_key(name)
    aliases = {key}
    words = key.split()
    if len(words) > 1 and words[0] in _VENDORS:
        aliases.add(" ".join(words[1:]))
    # Acronyms in the original name: "Amazon Web Services AWS" -> "aws", "Structured query language SQL" -> "sql"
    for word in re.findall(r"\b[A-Z][A-Z0-9+#]{1,5}\b", str(name)):
        aliases.add(word.lower())
    # Lists inside the name: "Cost estimation and budgeting", "AGM / EGM", "Vector databases (FAISS, Pinecone)"
    inner = " , ".join(re.findall(r"\(([^)]*)\)", str(name)))
    outer = re.sub(r"\([^)]*\)", " ", str(name))
    for chunk in (outer, inner):
        for part in re.split(r",|/|\band\b|\bor\b|;", chunk):
            part_key = skill_key(re.sub(r"^\s*(including|e\.g\.|eg)\s+", "", part.strip(), flags=re.IGNORECASE))
            if part_key and len(part_key.split()) <= 4:
                aliases.add(part_key)
                words = part_key.split()
                if len(words) > 1 and words[-1] in _TOO_GENERIC:
                    aliases.add(" ".join(words[:-1]))  # "bill of quantities preparation" -> "bill of quantities"
    return {a for a in aliases if len(a) > 1 and a not in _TOO_GENERIC}


def text_ngrams(text: str, max_n: int = 4) -> set[str]:
    """All 1- to 4-word phrases in a text, normalised like skill keys."""
    tokens = _TOKEN.findall(str(text).lower())
    return {" ".join(tokens[i:i + n]) for n in range(1, max_n + 1) for i in range(len(tokens) - n + 1)}
