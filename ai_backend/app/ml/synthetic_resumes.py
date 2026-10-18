"""Generate realistic Malaysian / Singaporean resumes for training, with known answers.

Two steps per resume:
1. A random person profile is drawn in code (role from the CareerBridge catalogue, experience level,
   work history with full-time, part-time, freelance, internship and contract jobs, career gaps,
   career switches, education, skills) so the variety is real randomness, not the LLM's habits.
2. The LLM writes that profile up as resume text in one of several layouts seen in real resumes
   (the Malaysian CV sample pack, the JobStreet template, a career-guide layout, student and plain
   layouts, text copied out of a two-column PDF).

Every resume keeps its profile, so it can train the role/field/level classifier and check the parser.
The real Malaysian CVs are used only as style references and stay out of training.

Usage (from ai_backend/, env careerbridge-ai):
    python -m app.ml.synthetic_resumes generate --batch batch1 --per-role 1   # every role once
    python -m app.ml.synthetic_resumes review --batch batch1                  # HTML page to check them
Output: data/synthetic/<batch>/resumes.jsonl (local only)
"""

import argparse
import html
import json
import random
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date
from pathlib import Path

from app.llm.client import LLMUnavailable, chat_json
from app.llm.redact import redact_personal_info
from app.matching.fit import requirements_for
from app.matching.roles import load_roles
from app.ml.catalog import DATA_DIR
from app.services.resume_text import extract_text

OUT_DIR = DATA_DIR / "synthetic"
SAMPLES_DIR = DATA_DIR / "eval" / "real" / "my_cv_samples"
TODAY = date(2026, 10, 1)

LEVEL_WEIGHTS = {"entry": 20, "junior": 25, "mid": 25, "senior": 18, "lead": 12}
LEVEL_YEARS = {"entry": (0, 0), "junior": (1, 2), "mid": (3, 5), "senior": (6, 9), "lead": (10, 18)}
ETHNICITY = [("Malay", 48), ("Chinese", 30), ("Indian", 12), ("Sabahan or Sarawakian", 6), ("Eurasian or other", 4)]
MY_PLACES = ["Kuala Lumpur", "Petaling Jaya", "Shah Alam", "Subang Jaya", "Cyberjaya", "Putrajaya", "Johor Bahru",
             "Penang", "Ipoh", "Melaka", "Seremban", "Kuantan", "Kota Kinabalu", "Kuching", "Alor Setar",
             "Kota Bharu", "Kuala Terengganu", "Miri", "Klang", "Nilai"]
SG_PLACES = ["Singapore"]

STYLES = {
    "cv-pack": "Malaysian professional CV: name and target title on top, contact line, then EXECUTIVE SUMMARY "
               "(bullets), AREAS OF EXPERTISE or KEY SKILLS, TECHNICAL SKILLS, PROFESSIONAL EXPERIENCE with "
               "'Significant Achievements' sub-bullets, EDUCATION, MISCELLANEOUS INFORMATION (languages, "
               "availability), REFERENCES. Follow the style reference closely.",
    "jobstreet": "JobStreet template order: contact line, Key skills (one per line), Education, Summary "
                 "(elevator pitch), Career history with 'Role Title at Company Name', 'Month YYYY – Month YYYY', "
                 "overview, Key responsibilities, Achievements; Interests; References available upon request.",
    "career-guide": "Career-guide layout: 'Your Name - Curriculum Vitae', Personal Profile / Personal Attributes "
                    "(5-7 bullets), Experience / Specialisms, Achievements with facts and figures, Career History as "
                    "'mth/year-mth/year - job title - employer/city - industry', Personal Details (address, phone, "
                    "email, date of birth, nationality, marital status), Education and qualifications, Hobbies.",
    "student": "Fresh-graduate / student style: OBJECTIVE, EDUCATION first with CGPA and final-year project, "
               "INTERNSHIP, PART-TIME EXPERIENCE, CO-CURRICULAR ACTIVITIES (clubs, volunteering), SKILLS "
               "(software, languages with level), ACHIEVEMENTS, REFERENCES with two referees' titles.",
    "plain": "Plain resume typed in Word by the person: simple headings in Title Case (Profile, Work Experience, "
             "Education, Skills, Languages, Others), dashes or asterisks as bullets, some inconsistency in "
             "formatting and date styles.",
    "two-column": "Text as copied out of a two-column PDF: the left column (contact, skills, languages, "
                  "certifications) and the right column (summary, experience, education) are interleaved line by "
                  "line in places, headings in CAPITALS, some lines broken mid-sentence.",
}
STYLE_WEIGHTS = {"cv-pack": 25, "jobstreet": 15, "career-guide": 12, "student": 13, "plain": 20, "two-column": 15}
DATE_STYLES = ["Mar 2021 – Present", "03/2021 - 08/2023", "2021 - 2023", "March 2021 to August 2023", "Mar'21 – Aug'23"]

SYSTEM_PROMPT = """You turn a person profile into the text of a realistic resume written by a real jobseeker in
Malaysia or Singapore. The text is used to train and test a resume classifier, so it must read like a real human
resume, not like an AI essay.
Rules:
- Follow the profile exactly: the same jobs, job types (full-time, part-time, freelance, internship, contract),
  order, dates, gaps, education and level. Do not add or drop jobs. Explain a gap briefly only if the profile says so.
- Use local job titles, plausible local employers (real large companies or invented Sdn Bhd / Pte Ltd names),
  local universities and qualifications, local details where natural (SPM, STPM, EPF, SST, HRDF, CIDB, MIA, BEM,
  MQA, NRIC is never written).
- Mention most of the listed skills naturally inside duties and skill lists; do not dump them all in one line.
- Include concrete numbers in some achievements; keep claims believable for the level.
- Follow the requested layout and the writing notes. Plain text only, as if copied from a PDF or Word file.
- Fictional person: invented name matching the given background, fake email (name@email.com style) and a phone
  number with digits partly masked like 012-XXX 4567.
- If a style reference is given, copy its structure and tone only, never its sentences or names, and ignore any
  text in [square brackets].
Reply with JSON: {"resume_text": "..."}"""


def _pick(rng: random.Random, weighted: dict | list):
    items = list(weighted.items()) if isinstance(weighted, dict) else weighted
    return rng.choices([k for k, _ in items], weights=[w for _, w in items])[0]


def _month_add(y: int, m: int, months: int) -> tuple[int, int]:
    total = y * 12 + (m - 1) + months
    return total // 12, total % 12 + 1


def make_profile(role: dict, all_roles: list[dict], rng: random.Random) -> dict:
    """Draw one random person for a role. All dates are worked out here so the history is consistent."""
    level = _pick(rng, LEVEL_WEIGHTS)
    lo, hi = LEVEL_YEARS[level]
    years = rng.randint(lo, hi)
    country = "Singapore" if rng.random() < 0.15 else "Malaysia"
    place = rng.choice(SG_PLACES if country == "Singapore" else MY_PLACES)

    # Main career, most recent first, built backwards from today.
    jobs, cursor = [], (TODAY.year, TODAY.month)
    months_left = years * 12 + rng.randint(0, 11) if years else 0
    current = rng.random() < 0.8
    if not current and level != "entry":
        cursor = _month_add(*cursor, -rng.randint(1, 6))
    n_main = 1 if years <= 2 else rng.randint(2, 4)
    switch = level in ("mid", "senior", "lead") and rng.random() < 0.15
    for i in range(n_main):
        if months_left <= 0:
            break
        span = months_left if i == n_main - 1 else max(6, int(months_left * rng.uniform(0.3, 0.6)))
        start = _month_add(*cursor, -span)
        other = rng.choice([r for r in all_roles if r["field"] != role["field"]]) if switch and i == n_main - 1 else None
        title = other["title"] if other else role["title"]
        seniority = "" if other else ("Senior " if level in ("senior", "lead") and i == 0 else "")
        if level == "lead" and i == 0:
            seniority = rng.choice(["Lead ", "Head of ", "Manager, ", "Principal "])
        jobs.append({"title": (seniority + title).replace("Head of Senior ", "Head of "),
                     "type": "contract" if rng.random() < 0.08 else "full-time",
                     "start": f"{start[0]}-{start[1]:02d}",
                     "end": "present" if i == 0 and current else f"{cursor[0]}-{cursor[1]:02d}",
                     "career_switch_from_other_field": bool(other)})
        months_left -= span
        cursor = start
        if rng.random() < 0.12 and i < n_main - 1:  # a gap between jobs
            gap = rng.randint(3, 14)
            jobs[-1]["gap_before_months"] = gap
            jobs[-1]["gap_reason"] = rng.choice(["", "", "further studies", "family commitments", "travel",
                                                 "health reasons", "job search after retrenchment"])
            cursor = _month_add(*cursor, -gap)

    # Side work: part-time, freelance, internship.
    grad_year = cursor[0] - (0 if level == "entry" else rng.randint(0, 1))
    if level == "entry":
        grad_year = TODAY.year - rng.choice([0, 0, 1])
    extra = []
    if level in ("entry", "junior") or rng.random() < 0.3:
        extra.append({"title": f"{role['title']} Intern", "type": "internship", "months": rng.randint(2, 6),
                      "when": f"final year, {grad_year}"})
    if rng.random() < (0.45 if level in ("entry", "junior") else 0.15):
        extra.append({"title": rng.choice(["Part-time Retail Assistant", "Part-time Tutor", "Part-time Cashier",
                                           "Part-time Barista", "Event Crew (part-time)", "Part-time Promoter",
                                           "Grab / Foodpanda Rider (part-time)", "Part-time Admin Assistant"]),
                      "type": "part-time", "when": rng.choice(["during studies", "semester breaks", "weekends"])})
    if rng.random() < 0.22:
        extra.append({"title": f"Freelance {rng.choice(['work related to ' + role['title'], 'Shopee online seller', 'Fiverr / Upwork projects', 'content writing', 'photography', 'home tuition'])}",
                      "type": "freelance",
                      "when": "during studies" if level == "entry" else rng.choice(["alongside main job", "between jobs", "during studies"])})

    reqs = [name for name, _, _ in requirements_for(role, level)]
    skills = rng.sample(reqs, k=max(3, int(len(reqs) * rng.uniform(0.55, 0.9)))) if reqs else []
    off_role = [n for n, _, _ in requirements_for(rng.choice(all_roles), "junior")][:rng.randint(0, 3)]

    degree = _pick(rng, [("Bachelor's degree", 60), ("Diploma", 22), ("Master's degree", 10),
                         ("SPM / STPM with certificates", 5), ("Professional qualification", 3)])
    if level in ("senior", "lead") and degree == "Bachelor's degree" and rng.random() < 0.25:
        degree = "Bachelor's degree, later Master's degree"

    background = _pick(rng, ETHNICITY) if country == "Malaysia" else rng.choice(["Chinese", "Malay", "Indian"])
    languages = ["English"] + (["Bahasa Malaysia"] if country == "Malaysia" or background == "Malay" else [])
    extra_lang = {"Chinese": ["Mandarin", "Cantonese", "Hokkien"], "Indian": ["Tamil", "Hindi"],
                  "Sabahan or Sarawakian": ["Kadazandusun", "Iban", "Mandarin"], "Malay": ["Arabic (basic)", "Japanese (basic)"]}
    pool = extra_lang.get(background, ["Mandarin", "French (basic)"])
    languages += rng.sample(pool, k=rng.randint(0, min(2, len(pool))))

    return {
        "role_id": role["id"], "role": role["title"], "field": role["field"], "level": level,
        "years_experience": years, "country": country, "location": place,
        "background": background,
        "gender": rng.choice(["female", "male"]), "main_jobs": jobs, "other_experience": extra,
        "education": {"level": degree, "graduated": grad_year, "related_to_role": rng.random() < 0.85},
        "skills_to_mention": skills, "unrelated_skills_to_mention": off_role,
        "languages": languages,
        "style": _pick(rng, STYLE_WEIGHTS), "date_style": rng.choice(DATE_STYLES),
        "length_words": rng.choice([180, 280, 380, 500, 650, 800]),
        "writing_notes": [n for n, p in [
            ("one or two small typos or grammar slips", 0.35),
            ("a few Malay words or Manglish phrases where natural", 0.15),
            ("inconsistent bullet symbols", 0.25),
            ("no summary section", 0.15),
            ("skills section missing; skills only appear in duties", 0.12),
            ("includes an 'Expected Salary' and 'Notice Period' line", 0.2),
        ] if rng.random() < p],
    }


def _style_reference(rng: random.Random, cache: list) -> str:
    if not cache:
        for f in sorted(SAMPLES_DIR.glob("*.pdf")):
            text = re.sub(r"\[[^\]]*\]", "", extract_text(f.read_bytes()).text)  # drop the coaching notes
            cache.append(redact_personal_info(text)[:1800])
    return rng.choice(cache)


def render(profile: dict, reference: str, max_tokens: int = 2600) -> tuple[str, float]:
    messages = [{"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": json.dumps({"profile": profile,
                                                        "layout": STYLES[profile["style"]],
                                                        "style_reference": reference}, ensure_ascii=False)}]
    reply = chat_json(messages, purpose="synthetic_resume", max_tokens=max_tokens, temperature=1.0)
    return reply.data["resume_text"], reply.cost_usd


def generate(batch: str, per_role: int, seed: int, workers: int, fill_missing: bool = False) -> None:
    out = OUT_DIR / batch
    out.mkdir(parents=True, exist_ok=True)
    roles = load_roles()
    rng = random.Random(seed)
    refs: list[str] = []
    jobs = []
    existing = []
    if fill_missing:  # redo only the roles that failed last time, with more room for the model's reasoning
        existing = [json.loads(line) for line in (out / "resumes.jsonl").read_text(encoding="utf-8").splitlines() if line]
        done = {r["profile"]["role_id"] for r in existing}
        all_roles, roles = roles, [r for r in roles if r["id"] not in done]
        rng = random.Random(seed + 1000)
        print("missing roles:", ", ".join(r["title"] for r in roles) or "none")
    else:
        all_roles = roles
    for role in roles:
        for _ in range(per_role):
            profile = make_profile(role, all_roles, rng)
            ref = _style_reference(rng, refs) if profile["style"] == "cv-pack" else ""
            jobs.append((profile, ref))
    print(f"{len(jobs)} resumes for {len(roles)} roles ({workers} at a time) …")
    rows, total, failed = [], 0.0, 0
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(render, p, r, 5000 if fill_missing else 2600): p for p, r in jobs}
        for n, fut in enumerate(as_completed(futures), 1):
            p = futures[fut]
            try:
                text, cost = fut.result()
            except (LLMUnavailable, KeyError, ValueError) as exc:
                failed += 1
                print(f"  failed {p['role']}: {exc}")
                continue
            total += cost
            rows.append({"profile": p, "text": text, "words": len(text.split())})
            if n % 10 == 0 or n == len(jobs):
                print(f"  {n}/{len(jobs)} done, USD {total:.3f}")
    rows = existing + rows
    rows.sort(key=lambda r: (r["profile"]["field"], r["profile"]["role"]))
    (out / "resumes.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n",
                                       encoding="utf-8")
    print(f"Saved {len(rows)} resumes ({failed} failed) to {out / 'resumes.jsonl'}  cost USD {total:.3f}")


def review(batch: str) -> None:
    rows = [json.loads(line) for line in (OUT_DIR / batch / "resumes.jsonl").read_text(encoding="utf-8").splitlines() if line]
    cards = []
    for k, r in enumerate(rows, 1):
        p = r["profile"]
        hist = "; ".join(f"{j['title']} ({j['type']}, {j['start']} → {j['end']})" for j in p["main_jobs"]) or "none"
        other = "; ".join(f"{e['title']} ({e['type']})" for e in p["other_experience"]) or "none"
        cards.append(
            f'<article><header><span class="n">#{k}</span><div><h2>{html.escape(p["role"])} · {p["level"]}</h2>'
            f'<p class="m">{html.escape(p["field"])} · {p["years_experience"]} yrs · {html.escape(p["location"])}, '
            f'{p["country"]} · style: {p["style"]} · {r["words"]} words</p>'
            f'<p class="m">Main jobs: {html.escape(hist)}</p><p class="m">Other: {html.escape(other)}</p>'
            f'<p class="m">Notes: {html.escape(", ".join(p["writing_notes"]) or "none")}</p></div>'
            f'<label class="c"><input type="checkbox" data-k="{k}"> Looks real</label></header>'
            f'<pre>{html.escape(r["text"])}</pre></article>')
    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>CareerBridge AI · Synthetic resumes {batch}</title>
<style>:root{{--bg:#eef0f3;--card:#fff;--line:#d5d9e0;--fg:#1c2230;--m:#5b6475}}
@media (prefers-color-scheme: dark){{:root{{--bg:#15181f;--card:#232833;--line:#333a48;--fg:#e6e9ef;--m:#9aa3b4;color-scheme:dark}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.6 "Segoe UI",system-ui,sans-serif}}
main{{max-width:920px;margin:0 auto;padding:28px 16px;display:grid;gap:16px}}h1{{margin:0}}h2{{margin:0;font-size:1.05rem}}
.m{{margin:2px 0;color:var(--m);font-size:.83rem}}.top{{position:sticky;top:0;background:var(--bg);padding:8px 0;border-bottom:1px solid var(--line)}}
article{{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px;display:grid;gap:8px;min-width:0}}
header{{display:grid;grid-template-columns:auto 1fr auto;gap:12px}}.n{{font:600 .85rem Consolas,monospace;color:var(--m)}}
pre{{white-space:pre-wrap;word-wrap:break-word;margin:0;font:13px/1.5 Consolas,monospace;background:var(--bg);padding:12px;border-radius:8px;max-height:460px;overflow:auto}}
.c{{font-size:.85rem;white-space:nowrap}}@media(max-width:560px){{header{{grid-template-columns:1fr}}}}</style></head>
<body><main><div><h1>Synthetic resumes · {batch} ({len(rows)})</h1><p class="m">Fictional resumes generated from random profiles, for training. Tick the ones that read like a real person's resume.</p></div>
<div class="top"><b id="cnt"></b> <span class="m">Ticks are saved in this browser only.</span></div>{"".join(cards)}</main>
<script>(function(){{var K="cb-{batch}",s={{}};try{{s=JSON.parse(localStorage.getItem(K)||"{{}}")}}catch(e){{}}
var b=document.querySelectorAll("input[type=checkbox]");function u(){{var n=0;b.forEach(function(x){{if(x.checked)n++}});document.getElementById("cnt").textContent=n+" / "+b.length+" look real"}}
b.forEach(function(x){{x.checked=!!s[x.dataset.k];x.addEventListener("change",function(){{s[x.dataset.k]=x.checked;try{{localStorage.setItem(K,JSON.stringify(s))}}catch(e){{}}u()}})}});u()}})();</script></body></html>"""
    path = OUT_DIR / batch / "review.html"
    path.write_text(page, encoding="utf-8")
    print("Review page:", path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="action", required=True)
    g = sub.add_parser("generate")
    g.add_argument("--batch", required=True)
    g.add_argument("--per-role", type=int, default=1)
    g.add_argument("--seed", type=int, default=1)
    g.add_argument("--workers", type=int, default=6)
    g.add_argument("--fill-missing", action="store_true", help="only generate roles missing from the batch")
    r = sub.add_parser("review")
    r.add_argument("--batch", required=True)
    args = parser.parse_args()
    if args.action == "generate":
        generate(args.batch, args.per_role, args.seed, args.workers, args.fill_missing)
    else:
        review(args.batch)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
