"""Fit scoring tests (uses a small fake role)."""

from datetime import date

import pytest

from app.matching.fit import estimate_years, has_skill, match_label, requirements_for, score_fit
from app.catalog.skillnames import skill_aliases, text_ngrams


def market(name, share, **by_level):
    return {"name": name, "share": share, "by_level": by_level}


DATA_ANALYST = {
    "title": "Data Analyst",
    "postings": {"total": 500},
    "skills": {
        "market_core": [market("SQL", 0.6, junior=0.5, senior=0.7), market("Python", 0.4, junior=0.3, senior=0.5)],
        "market_common": [market("Power BI", 0.2), market("Machine Learning", 0.15, junior=0.1, senior=0.2)],
        "tools": ["Microsoft Excel", "Amazon Web Services AWS"],
        "essential": [], "optional": [],
        "soft": [{"name": "Communication", "share": 0.3}],
    },
}

RESUME = """AINA RAHMAN
WORK EXPERIENCE
Data Analyst, Retail Group   Jan 2024 - Present
Built dashboards in Power BI with SQL and Python. Strong communication.
Intern, TechCorp   Jun 2023 - Dec 2023
EDUCATION
Bachelor of Computer Science, UTeM   2020 - 2024
SKILLS
SQL, Python, Power BI, Excel
"""


def test_skill_aliases_cover_vendor_names_and_acronyms():
    assert "excel" in skill_aliases("Microsoft Excel")
    assert "aws" in skill_aliases("Amazon Web Services AWS")
    assert "sql" in skill_aliases("Structured query language SQL")


def test_skills_are_found_as_whole_phrases():
    phrases = text_ngrams("Experienced in Power BI and SQL")
    assert has_skill("Power BI", phrases)
    assert has_skill("SQL", phrases)
    assert not has_skill("R", phrases)  # single letters are never matched


def test_requirement_weights_follow_the_chosen_level():
    junior = dict((n, w) for n, w, _ in requirements_for(DATA_ANALYST, "junior"))
    senior = dict((n, w) for n, w, _ in requirements_for(DATA_ANALYST, "senior"))
    assert junior["SQL"] == 0.5 and senior["SQL"] == 0.7
    assert junior["Power BI"] == 0.2  # no level data -> overall share


def test_experience_years_ignore_education_dates():
    years = estimate_years(RESUME, today=date(2026, 10, 1))
    assert years == pytest.approx(3.0, abs=0.6)  # 2023–2026 work; 2020–2024 study not counted


def test_good_fit_scores_high_and_lists_gaps():
    result = score_fit(RESUME, DATA_ANALYST, "junior")
    assert result.score >= 75
    assert {r.name for r in result.matched} >= {"SQL", "Python", "Power BI", "Microsoft Excel"}
    assert "Machine Learning" in {r.name for r in result.missing}
    assert "Communication" in result.soft_skills_found


def test_unrelated_background_gets_low_score():
    nurse_resume = "WORK EXPERIENCE\nStaff Nurse, Hospital Melaka  2019 - 2024\nPatient care, CPR\nEDUCATION\nDiploma in Nursing"
    result = score_fit(nurse_resume, DATA_ANALYST, "junior")
    assert result.score < 20
    assert result.label == "Low Match"


def test_level_mismatch_is_explained():
    result = score_fit(RESUME, DATA_ANALYST, "senior")
    assert any("closer to Junior" in n for n in result.notes)


def test_role_with_few_ads_uses_occupation_skills():
    rare = {"title": "Plantation Executive", "postings": {"total": 4},
            "skills": {"market_core": [], "market_common": [], "tools": ["Microsoft Excel"],
                       "essential": ["crop production principles", "agronomy"], "optional": ["GIS"], "soft": []}}
    sources = {src for _, _, src in requirements_for(rare, "junior")}
    assert sources == {"essential", "optional", "tool"}


@pytest.mark.parametrize(("score", "label"), [(90, "Strong Match"), (70, "Good Match"), (50, "Partial Match"), (10, "Low Match")])
def test_match_labels(score, label):
    assert match_label(score) == label
