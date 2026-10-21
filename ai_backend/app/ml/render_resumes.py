"""Lay out generated resumes as real files, then read them back like an uploaded resume."""

import argparse
import copy
import html
import json
import random
import re
from pathlib import Path

import docx
import pymupdf
from docx.shared import Pt

from app.ml.catalog import DATA_DIR
from app.services.resume_text import extract_text

OUT_DIR = DATA_DIR / "synthetic"
JOBSTREET_TEMPLATE = DATA_DIR / "eval" / "real" / "originals" / "JobStreet-resume-template-1.docx"

_BULLET = re.compile(r"^\s*(?:[•\-*▪·o◦►]|\d+[.)])\s+")
_MONTH = r"(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?'?\s*\d{2,4}"
_DATE = rf"(?:{_MONTH}|\d{{1,2}}/\d{{4}}|\d{{4}})"
_RANGE = re.compile(rf"({_DATE})\s*(?:[-–—]+|to|until)\s*({_DATE}|present|current|now|date)", re.I)
_SECTION_WORDS = {"profile", "summary", "executive summary", "professional summary", "objective", "career objective",
                  "experience", "work experience", "professional experience", "employment history", "career history",
                  "education", "education and qualifications", "qualifications", "skills", "key skills",
                  "technical skills", "areas of expertise", "core competencies", "languages", "certifications",
                  "awards", "achievements", "projects", "interests", "hobbies", "references", "others",
                  "personal details", "personal particulars", "contact", "co-curricular activities",
                  "internship", "part-time experience", "miscellaneous information", "additional information",
                  "personal profile", "experience / specialisms", "volunteer experience", "courses", "training"}
_SECTION_KEYS = ("experience", "education", "skill", "summary", "profile", "objective", "language", "certif",
                 "award", "achievement", "reference", "interest", "hobb", "project", "activities", "information",
                 "details", "particulars", "qualification", "expertise", "competenc", "internship", "training",
                 "course", "contact", "career", "employment", "history", "personal", "volunteer", "others",
                 "specialism", "strength")
_PLACES = ("kuala lumpur", "selangor", "johor", "penang", "pulau pinang", "perak", "melaka", "malacca", "negeri sembilan",
           "pahang", "kedah", "kelantan", "terengganu", "sabah", "sarawak", "perlis", "putrajaya", "labuan",
           "singapore", "malaysia", "petaling jaya", "shah alam", "cyberjaya", "ipoh", "kuching", "kota kinabalu")
SIDEBAR_HINTS = ("contact", "skill", "language", "certif", "personal", "interest", "hobb", "reference", "competenc",
                 "expertise", "award", "course", "training")


def is_heading(line: str) -> bool:
    s = line.strip().rstrip(":").strip()
    if not s or _BULLET.match(line) or len(s) > 45 or "@" in s:
        return False
    low = s.lower()
    if low in _SECTION_WORDS or any(low.startswith(w + " ") and len(low.split()) <= 4 for w in ("work", "professional", "key", "technical")):
        return True
    letters = re.sub(r"[^A-Za-z]", "", s)
    looks_heading = len(letters) >= 4 and len(s.split()) <= 5 and not _RANGE.search(s)
    # A capital line is a heading only if it names a section.
    return looks_heading and any(k in low for k in _SECTION_KEYS)


def parse(text: str) -> dict:
    """Split plain resume text into a header and sections of (kind, text) lines."""
    lines = [ln.rstrip() for ln in text.replace("\r", "").split("\n")]
    head, sections, current = [], [], None
    first = next((i for i, ln in enumerate(lines) if ln.strip()), 0)
    for i, ln in enumerate(lines):
        if i == first:
            head.append(ln.strip())
            continue
        if not ln.strip():
            if current is not None:
                current["lines"].append(("gap", ""))
            continue
        if is_heading(ln):
            current = {"heading": ln.strip().rstrip(":"), "lines": []}
            sections.append(current)
        elif current is None:
            head.append(ln.strip())
        elif _BULLET.match(ln):
            current["lines"].append(("bullet", _BULLET.sub("", ln).strip()))
        elif _RANGE.search(ln):
            current["lines"].append(("dated", ln.strip()))
        else:
            current["lines"].append(("text", ln.strip()))
    name = head[0] if head else "Resume"
    title = (head[1] if len(head) > 1 and "@" not in head[1] and not re.search(r"\d{3}", head[1])
             and not any(pl in head[1].lower() for pl in _PLACES) else "")
    contact = [h for h in head[1:] if h != title]
    return {"name": name, "title": title, "contact": contact, "sections": sections}


def _esc(s: str) -> str:
    return html.escape(s, quote=False)


def _dated_parts(line: str) -> tuple[str, str]:
    m = _RANGE.search(line)
    left = (line[:m.start()] + line[m.end():]).strip(" |,–—-()") if m else line
    return left, (m.group(0) if m else "")


def _section_html(sec: dict, font: str, size: int, accent: str, rule: bool, caps: bool) -> str:
    head = sec["heading"].upper() if caps else sec["heading"]
    border = f"border-bottom:1px solid {accent};" if rule else ""
    out = [f'<p style="font-family:{font};font-size:{size + 1}px;font-weight:bold;color:{accent};{border}'
           f'margin-top:10px;margin-bottom:4px">{_esc(head)}</p>']
    bullets = []

    def flush():
        if bullets:
            out.append(f'<ul style="font-family:{font};font-size:{size}px;margin-top:2px;margin-bottom:2px">'
                       + "".join(f"<li>{_esc(b)}</li>" for b in bullets) + "</ul>")
            bullets.clear()

    for kind, txt in sec["lines"]:
        if kind == "bullet":
            bullets.append(txt)
            continue
        flush()
        if kind == "dated":
            left, right = _dated_parts(txt)
            out.append(f'<table style="width:100%;font-family:{font};font-size:{size}px;margin:0"><tr>'
                       f'<td><b>{_esc(left)}</b></td><td style="text-align:right"><b>{_esc(right)}</b></td></tr></table>')
        elif kind == "text":
            bold = "font-weight:bold;" if txt.upper() == txt and len(txt) < 60 else ""
            out.append(f'<p style="font-family:{font};font-size:{size}px;{bold}margin:1px 0">{_esc(txt)}</p>')
    flush()
    return "".join(out)


def _write_story_pdf(path: Path, parts: list[tuple[str, pymupdf.Rect | None]]) -> int:
    """Draw one or more HTML stories, each in its own rectangle, continuing onto new pages."""
    page_rect = pymupdf.paper_rect("a4")
    writer = pymupdf.DocumentWriter(str(path))
    stories = [(pymupdf.Story(html=h), r) for h, r in parts]
    pending = [True] * len(stories)
    pages = 0
    while any(pending) and pages < 6:
        dev = writer.begin_page(page_rect)
        for i, (story, rect) in enumerate(stories):
            if pending[i]:
                more, _ = story.place(rect)
                story.draw(dev)
                pending[i] = bool(more)
        writer.end_page()
        pages += 1
    writer.close()
    return pages


def pdf_cv_pack(p: dict, path: Path) -> int:
    font = "serif"
    top = (f'<p style="text-align:center;font-family:{font};font-size:20px;font-weight:bold;margin:0">{_esc(p["name"].upper())}</p>'
           + (f'<p style="text-align:center;font-family:{font};font-size:14px;margin:0">{_esc(p["title"])}</p>' if p["title"] else "")
           + "".join(f'<p style="text-align:center;font-family:{font};font-size:9px;margin:0">{_esc(c)}</p>' for c in p["contact"]))
    body = "".join(_section_html(s, font, 10, "#000000", True, True) for s in p["sections"])
    return _write_story_pdf(path, [(top + body, pymupdf.Rect(50, 45, 545, 800))])


def pdf_student(p: dict, path: Path, rng: random.Random) -> int:
    accent = rng.choice(["#1f4e79", "#7a1f3d", "#215a3a", "#3b3b98", "#8a4b08"])
    font = "sans-serif"
    top = (f'<p style="font-family:{font};font-size:24px;font-weight:bold;color:{accent};margin:0">{_esc(p["name"])}</p>'
           + (f'<p style="font-family:{font};font-size:13px;margin:0">{_esc(p["title"])}</p>' if p["title"] else "")
           + f'<p style="font-family:{font};font-size:9px;color:#555555;margin-bottom:6px">{_esc("  |  ".join(p["contact"]))}</p>')
    body = "".join(_section_html(s, font, 10, accent, rng.random() < 0.5, rng.random() < 0.5) for s in p["sections"])
    return _write_story_pdf(path, [(top + body, pymupdf.Rect(45, 40, 550, 805))])


def pdf_two_column(p: dict, path: Path, rng: random.Random) -> int:
    accent = rng.choice(["#2b3a55", "#004d61", "#5b2a86", "#333333"])
    font = rng.choice(["sans-serif", "serif"])
    side = [dict(s, lines=list(s["lines"])) for s in p["sections"] if any(h in s["heading"].lower() for h in SIDEBAR_HINTS)]
    main = [dict(s, lines=list(s["lines"])) for s in p["sections"] if not any(h in s["heading"].lower() for h in SIDEBAR_HINTS)]
    # Short items go to the sidebar, the rest to the main column.
    if main:
        target = next((s for s in main if "experience" in s["heading"].lower() or "history" in s["heading"].lower()), main[-1])
        for sec in side:
            keep = [(k, t) for k, t in sec["lines"] if k == "gap" or (k == "text" and len(t) < 110)]
            target["lines"] += [(k, t) for k, t in sec["lines"] if (k, t) not in keep]
            sec["lines"] = keep
    left = (f'<p style="font-family:{font};font-size:9px;font-weight:bold;color:{accent}">CONTACT</p>'
            + "".join(f'<p style="font-family:{font};font-size:8px;margin:1px 0">{_esc(c)}</p>' for c in p["contact"])
            + "".join(_section_html(s, font, 8, accent, False, True) for s in side))
    right = (f'<p style="font-family:{font};font-size:22px;font-weight:bold;color:{accent};margin:0">{_esc(p["name"].upper())}</p>'
             + (f'<p style="font-family:{font};font-size:12px;margin-bottom:6px">{_esc(p["title"])}</p>' if p["title"] else "")
             + "".join(_section_html(s, font, 9, accent, True, True) for s in main))
    return _write_story_pdf(path, [(left, pymupdf.Rect(30, 40, 185, 805)), (right, pymupdf.Rect(205, 40, 565, 805))])


def _docx_clear(document: docx.document.Document) -> None:
    body = document.element.body
    for child in list(body):
        if not child.tag.endswith("sectPr"):
            body.remove(child)


def _style(document, name: str, fallback: str = "Normal"):
    try:
        return document.styles[name]
    except KeyError:
        return document.styles[fallback]


def docx_write(p: dict, path: Path, kind: str, rng: random.Random) -> int:
    if kind == "jobstreet":
        d = docx.Document(str(JOBSTREET_TEMPLATE))
        _docx_clear(d)
        st = {"name": "personalDetailsTitleStyle", "head": "sectionTitleStyle", "text": "plainTextStyle",
              "dated": "roleDateStyle", "bullet": "bulletStyle", "contact": "plainTextStyle"}
    else:
        d = docx.Document()
        d.styles["Normal"].font.name = rng.choice(["Calibri", "Arial", "Times New Roman", "Cambria"])
        d.styles["Normal"].font.size = Pt(rng.choice([10, 10.5, 11]))
        st = {"name": "Title" if kind == "career-guide" else "Heading 1", "head": "Heading 2", "text": "Normal",
              "dated": "Normal", "bullet": "List Bullet", "contact": "Normal"}
    name = f'{p["name"]} - Curriculum Vitae' if kind == "career-guide" else p["name"]
    d.add_paragraph(name, style=_style(d, st["name"]))
    if p["title"]:
        d.add_paragraph(p["title"], style=_style(d, st["text"]))
    if p["contact"]:
        d.add_paragraph(" | ".join(p["contact"]), style=_style(d, st["contact"]))
    for sec in p["sections"]:
        d.add_paragraph(sec["heading"], style=_style(d, st["head"]))
        for kind_, txt in sec["lines"]:
            if kind_ == "gap":
                continue
            para = d.add_paragraph(txt, style=_style(d, st[kind_ if kind_ in st else "text"]))
            if kind_ == "dated" and kind != "jobstreet":
                for run in para.runs:
                    run.bold = True
    d.save(str(path))
    return 1


def pdf_to_jpg(pdf: Path, jpg: Path, rng: random.Random) -> None:
    page = pymupdf.open(str(pdf))[0]
    pix = page.get_pixmap(dpi=rng.choice([90, 110, 130]))
    pix.save(str(jpg), jpg_quality=rng.choice([55, 70, 85]))


def render_batch(batch: str, seed: int = 7) -> None:
    folder = OUT_DIR / batch
    files = folder / "files"
    files.mkdir(parents=True, exist_ok=True)
    rows = [json.loads(line) for line in (folder / "resumes.jsonl").read_text(encoding="utf-8").splitlines() if line]
    rng = random.Random(seed)
    out = []
    for k, r in enumerate(rows, 1):
        prof = r["profile"]
        parsed = parse(r["text"])
        stem = f'{k:03d}_{prof["role_id"]}'
        style = prof["style"]
        if style in ("jobstreet", "plain", "career-guide"):
            path = files / f"{stem}.docx"
            docx_write(parsed, path, style, rng)
            pages = 1
        else:
            path = files / f"{stem}.pdf"
            pages = {"cv-pack": lambda: pdf_cv_pack(parsed, path),
                     "two-column": lambda: pdf_two_column(parsed, path, rng),
                     "student": lambda: pdf_student(parsed, path, rng)}[style]()
            if pages == 1 and rng.random() < 0.35:
                jpg = files / f"{stem}.jpg"
                pdf_to_jpg(path, jpg, rng)
                path.unlink()
                path = jpg
        extracted = extract_text(path.read_bytes())
        out.append({"profile": prof, "generated_text": r["text"], "file": f"files/{path.name}",
                    "file_kind": path.suffix[1:], "pages": pages, "extracted_text": extracted.text,
                    "extract_method": extracted.method, "sections_found": len(parsed["sections"])})
        if k % 20 == 0 or k == len(rows):
            print(f"  {k}/{len(rows)} rendered")
    (folder / "rendered.jsonl").write_text("\n".join(json.dumps(o, ensure_ascii=False) for o in out) + "\n",
                                           encoding="utf-8")
    kinds = {}
    for o in out:
        kinds[o["file_kind"]] = kinds.get(o["file_kind"], 0) + 1
    print(f"Saved {len(out)} files {kinds} to {files}")
    review(batch, out)


def review(batch: str, rows: list[dict]) -> None:
    cards = []
    for k, r in enumerate(rows, 1):
        p = r["profile"]
        hist = "; ".join(f"{j['title']} ({j['type']}, {j['start']} → {j['end']})" for j in p["main_jobs"]) or "none"
        other = "; ".join(f"{e['title']} ({e['type']})" for e in p["other_experience"]) or "none"
        f = html.escape(r["file"])
        if r["file_kind"] == "pdf":
            preview = f'<iframe src="{f}#view=FitH" title="Resume {k}"></iframe>'
        elif r["file_kind"] == "jpg":
            preview = f'<img src="{f}" alt="Resume {k} as an image">'
        else:
            preview = (f'<p class="m">Word file: <a href="{f}">open {html.escape(Path(r["file"]).name)} in Word</a> '
                       f'(browsers cannot show .docx files)</p>')
        cards.append(
            f'<article><header><span class="n">#{k}</span><div><h2>{html.escape(p["role"])} · {p["level"]}</h2>'
            f'<p class="m">{html.escape(p["field"])} · {p["years_experience"]} yrs · {html.escape(p["location"])}, {p["country"]}'
            f' · layout: {p["style"]} · file: {r["file_kind"].upper()} · {r["pages"]} page(s)</p>'
            f'<p class="m">Main jobs: {html.escape(hist)}</p><p class="m">Other: {html.escape(other)}</p></div>'
            f'<label class="c"><input type="checkbox" data-k="{k}"> Looks real</label></header>{preview}'
            f'<details><summary>Text the system reads from this file ({r["extract_method"]})</summary>'
            f'<pre>{html.escape(r["extracted_text"])}</pre></details></article>')
    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>CareerBridge AI · Rendered resumes {batch}</title>
<style>:root{{--bg:#eef0f3;--card:#fff;--line:#d5d9e0;--fg:#1c2230;--m:#5b6475}}
@media (prefers-color-scheme: dark){{:root{{--bg:#15181f;--card:#232833;--line:#333a48;--fg:#e6e9ef;--m:#9aa3b4;color-scheme:dark}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.6 "Segoe UI",system-ui,sans-serif}}
main{{max-width:980px;margin:0 auto;padding:28px 16px;display:grid;gap:18px}}h1{{margin:0}}h2{{margin:0;font-size:1.05rem}}
.m{{margin:2px 0;color:var(--m);font-size:.83rem}}.top{{position:sticky;top:0;background:var(--bg);padding:8px 0;border-bottom:1px solid var(--line);z-index:2}}
article{{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px;display:grid;gap:10px;min-width:0}}
header{{display:grid;grid-template-columns:auto 1fr auto;gap:12px}}.n{{font:600 .85rem Consolas,monospace;color:var(--m)}}
iframe{{width:100%;height:820px;border:1px solid var(--line);border-radius:6px;background:#fff}}
img{{max-width:100%;border:1px solid var(--line);border-radius:6px}}a{{color:inherit}}
pre{{white-space:pre-wrap;word-wrap:break-word;margin:6px 0 0;font:12.5px/1.5 Consolas,monospace;background:var(--bg);padding:12px;border-radius:8px;max-height:420px;overflow:auto}}
summary{{cursor:pointer;color:var(--m);font-size:.85rem}}.c{{font-size:.85rem;white-space:nowrap}}
@media(max-width:560px){{header{{grid-template-columns:1fr}}iframe{{height:560px}}}}</style></head>
<body><main><div><h1>Rendered resumes · {batch} ({len(rows)})</h1><p class="m">Each generated resume laid out as a PDF, Word file or image in a layout modelled on the reference resumes. Open the text panel to see what the system reads from the file; that text is what the models train on.</p></div>
<div class="top"><b id="cnt"></b> <span class="m">Ticks are saved in this browser only.</span></div>{"".join(cards)}</main>
<script>(function(){{var K="cb-render-{batch}",s={{}};try{{s=JSON.parse(localStorage.getItem(K)||"{{}}")}}catch(e){{}}
var b=document.querySelectorAll("input[type=checkbox]");function u(){{var n=0;b.forEach(function(x){{if(x.checked)n++}});document.getElementById("cnt").textContent=n+" / "+b.length+" look real"}}
b.forEach(function(x){{x.checked=!!s[x.dataset.k];x.addEventListener("change",function(){{s[x.dataset.k]=x.checked;try{{localStorage.setItem(K,JSON.stringify(s))}}catch(e){{}}u()}})}});u()}})();</script></body></html>"""
    path = OUT_DIR / batch / "review_files.html"
    path.write_text(page, encoding="utf-8")
    print("Review page:", path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--batch", required=True)
    args = parser.parse_args()
    render_batch(args.batch)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
