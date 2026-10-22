from datetime import date

from app.catalog.skillnames import is_requirement, skill_aliases
from app.llm.profile_extract import Job, from_dict
from app.matching.assess import assess
from app.matching.fit import requirements_for
from app.matching.roles import find_role


def profile(jobs, education=None, skills=()):
    return from_dict({"headline": None, "skills": list(skills), "soft_skills": [], "experience": jobs,
                      "education": education or [], "certifications": [], "languages": [], "uncertain": []})


ML_JOBS = [{"title": "Machine Learning Engineer", "organisation": "Aurora", "start": "2018-01", "end": "present",
            "type": "full-time", "highlights": ["Built deep learning models with TensorFlow and PyTorch in Python"]},
           {"title": "Machine Learning Developer", "organisation": "PNC", "start": "2016-07", "end": "2018-01",
            "type": "full-time", "highlights": ["NLP and Bayesian models"]}]
CS_DEGREE = [{"level": "Bachelor", "field": "Mathematics and Computer Science", "institution": "CMU", "end_year": 2016}]
ML_TEXT = "## Experience\nMachine Learning Engineer\nTensorFlow PyTorch Python AI natural language processing algorithms\n"


def test_job_months_from_dates():
    assert Job("x", None, "2016-07", "2018-01", "full-time").months() == 19
    assert Job("x", None, "2020", "present", "unknown").months(date(2021, 12, 1)) == 24
    assert Job("x", None, None, "2018-01", "full-time").months() is None


def test_experienced_profile_gets_a_higher_level_suggestion():
    a = assess(profile(ML_JOBS, CS_DEGREE), ML_TEXT, find_role("AI Engineer"), "mid")

    assert a.relevant_years and a.relevant_years >= 5
    assert a.suggested_level in ("senior", "lead")
    assert a.parts["experience"].score == 1.0 and a.parts["education"].score == 1.0


def test_unreadable_dates_are_not_scored_and_weights_shift():
    jobs = [dict(j, start=None, end=None) for j in ML_JOBS]
    a = assess(profile(jobs, CS_DEGREE), ML_TEXT, find_role("AI Engineer"), "mid")

    assert a.parts["experience"].score is None and a.parts["experience"].weight == 0
    assert "could not read the dates" in a.parts["experience"].reasons[0]
    assert abs(a.parts["skills"].weight + a.parts["education"].weight - 1) < 1e-9


def test_unrelated_field_of_study_counts_less():
    marketing = [{"level": "Master", "field": "Marketing", "institution": None, "end_year": None}]
    related = assess(profile([], CS_DEGREE), "", find_role("Data Analyst"), "entry").parts["education"].score
    unrelated = assess(profile([], marketing), "", find_role("Data Analyst"), "entry").parts["education"].score
    assert related > unrelated


def test_job_ad_noise_is_not_a_requirement():
    for noise in ("Master's Degree", "3+ Years of Experience", "Insights", "Programming", "Paid Time Off"):
        assert not is_requirement(noise)
    names = [n for n, _, _ in requirements_for(find_role("AI Engineer"), "mid")]
    assert not ({"AI", "Artificial Intelligence"} <= set(names))  # one skill, not counted twice


def test_abbreviations_and_related_terms_match():
    assert "artificial intelligence" in skill_aliases("AI")
    assert "data analytics" in skill_aliases("Data Analysis")
    assert "dashboards" in skill_aliases("Data Visualization")
    assert "image recognition" in skill_aliases("Computer Vision")


def test_unrelated_work_is_not_counted_as_related_experience():
    teacher = [{"title": "Teacher, Literature in English", "organisation": "School", "start": "2009-07", "end": "2021-05",
                "type": "full-time", "highlights": ["Taught literature classes"]}]
    a = assess(profile(teacher), "", find_role("Software Engineer"), "junior")

    assert a.relevant_years == 0 and a.suggested_level is None
    assert a.parts["experience"].score < 0.5
    assert "carry over" in a.parts["experience"].reasons[0]


def test_similar_titles_count_as_related_experience():
    ai = find_role("AI Engineer")
    from app.matching.assess import _title_relevance
    assert _title_relevance("Machine Learning Software Engineer", ai) == 1.0
    assert _title_relevance("Machine Learning Engineer", ai) == 1.0
    assert _title_relevance("Data Science Intern", ai) == 0.6
    assert _title_relevance("Machine Learning Engineer", find_role("Data Engineer")) == 0.6


def test_years_alone_suggest_senior_not_lead():
    jobs = [{"title": "Machine Learning Engineer", "organisation": "X", "start": "2010-01", "end": "2024-01",
             "type": "full-time", "highlights": []}]
    a = assess(profile(jobs, CS_DEGREE), ML_TEXT, find_role("AI Engineer"), "mid")
    assert a.relevant_years >= 10 and a.suggested_level == "senior"


def test_lead_level_needs_some_sign_of_leading():
    jobs = [{"title": "Machine Learning Engineer", "organisation": "X", "start": "2010-01", "end": "2024-01",
             "type": "full-time", "highlights": ["Built models"]}]
    plain = assess(profile(jobs, CS_DEGREE), ML_TEXT, find_role("AI Engineer"), "lead").parts["experience"]
    assert plain.score == 0.7 and any("leading people" in r for r in plain.reasons)

    jobs[0]["highlights"] = ["Led a team of four engineers"]
    led = assess(profile(jobs, CS_DEGREE), ML_TEXT, find_role("AI Engineer"), "lead").parts["experience"]
    assert led.score == 1.0
