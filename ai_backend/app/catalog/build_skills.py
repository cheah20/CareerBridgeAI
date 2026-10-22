"""Step 1b: skills for every role and experience level."""

import json
import re
from collections import Counter, defaultdict
from datetime import date

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer

from app.catalog.build_roles import ESCO, ONET, OUT, RAW, _norm, dedupe_ads
from app.catalog.skillnames import TOKEN, skill_key

LEVELS = ("entry", "junior", "mid", "senior", "lead")
LEVEL_NAMES = {
    "entry": "Internship / Fresh Graduate",
    "junior": "Junior (1–2 years)",
    "mid": "Mid-level (3–5 years)",
    "senior": "Senior (6–9 years)",
    "lead": "Lead / Manager (10+ years)",
}
LINKEDIN_LEVEL = {
    "Internship": "entry", "Entry level": "entry", "Associate": "junior",
    "Mid-Senior level": "mid", "Director": "lead", "Executive": "lead",
}
DS_LEVEL = {"Associate": "junior", "Mid senior": "mid"}
TITLE_LEVEL = [  # checked in order; title words beat the posting's own label
    ("entry", r"\b(intern|internship|trainee|graduate|fresh)\b"),
    ("lead", r"\b(lead|principal|head|director|chief|vp)\b"),  # not "staff": Staff Nurse is not senior
    ("senior", r"\b(senior|sr)\b"),
    ("junior", r"\b(junior|jr|associate)\b"),
]

MIN_SHARE = 0.10          # a market skill must appear in >=10% of a role's postings
CORE_SHARE = 0.25         # >=25% = core market skill
MIN_POSTINGS_FOR_LEVEL = 15
GENERIC_ROLE_SHARE = 0.25  # in this share of roles' ads at >=15% -> a generic ad word, not a skill

# Words common in job ads that are not skills (benefits, hiring language, filler).
STOP = {
    "experience", "benefits", "disability", "diversity", "inclusion", "hybrid", "remote", "passion", "requirements",
    "solutions", "services", "service", "support", "build", "data", "learning", "models", "knowledge", "science",
    "access", "staffing", "flexible", "bonus", "resources", "impact", "trends", "performance", "quality", "health",
    "business", "management", "customers", "customer", "technical", "financial", "strategies", "strategy", "leading",
    "organization", "engineering", "design", "project", "projects", "construction", "medical", "healthcare",
    "education", "integration", "documentation", "best practices", "privacy", "computer software", "software",
    "industry", "insurance", "salary", "pay", "veteran", "gender", "equal opportunity", "employment", "travel",
    "opportunity", "growth", "culture", "career", "team", "work", "skills", "ability", "development", "operations",
    "planning", "research", "analysis", "reporting", "sales", "marketing", "finance", "legal", "security", "safety",
    "training", "products", "product", "program", "process", "systems", "system", "technology", "tools", "office",
    # US job-ad benefit and filler words
    "vision", "dental", "401", "benefits package", "accommodation", "technologies", "processing", "techniques",
    "related field", "degree in computer science", "motivated", "discipline", "commercial", "innovation",
    "consistency", "direction", "designing", "feedback", "tracking", "languages", "concepts", "platforms", "media",
    "production", "safe", "accuracy", "transactions", "payments", "invoices", "environmental", "specifications",
    "drawings", "calculations", "storm", "contractors", "permitting", "civil", "recognition", "pipelines", "test",
    "engagement", "policy", "administration", "certifications", "licensure", "supervision", "treatment", "assessment",
    "act", "guidelines", "evaluation", "monitoring",
}
# Soft skills are real skills: kept in their own group instead of being filtered out.
SOFT_SKILLS = {
    "communication", "communication skills", "teamwork", "collaboration", "leadership", "problem solving",
    "problem solving skills", "time management", "critical thinking", "attention to detail", "interpersonal skills",
    "customer service", "presentation skills", "presentations", "negotiation", "adaptability", "creativity",
    "analytical skills", "organizational skills", "multitasking", "decision making", "mentoring", "coaching",
}


# ------------------------------------------------------------------ vocabulary

def build_vocabulary(ds_skills: pd.Series, onet_software: pd.DataFrame, esco_skills: pd.DataFrame,
                     role_names: set[str]) -> dict[str, str]:
    """skill key -> display name."""
    names: dict[str, Counter] = defaultdict(Counter)
    ds_counts = Counter(s.strip() for row in ds_skills.dropna() for s in row.split(","))
    for name, n in ds_counts.items():
        if n >= 5:
            names[skill_key(name)][name] += n
    for name in onet_software["Workplace Example"].unique():
        names[skill_key(name)][re.sub(r"\s+software$", "", name)] += 1
    for name in esco_skills["preferredLabel"]:
        if len(name.split()) <= 3:
            names[skill_key(name)][name] += 1
    return {k: c.most_common(1)[0][0].rstrip(":").strip() for k, c in names.items()
            if len(k) > 1 and 1 <= len(k.split()) <= 4 and k not in STOP and k not in role_names and not k.endswith(":")}


# ------------------------------------------------------------------ postings

def level_of(title: str, label: str | None, mapping: dict) -> str:
    t = str(title).lower()
    for level, pattern in TITLE_LEVEL:
        if re.search(pattern, t):
            return level
    return mapping.get(label, "mid") if label else "mid"


def role_patterns(roles: list[dict]) -> list[re.Pattern]:
    return [re.compile(r"\b(?:" + "|".join(re.escape(_norm(n)) for n in r["ad_names"]) + r")\b") for r in roles]


def market_skills(roles: list[dict], vocab: dict[str, str]) -> dict[int, dict]:
    """Per role index: {'n': {level: count}, 'skills': {key: {level: count}}}."""
    stats = {i: {"n": Counter(), "skills": defaultdict(Counter)} for i in range(len(roles))}
    patterns = role_patterns(roles)

    # LinkedIn: find vocabulary skills inside title + description.
    li = pd.read_csv(RAW / "linkedin-job-postings-2023-24" / "postings.csv",
                     usecols=["company_name", "title", "description", "skills_desc", "formatted_experience_level"])
    li = dedupe_ads(li).reset_index(drop=True)
    li["title_n"] = li["title"].map(_norm)
    li["roles"] = li["title_n"].map(lambda t: [i for i, p in enumerate(patterns) if p.search(t)])
    li = li[li["roles"].map(bool)].reset_index(drop=True)
    texts = (li["title"].fillna("") + " " + li["description"].fillna("") + " " + li["skills_desc"].fillna("")).map(
        lambda s: " ".join(re.findall(TOKEN, s.lower())))
    vectorizer = CountVectorizer(vocabulary=sorted(vocab), token_pattern=TOKEN, ngram_range=(1, 4), binary=True, lowercase=False)
    matrix = vectorizer.transform(texts).tocsr()
    keys = np.array(vectorizer.get_feature_names_out())
    for row, (title, label, role_ids) in enumerate(li[["title", "formatted_experience_level", "roles"]].itertuples(index=False)):
        level = level_of(title, label, LINKEDIN_LEVEL)
        found = keys[matrix[row].indices]
        for i in role_ids:
            stats[i]["n"][level] += 1
            for k in found:
                stats[i]["skills"][k][level] += 1
    print(f"  LinkedIn: {len(li):,} postings matched to roles")

    # Data/AI postings: skills are already listed per posting.
    jp = pd.read_csv(RAW / "ds-job-postings-skills-2024" / "job_postings.csv", usecols=["job_link", "job_title", "job_level"])
    js = pd.read_csv(RAW / "ds-job-postings-skills-2024" / "job_skills.csv")
    ds = jp.merge(js, on="job_link")
    ds["roles"] = ds["job_title"].map(_norm).map(lambda t: [i for i, p in enumerate(patterns) if p.search(t)])
    ds = ds[ds["roles"].map(bool)]
    for title, label, skills, role_ids in ds[["job_title", "job_level", "job_skills", "roles"]].itertuples(index=False):
        level = level_of(title, label, DS_LEVEL)
        found = {skill_key(s) for s in str(skills).split(",")} & vocab.keys()
        for i in role_ids:
            stats[i]["n"][level] += 1
            for k in found:
                stats[i]["skills"][k][level] += 1
    print(f"  Data/AI: {len(ds):,} postings matched to roles")
    return stats


# ------------------------------------------------------------------ build

def main() -> None:
    roles = json.loads((OUT / "roles_map.json").read_text(encoding="utf-8"))["roles"]

    occ = pd.read_csv(ONET / "Occupation Data.txt", sep="\t").set_index("O*NET-SOC Code")
    software = pd.read_csv(ONET / "Software Skills.txt", sep="\t")
    abilities = pd.read_csv(ONET / "Essential Skills.txt", sep="\t")
    abilities = abilities[(abilities["Scale ID"] == "IM") & (abilities["Recommend Suppress"] != "Y")]
    esco_rel = pd.read_csv(ESCO / "occupationSkillRelations_en.csv")
    esco_skills = pd.read_csv(ESCO / "skills_en.csv", usecols=["conceptUri", "preferredLabel", "skillType"])
    ds_skills = pd.read_csv(RAW / "ds-job-postings-skills-2024" / "job_skills.csv")["job_skills"]

    print("Building skill vocabulary …")
    role_names = {skill_key(n) for r in roles for n in [r["title"], *r["aka"]]} | {"rn", "lpn", "cna"}
    vocab = build_vocabulary(ds_skills, software, esco_skills, role_names)
    print(f"  {len(vocab):,} skill names")
    print("Counting skills in job postings …")
    stats = market_skills(roles, vocab)

    # Words found in most roles' ads are ad wording, not skills (soft skills are kept).
    big_roles = [i for i in stats if sum(stats[i]["n"].values()) >= 30]
    common_in = Counter()
    for i in big_roles:
        n = sum(stats[i]["n"].values())
        for key, by_level in stats[i]["skills"].items():
            if sum(by_level.values()) / n >= 0.15:
                common_in[key] += 1
    tool_keys = {skill_key(x) for x in software["Workplace Example"]} | {"excel", "microsoft office"}
    generic = {k for k, c in common_in.items() if c >= GENERIC_ROLE_SHARE * len(big_roles)} - SOFT_SKILLS - tool_keys
    print(f"  generic ad words removed: {sorted(vocab[k] for k in generic)[:40]}")

    out_roles = []
    for i, role in enumerate(roles):
        codes = [o["code"] for o in role["onet"]]
        n_by_level = stats[i]["n"]
        n_total = sum(n_by_level.values())

        # Market skills: share of this role's postings mentioning the skill.
        market, soft = [], []
        for key, by_level in stats[i]["skills"].items():
            share = sum(by_level.values()) / n_total if n_total else 0
            if key in generic or share < MIN_SHARE or n_total < 10:
                continue
            (soft if key in SOFT_SKILLS else market).append({
                    "name": vocab[key],
                    "share": round(share, 3),
                    "by_level": {lv: round(by_level[lv] / n_by_level[lv], 3)
                                 for lv in LEVELS if n_by_level[lv] >= MIN_POSTINGS_FOR_LEVEL},
                })
        market.sort(key=lambda s: -s["share"])
        soft.sort(key=lambda s: -s["share"])
        market_keys = {skill_key(m["name"]) for m in market}

        sw = software[software["O*NET-SOC Code"].isin(codes)]
        sw = sw.assign(score=(sw["In Demand"] == "Y") * 2 + (sw["Hot Technology"] == "Y"))
        # Keep tools that are in demand, or that this role's real ads actually mention.
        sw = sw[(sw["In Demand"] == "Y") | sw["Workplace Example"].map(skill_key).isin(market_keys)]
        tools = (sw[sw["score"] > 0].sort_values("score", ascending=False)
                 .drop_duplicates("Workplace Example")["Workplace Example"].str.replace(r"\s+software$", "", regex=True)
                 .head(20).tolist())

        ab = abilities[abilities["O*NET-SOC Code"].isin(codes)].groupby("Element Name")["Data Value"].mean()
        core_abilities = [name for name, v in ab.sort_values(ascending=False).items() if v >= 3.5][:8]

        esco = {"essential": [], "optional": []}
        if role["esco"]:
            rel = esco_rel[esco_rel["occupationUri"] == role["esco"]["uri"]]
            for kind in esco:
                esco[kind] = rel[rel["relationType"] == kind]["skillLabel"].tolist()

        out_roles.append({
            "id": _slug(role["title"]),
            "field": role["field"],
            "title": role["title"],
            "aka": role["aka"],
            "emerging": role["emerging"],
            "description": occ.loc[codes[0], "Description"] if codes and codes[0] in occ.index else "",
            "sources": {"onet": role["onet"], "esco": role["esco"], "matched_by": role["matched_by"]},
            "postings": {"total": n_total, "by_level": {lv: n_by_level[lv] for lv in LEVELS}},
            "skills": {
                "market_core": [s for s in market if s["share"] >= CORE_SHARE][:25],
                "market_common": [s for s in market if s["share"] < CORE_SHARE][:25],
                "soft": soft[:10],
                "tools": tools,
                "essential": esco["essential"][:30],
                "optional": esco["optional"][:25],
                "core_abilities": core_abilities,
                "llm_drafted": _load_draft(_slug(role["title"])),
            },
        })

    (OUT / "roles.json").write_text(json.dumps(
        {"generated": date.today().isoformat(), "levels": LEVEL_NAMES, "roles": out_roles}, indent=2), encoding="utf-8")
    for r in out_roles:
        path = OUT / "roles" / _slug(r["field"]) / f"{r['id']}.md"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(_role_md(r), encoding="utf-8")
    (OUT / "README.md").write_text(_index_md(out_roles), encoding="utf-8")

    thin = [r["title"] for r in out_roles if r["postings"]["total"] < 20]
    print(f"Wrote {len(out_roles)} role profiles to {OUT / 'roles'}")
    print(f"Roles with fewer than 20 postings (skills rely on ESCO/O*NET): {len(thin)} → {thin}")


def _load_draft(role_id: str) -> list[dict]:
    """Skills drafted by the LLM for roles with few job ads."""
    path = OUT / "llm_drafts" / f"{role_id}.json"
    if not path.exists():
        return []
    draft = json.loads(path.read_text(encoding="utf-8"))
    return [{"name": x["name"], "weight": round(float(x.get("importance", 0.3)), 2), "type": x.get("type", "hard")}
            for x in draft.get("skills", []) if x.get("type") != "soft" and x.get("name")]


def _slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower().replace("&", "and")).strip("-")


def _role_md(r: dict) -> str:
    s = r["skills"]
    lines = [f"# {r['title']}", ""]
    lines += [f"- **Field:** {r['field']}"]
    if r["aka"]:
        lines += [f"- **Also called:** {', '.join(r['aka'])}"]
    if r["emerging"]:
        lines += ["- **Emerging role** (fast-growing in 2025–2026)"]
    onet = "; ".join(f"{o['code']} {o['title']}" for o in r["sources"]["onet"]) or "—"
    esco = r["sources"]["esco"]["label"] if r["sources"]["esco"] else "—"
    lines += [f"- **O*NET:** {onet}", f"- **ESCO:** {esco}",
              f"- **Job ads analysed:** {r['postings']['total']:,} "
              f"({', '.join(f'{LEVEL_NAMES[lv].split(' (')[0]} {n}' for lv, n in r['postings']['by_level'].items() if n)})", ""]
    if r["description"]:
        lines += ["## What the job involves", "", r["description"], ""]

    if s["market_core"] or s["market_common"]:
        lines += ["## Skills employers ask for", "",
                  "Share of job ads for this role that mention the skill, overall and by experience level.", ""]
        shown_levels = [lv for lv in LEVELS if any(lv in x["by_level"] for x in s["market_core"] + s["market_common"])]
        header = "| Skill | All ads | " + " | ".join(LEVEL_NAMES[lv].split(" (")[0] for lv in shown_levels) + " |"
        lines += [header, "|---|---|" + "---|" * len(shown_levels)]
        for x in s["market_core"] + s["market_common"]:
            cells = " | ".join(f"{x['by_level'][lv]:.0%}" if lv in x["by_level"] else "–" for lv in shown_levels)
            core = " **(core)**" if x in s["market_core"] else ""
            lines.append(f"| {x['name']}{core} | {x['share']:.0%} | {cells} |")
        lines.append("")
    if s["soft"]:
        lines += ["## Soft skills employers mention", "",
                  ", ".join(f"{x['name']} ({x['share']:.0%})" for x in s["soft"]), ""]
    if s["llm_drafted"]:
        lines += ["## Malaysia / Singapore skills (AI-drafted, pending human review)", "",
                  "Drafted by DeepSeek because few job ads matched this title. Estimated share of job ads in brackets.", ""]
        lines += [f"- {x['name']} ({x['weight']:.0%}, {x['type']})" for x in s["llm_drafted"]] + [""]
    if s["tools"]:
        lines += ["## Tools and technologies (O*NET in-demand, or seen in this role's ads)", "", ", ".join(s["tools"]), ""]
    if s["essential"]:
        lines += ["## Essential skills (ESCO)", ""] + [f"- {x}" for x in s["essential"]] + [""]
    if s["optional"]:
        lines += ["## Optional skills (ESCO)", ""] + [f"- {x}" for x in s["optional"]] + [""]
    if s["core_abilities"]:
        lines += ["## Core abilities (O*NET importance ≥ 3.5 of 5)", "", ", ".join(s["core_abilities"]), ""]
    if r["postings"]["total"] < 20:
        lines += ["> **Limited market data:** fewer than 20 job ads matched this title, so skills rely mainly on ESCO and O*NET.", ""]
    lines += ["---", "Sources: O*NET 31.0 (USDOL/ETA, CC BY 4.0); ESCO v1.2.1 (European Commission); "
              "LinkedIn Job Postings 2023–24 (CC BY-SA 4.0); Data Science Job Postings & Skills 2024 (ODC-By)."]
    return "\n".join(lines) + "\n"


def _index_md(roles: list[dict]) -> str:
    lines = ["# CareerBridge role catalogue", "",
             f"Generated {date.today().isoformat()} · {len(roles)} roles · ★ emerging (2025–2026)", ""]
    for field_name in dict.fromkeys(r["field"] for r in roles):
        lines += [f"## {field_name}", "", "| Role | Job ads | Core market skills |", "|---|---|---|"]
        for r in (x for x in roles if x["field"] == field_name):
            core = ", ".join(x["name"] for x in r["skills"]["market_core"][:6]) or "—"
            star = " ★" if r["emerging"] else ""
            lines.append(f"| [{r['title']}](roles/{_slug(field_name)}/{r['id']}.md){star} | {r['postings']['total']:,} | {core} |")
        lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    main()
