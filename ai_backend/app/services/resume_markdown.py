"""Normalized Markdown for a resume and a copy without personal details."""

import re

SECTION_WORDS = (
    "summary", "profile", "objective", "about me", "experience", "employment", "work history", "career history",
    "education", "qualification", "skills", "expertise", "competenc", "certification", "licen", "training",
    "courses", "projects", "achievements", "awards", "languages", "interests", "hobbies", "activities",
    "volunteer", "references", "referees", "publications", "personal details", "personal information",
    "personal particulars", "personal data", "personal profile", "contact", "miscellaneous", "additional", "details",
    "internship", "strengths", "specialisms", "career history",
)
_BULLET = re.compile(r"^\s*(?:[•·▪◦►✓✔➢➤\-–*]|o(?=\s))\s*")
_EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_URL = re.compile(r"https?://\S+|www\.\S+|\b(?:linkedin|github|behance|facebook|instagram)(?:\.com)?/\S+", re.IGNORECASE)
_PHONE = re.compile(r"(?<![\w/])\+?\(?\d[\d ().-]{6,}\d(?![\w/])")
_YEAR_RANGE = re.compile(r"^(?:19|20)\d{2}\s*[-–]\s*(?:19|20)\d{2}$")
_ID = re.compile(r"\b\d{6}-?\d{2}-?\d{4}\b|\b[STFGM]\d{7}[A-Z]\b")  # MyKad, Singapore NRIC/FIN
_PERSONAL = re.compile(
    r"^\s*(?:date of birth|d\.o\.b|dob|birth ?date|age|gender|sex|religion|race|ethnicity|marital status|"
    r"nationality|citizenship|ic no|i/c|nric|passport|address|alamat|phone|mobile|tel|email|e-mail)\b",
    re.IGNORECASE)
_ADDRESS = re.compile(
    r"\b(?:jalan|jln|lorong|taman|persiaran|lebuh|lebuhraya|blk|block|street|st\.|road|rd\.|avenue|ave\.|"
    r"apartment|condominium|kondominium|no\.\s*\d)\b|\b\d{5}\b.*\b(?:johor|kedah|kelantan|melaka|malacca|"
    r"negeri sembilan|pahang|penang|pulau pinang|perak|perlis|sabah|sarawak|selangor|terengganu|kuala lumpur|"
    r"putrajaya|labuan)\b|\bsingapore\s*\d{6}\b", re.IGNORECASE)
_CREDENTIALS = re.compile(r",?\s*\b(?:CA|CFA|CPA|ACCA|CIMA|CMA|MBA|PhD|Ph\.D|PE|Ir|Ts|Dr|Prof)\b\.?", re.IGNORECASE)
_NAME_LINE = re.compile(r"^[A-Za-z][A-Za-z'.\-]*(?:\s+[A-Za-z][A-Za-z'.\-]*){0,4}$")
_JOB_WORDS = re.compile(r"\b(engineer|manager|developer|executive|analyst|officer|assistant|designer|consultant|"
                        r"specialist|accountant|nurse|teacher|lecturer|intern|student|graduate|director|clerk|"
                        r"technician|scientist|architect|supervisor|coordinator|representative|curriculum vitae|resume)\b",
                        re.IGNORECASE)


_SMALL_WORDS = {"of", "and", "&", "the", "in", "for", "to", "/"}


def is_heading(line: str) -> bool:
    """A section title such as "WORK EXPERIENCE" or "Key Skills" (not a sentence that mentions experience)."""
    s = line.strip().rstrip(":").strip()
    if not s or len(s) > 40 or _BULLET.match(line) or any(ch.isdigit() for ch in s) or s[-1] in ".,;":
        return False
    words = s.split()
    if len(words) > 4:
        return False
    title_like = s.isupper() or all(w[0].isupper() or w.lower() in _SMALL_WORDS for w in words)
    # "PERSONAL ASSISTANT" or "TRAINING MANAGER" is a job title, not a section.
    low = s.lower()
    clear_section = any(w in low for w in ("summary", "experience", "education", "skills", "objective", "references",
                                            "employment", "qualifications", "certifications", "languages"))
    return title_like and any(w in low for w in SECTION_WORDS) and (clear_section or not _JOB_WORDS.search(s))


_DECORATION = "。○◦●•·*|ㅡ—_"
_INVISIBLE = re.compile("[\u200b-\u200f\u2060\ufeff\u00ad]")  # zero-width spaces and marks from Google Docs/Word
_OCR_AI = re.compile(r"\bAl\b(?![-'’])")  # OCR reads "AI" as "Al" (lowercase L)


def _clean_ocr(text: str) -> str:
    """Fix common OCR mistakes."""
    out: list[str] = []
    for line in _INVISIBLE.sub("", text).split("\n"):
        s = line.strip()
        bare = s.strip(_DECORATION + " ")
        if s and bare != s and is_heading(bare):
            s = bare  # "。DETAILS。" -> "DETAILS"
        if s in ("o", "O", "0") or (s and not s.strip(_DECORATION + " ")):
            continue  # a bullet or decoration read as its own line
        s = _OCR_AI.sub("AI", s)
        if re.fullmatch(r"\([^()]{1,20}\)", s) and out and out[-1].strip():
            out[-1] = f"{out[-1].rstrip()} {s}"  # "Natural Language Processing" + "(NLP)"
            continue
        out.append(s)
    return "\n".join(out)


def to_markdown(text: str) -> str:
    out = []
    for line in _clean_ocr(text).split("\n"):
        s = line.strip()
        if not s:
            if out and out[-1] != "":
                out.append("")
        elif is_heading(s):
            out += ["", f"## {s.strip(':').title() if s.isupper() else s.strip(':')}"]
        elif _BULLET.match(s):
            out.append("- " + _BULLET.sub("", s))
        else:
            out.append(s)
    return re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip() + "\n"


def _is_phone(match: str) -> bool:
    digits = re.sub(r"\D", "", match)
    return 8 <= len(digits) <= 15 and not _YEAR_RANGE.match(match.strip())


_PERSONAL_SECTIONS = ("reference", "referee", "personal details", "personal information", "personal particulars",
                      "personal data", "contact")
# Where someone lives, written as "City, State" or "City, Country" in the resume header.
_LOCATION = re.compile(r"^[A-Z][A-Za-z.' ]{1,25},\s*[A-Z][A-Za-z.' ]{1,25}$")


def _is_personal_section(heading: str) -> bool:
    h = heading.strip().lower()
    return h in ("details", "info", "my details") or any(w in h for w in _PERSONAL_SECTIONS)


def without_personal_details(markdown: str) -> str:
    lines = markdown.split("\n")
    # Name line: one of the first two lines, 1-3 capital words, not a job title.
    top = [i for i, l in enumerate(lines) if l.strip()][:2]
    def looks_like_name(line: str) -> bool:
        bare = _CREDENTIALS.sub("", line).strip(" ,")  # "JOHN SIM, CA" -> "JOHN SIM"
        return (bool(bare) and bool(_NAME_LINE.match(bare)) and len(bare.split()) <= 3
                and all(w[0].isupper() for w in bare.split()) and not _JOB_WORDS.search(bare))

    name_lines = {i for i in top if looks_like_name(lines[i].strip())}
    # Lines before the first real section (the header) may hold the home city.
    first_section = next((i for i, l in enumerate(lines) if l.startswith("## ") and not _is_personal_section(l[3:])),
                         len(lines))
    out, in_references = [], False
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith("## "):
            in_references = _is_personal_section(s[3:])
            if in_references:
                continue
        if in_references:
            continue
        if _EMAIL.search(s) or _URL.search(s) or _ID.search(s) or _PERSONAL.match(s) or _ADDRESS.search(s):
            continue
        if any(_is_phone(m.group()) for m in _PHONE.finditer(s)):
            continue
        if i in name_lines:
            continue
        if i < first_section and _LOCATION.match(s) and not _JOB_WORDS.search(s):
            continue
        out.append(line)
    return re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip() + "\n"
