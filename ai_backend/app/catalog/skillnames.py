"""Skill-name normalisation shared by the catalogue builder and resume matching."""

import re

# Keep dots inside words like "node.js", drop them at the end.
TOKEN = r"(?u)[a-z0-9](?:[a-z0-9+#]|\.(?=[a-z0-9]))*"
_TOKEN = re.compile(TOKEN)

# "Microsoft Excel" is also written "Excel"; "Adobe Photoshop" as "Photoshop".
_VENDORS = {"microsoft", "adobe", "autodesk", "atlassian", "apache", "ibm", "oracle", "google", "amazon", "intuit", "sap"}
# Parts too vague to be a skill on their own.
_TOO_GENERIC = {"suite", "management", "preparation", "documentation", "maintenance", "control", "planning", "compliance",
                "supervision", "systems", "principles", "practice", "practices", "skills", "knowledge", "work",
                "evaluation", "coordination", "administration"}


# Common abbreviations: a resume may write either form.
ACRONYMS = {
    "ai": "artificial intelligence", "ml": "machine learning", "nlp": "natural language processing",
    "bi": "business intelligence", "cv": "computer vision", "ui": "user interface", "ux": "user experience",
    "qa": "quality assurance", "hr": "human resources", "crm": "customer relationship management",
    "erp": "enterprise resource planning", "seo": "search engine optimization", "sem": "search engine marketing",
    "ppc": "pay per click", "kpi": "key performance indicators", "api": "application programming interface",
    "oop": "object oriented programming", "gis": "geographic information system", "bim": "building information modelling",
    "aws": "amazon web services", "gcp": "google cloud platform", "iot": "internet of things",
    "llm": "large language models", "genai": "generative ai", "hse": "health safety and environment",
    "osh": "occupational safety and health", "sop": "standard operating procedures", "pos": "point of sale",
    "smm": "social media marketing", "dbms": "database management system", "etl": "extract transform load",
}
_FULL_TO_ACRONYM = {v: k for k, v in ACRONYMS.items()}

# Wordings that show the same skill (a job ad's term -> other ways a resume may show it).
RELATED_TERMS = {
    "data analysis": ["data analytics", "analysing data", "analyzing data", "data analyst"],
    "data analytics": ["data analysis", "analysing data", "analyzing data"],
    "data visualization": ["data visualisation", "dashboards", "dashboard", "tableau", "power bi", "microsoft bi",
                           "looker", "data studio"],
    "business intelligence": ["power bi", "microsoft bi", "tableau", "qlik", "looker"],
    "administrative support": ["administration", "administrative", "secretarial", "clerical", "clerkship",
                               "office administration", "admin"],
    "calendar": ["scheduling", "calendar management", "appointments", "diary management"],
    "scheduling": ["calendar management", "appointments", "diary management"],
    "correspondence": ["letters", "emails", "memos", "minutes of meeting"],
    "machine learning algorithms": ["machine learning", "deep learning"],
    "statistics": ["statistical analysis", "statistical models", "statistical modelling", "statistical modeling"],
    "customer service": ["customer support", "client service"],
    "project management": ["managed projects", "project manager", "project planning"],
    "web development": ["website development", "web application", "web applications", "websites", "website",
                        "built website", "web developer", "front-end development", "backend development"],
    "computer vision": ["image recognition", "image processing", "object detection", "image classification",
                        "opencv"],
}

# Job-ad words that are not real skills.
_NOT_A_SKILL = {"developers", "developer", "insights", "analyze", "analyse", "analytical", "analysis skills", "implementation", "recommendations",
                "methodologies", "methodology", "programming", "coding", "frameworks", "framework", "guidance",
                "deadlines", "equity", "solutions", "detail oriented", "attention to detail", "self motivated",
                "fast paced", "multitasking", "hands on", "best practices", "excellent", "strong", "ability",
                "meetings", "execution", "deliverables", "efficiency", "business needs", "scalable", "scalability",
                "programming languages", "computer science", "stakeholders", "requirements", "operations", "growth",
                "performance", "quality", "innovation", "strategy", "planning", "results", "support", "teamwork",
                # benefits, working conditions and personal traits copied from job ads
                "paid time off", "401k", "life insurance", "health insurance", "dental", "vision", "benefits", "bonus",
                "work environment", "onsite", "on site", "remote", "hybrid", "part time", "full time", "flexibility",
                "flexible", "organized", "organised", "work independently", "independently", "excellence", "objectives",
                "email", "phone", "word", "power", "methods", "resource", "resources", "assessments", "controls",
                "coordination", "communications", "travel", "overtime", "shifts", "weekends", "salary",
                "affirmative action", "equal employment opportunity", "eeo", "responsibility", "responsibilities",
                "work experience", "collaborative", "ms", "initiative", "written communication", "network", "industrial software",
                "respect", "compassion", "empathy", "integrity", "honesty", "background checks", "background check",
                "drug test", "drug screening"}
_NOT_A_SKILL_PATTERN = re.compile(
    r"\b(degree|bachelor'?s?|master'?s?|ph\s?d|doctorate|diploma|spm|stpm|years? of experience|"
    r"\d+\+?\s*years?|fresh graduates?|driving licen[cs]e|own transport)\b")


def is_requirement(name: str) -> bool:
    """False for job-ad words that are not skills (e.g. "Insights", "Master's Degree", "3+ Years of Experience")."""
    key = skill_key(name)
    return bool(key) and key not in _NOT_A_SKILL and not _NOT_A_SKILL_PATTERN.search(key)


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
    # Acronym at the end of a name, e.g. "Amazon Web Services AWS" -> "aws"
    for word in re.findall(r"\b[A-Z][A-Z0-9+#]{1,5}\b", str(name)):
        aliases.add(word.lower())
    # Split names that hold a list, like "AGM / EGM"
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
    for a in list(aliases):
        aliases.update(RELATED_TERMS.get(a, []))
    # Short and full names (AI = Artificial Intelligence), UK and US spelling.
    for a in list(aliases):
        if a in ACRONYMS:
            aliases.add(ACRONYMS[a])
        if a in _FULL_TO_ACRONYM:
            aliases.add(_FULL_TO_ACRONYM[a])
        words = a.split()
        if len(words[-1]) > 4 and words[-1].endswith("s") and not words[-1].endswith("ss"):
            aliases.add(" ".join(words[:-1] + [words[-1][:-1]]))  # "business processes" -> "business processe"/"process"
            if words[-1].endswith("es"):
                aliases.add(" ".join(words[:-1] + [words[-1][:-2]]))
        if "isation" in a or "ization" in a:
            aliases |= {a.replace("isation", "ization"), a.replace("ization", "isation")}
    return {a for a in aliases if len(a) > 1 and a not in _TOO_GENERIC}


def text_ngrams(text: str, max_n: int = 4) -> set[str]:
    """All 1- to 4-word phrases in a text, normalised like skill keys."""
    tokens = _TOKEN.findall(str(text).lower())
    return {" ".join(tokens[i:i + n]) for n in range(1, max_n + 1) for i in range(len(tokens) - n + 1)}
