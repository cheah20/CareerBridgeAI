"""Remove personal details from resume text before it is sent to an external LLM.

Requirements §17: do not send or log unnecessary resume content. Skills and
work history are kept (needed for advice); contact details and identifiers are not.
"""

import re

_EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_URL = re.compile(r"(?:https?://|www\.)\S+|\b(?:linkedin\.com|github\.com)/\S+", re.IGNORECASE)
_PHONE = re.compile(r"(?<!\d)(?:\+?6?0|\+65)?[\s-]?\(?\d{1,3}\)?[\s-]?\d{3,4}[\s-]?\d{3,4}(?!\d)")
_NRIC = re.compile(r"\b\d{6}-?\d{2}-?\d{4}\b")                    # Malaysian MyKad
_SG_ID = re.compile(r"\b[STFGM]\d{7}[A-Z]\b")                       # Singapore NRIC / FIN
_ADDRESS_LINE = re.compile(
    r"^.*\b(jalan|jln|lorong|taman|persiaran|lebuh|blk|block|street|road|avenue)\b.*$|^.*\b\d{5,6}\b.*\b("
    r"johor|kedah|kelantan|melaka|malacca|negeri sembilan|pahang|penang|pulau pinang|perak|perlis|sabah|sarawak|"
    r"selangor|terengganu|kuala lumpur|putrajaya|labuan|singapore)\b.*$",
    re.IGNORECASE | re.MULTILINE,
)
_PERSONAL_LINE = re.compile(r"^\s*(date of birth|dob|age|gender|religion|race|marital status|nationality|ic no|nric)\b.*$",
                            re.IGNORECASE | re.MULTILINE)


def redact_personal_info(text: str, known_names: list[str] | None = None) -> str:
    text = _EMAIL.sub("[EMAIL]", text)
    text = _URL.sub("[LINK]", text)
    text = _NRIC.sub("[ID]", text)
    text = _SG_ID.sub("[ID]", text)
    text = _PHONE.sub("[PHONE]", text)
    text = _ADDRESS_LINE.sub("[ADDRESS]", text)
    text = _PERSONAL_LINE.sub("[PERSONAL DETAIL]", text)
    for name in known_names or []:
        if name.strip():
            text = re.sub(re.escape(name.strip()), "[NAME]", text, flags=re.IGNORECASE)
    # Resumes usually start with the person's name.
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if line.strip():
            if re.fullmatch(r"[A-Za-z][A-Za-z'.@-]*(?:\s+[A-Za-z][A-Za-z'.@-]*){0,4}", line.strip()) and len(line.split()) >= 2:
                lines[i] = "[NAME]"
            break
    return "\n".join(lines)
