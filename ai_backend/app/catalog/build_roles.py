"""Step 1a: match every seed role to O*NET, ESCO and real job postings."""

import json
import re
from collections import Counter
from datetime import date

import pandas as pd

from app.catalog.seed import FIELDS
from app.ml.catalog import DATA_DIR

RAW = DATA_DIR / "raw"
OUT = DATA_DIR / "catalog"
ONET = RAW / "onet-31.0" / "db_31_0_text"
ESCO = RAW / "esco-1.2.1"

LEVELS = {  # LinkedIn experience level -> CareerBridge level
    "Internship": "entry",
    "Entry level": "entry",
    "Associate": "junior",
    "Mid-Senior level": "mid/senior",
    "Director": "lead",
    "Executive": "lead",
}


def _norm(text: str) -> str:
    return re.sub(r"\s+", " ", str(text).lower().replace("–", "-")).strip()


def _variants(title: str) -> list[str]:
    """'AI Engineer (Artificial Intelligence Engineer)' -> both names."""
    inner = re.findall(r"\(([^)]+)\)", title)
    outer = re.sub(r"\s*\([^)]*\)", "", title)
    return [_norm(v) for v in [outer, *inner] if v.strip()]


def _words(text: str) -> set[str]:
    return {w.rstrip("s") for w in re.findall(r"[a-z]+", text.lower()) if len(w) > 2}


def _similarity(a: str, b: str) -> float:
    wa, wb = _words(a), _words(b)
    return len(wa & wb) / len(wa | wb) if wa and wb else 0.0


def load_onet() -> tuple[dict[str, Counter], dict[str, str]]:
    """Job title -> Counter of O*NET codes (how many title records point to each)."""
    occ = pd.read_csv(ONET / "Occupation Data.txt", sep="\t")
    titles = pd.read_csv(ONET / "Job Titles.txt", sep="\t")
    reported = pd.read_csv(ONET / "Sample of Reported Titles.txt", sep="\t")
    by_title: dict[str, Counter] = {}
    for code, title in pd.concat([
        occ[["O*NET-SOC Code", "Title"]].rename(columns={"Title": "t"}),
        titles[["O*NET-SOC Code", "Job Title"]].rename(columns={"Job Title": "t"}),
        reported[["O*NET-SOC Code", "Reported Job Title"]].rename(columns={"Reported Job Title": "t"}),
    ]).itertuples(index=False):
        for v in _variants(title):
            by_title.setdefault(v, Counter())[code] += 1
    names = dict(zip(occ["O*NET-SOC Code"], occ["Title"]))
    return by_title, names


def pick_onet(names: list[str], by_title: dict[str, Counter], onet_names: dict[str, str]) -> list[str]:
    """Rank candidate codes: title matches first, then similarity of the occupation name to the role."""
    votes = Counter()
    for n in names:
        votes.update(by_title.get(_norm(n), Counter()))
    return sorted(votes, key=lambda c: (-votes[c], -max(_similarity(n, onet_names.get(c, "")) for n in names)))


def load_esco() -> tuple[dict[str, tuple[str, str]], dict[str, tuple[str, str]]]:
    """(preferred label -> occupation, alternative label -> occupation)."""
    occ = pd.read_csv(ESCO / "occupations_en.csv")
    preferred, alternative = {}, {}
    for uri, pref, alts in occ[["conceptUri", "preferredLabel", "altLabels"]].itertuples(index=False):
        preferred.setdefault(_norm(pref), (uri, pref))
        for label in str(alts if isinstance(alts, str) else "").split("\n"):
            if label.strip():
                alternative.setdefault(_norm(label), (uri, pref))
    return preferred, alternative


def pick_esco(names: list[str], preferred: dict, alternative: dict) -> tuple[str, str] | None:
    """Prefer an exact match on an occupation's official name over its synonyms."""
    for table in (preferred, alternative):
        for n in names:
            if _norm(n) in table:
                return table[_norm(n)]
    return None


def load_postings() -> pd.DataFrame:
    li = pd.read_csv(RAW / "linkedin-job-postings-2023-24" / "postings.csv",
                     usecols=["title", "formatted_experience_level"])
    li = li.rename(columns={"formatted_experience_level": "level"})
    ds = pd.read_csv(RAW / "ds-job-postings-skills-2024" / "job_postings.csv", usecols=["job_title"])
    ds = ds.rename(columns={"job_title": "title"}).assign(level=None)
    both = pd.concat([li, ds], ignore_index=True)
    both["title_n"] = both["title"].map(_norm)
    return both


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    onet_titles, onet_names = load_onet()
    esco_preferred, esco_alternative = load_esco()
    esco_by_uri = {v[0]: v for v in [*esco_preferred.values(), *esco_alternative.values()]}
    postings = load_postings()

    roles = []
    for f in FIELDS:
        for seed in f.roles:
            names = [seed.title, *seed.aka]
            # Manually chosen matches (seed.onet / seed.esco) win over automatic ones.
            onet_codes = list(seed.onet) or pick_onet(names, onet_titles, onet_names)
            esco = (esco_preferred.get(_norm(seed.esco)) if seed.esco else None) or pick_esco(
                names, esco_preferred, esco_alternative)

            ad_names = list(seed.ads) or names
            pattern = re.compile(r"\b(?:" + "|".join(re.escape(_norm(n)) for n in ad_names) + r")\b")
            hits = postings[postings["title_n"].str.contains(pattern, na=False)]
            levels = Counter(LEVELS.get(l, "unknown") for l in hits["level"].dropna())

            roles.append({
                "field": f.name,
                "title": seed.title,
                "aka": list(seed.aka),
                "ad_names": ad_names,
                "emerging": seed.emerging,
                "onet": [{"code": c, "title": onet_names.get(c, "")} for c in onet_codes[:3]],
                "esco": {"uri": esco[0], "label": esco[1]} if esco else None,
                "matched_by": "manual" if (seed.onet or seed.esco) else "automatic",
                "postings": int(len(hits)),
                "postings_by_level": dict(levels),
            })

    (OUT / "roles_map.json").write_text(json.dumps(
        {"generated": date.today().isoformat(), "roles": roles}, indent=2), encoding="utf-8")
    (OUT / "ROLES.md").write_text(_overview(roles), encoding="utf-8")

    unmatched = [r for r in roles if not r["onet"] and not r["esco"]]
    print(f"{len(roles)} roles in {len(FIELDS)} fields | O*NET matched {sum(bool(r['onet']) for r in roles)} | "
          f"ESCO matched {sum(bool(r['esco']) for r in roles)} | no occupation match {len(unmatched)} | "
          f"with job postings {sum(r['postings'] > 0 for r in roles)}")
    print(f"Wrote {OUT / 'ROLES.md'}")


def _overview(roles: list[dict]) -> str:
    lines = [
        "# CareerBridge role catalogue — fields and job titles",
        "",
        f"Generated {date.today().isoformat()}. ✓ = matched in that source; postings = real job ads whose title matches "
        "(LinkedIn 2023–24 + Data/AI postings 2024). ★ = emerging role (2025–2026).",
        "",
    ]
    for field_name in dict.fromkeys(r["field"] for r in roles):
        lines += [f"## {field_name}", "", "| Role | O*NET | ESCO | Job postings |", "|---|---|---|---|"]
        for r in (r for r in roles if r["field"] == field_name):
            onet = r["onet"][0]["title"] if r["onet"] else "—"
            esco = r["esco"]["label"] if r["esco"] else "—"
            star = " ★" if r["emerging"] else ""
            lines.append(f"| {r['title']}{star} | {onet} | {esco} | {r['postings']:,} |")
        lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    main()
