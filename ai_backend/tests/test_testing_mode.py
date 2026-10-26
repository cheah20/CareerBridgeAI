import pymupdf
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api import testing
from app.core.errors import register_error_handlers
from app.llm.client import LLMReply, LLMUnavailable
from app.llm.profile_extract import from_dict
from app.ml.predict import CareerSuggestion
from app.services import logbook

RESUME = ("Aina Rahman\nData Analyst\naina@example.com | 012-345 6789\n\nEXPERIENCE\nJunior Data Analyst\nMaybank\n"
          "Jan 2023 - Present\n- Built Power BI dashboards and SQL reports\n\nSKILLS\nPython, SQL, Power BI, Excel\n\n"
          "EDUCATION\nBachelor of Computer Science (Data Science)")
PROFILE = {"headline": "Data Analyst", "skills": ["Python", "SQL", "Power BI", "Excel"], "soft_skills": [],
           "experience": [{"title": "Junior Data Analyst", "organisation": "Maybank", "start": "2023-01",
                           "end": "present", "type": "full-time", "highlights": ["Built Power BI dashboards and SQL reports"]}],
           "education": [{"level": "Bachelor", "field": "Computer Science", "institution": None, "end_year": None}],
           "certifications": [], "languages": [], "uncertain": []}


def make_pdf(text: str = RESUME) -> bytes:
    doc = pymupdf.open()
    doc.new_page().insert_text((50, 72), text)
    return doc.tobytes()


@pytest.fixture
def local(tmp_path, monkeypatch):
    monkeypatch.setattr(logbook, "LOGBOOK_DIR", tmp_path)
    seen = {}

    def fake_extract(clean_markdown, user_id=None):
        seen["clean"] = clean_markdown
        return from_dict(PROFILE)

    monkeypatch.setattr(testing, "extract_profile", fake_extract)
    monkeypatch.setattr(testing, "coach", lambda *a, **k: LLMReply({"summary": "Great start."}, cached=False, cost_usd=0))
    # The trained model is not in Git, so use a fixed answer.
    monkeypatch.setattr(testing, "suggest_careers", lambda text, top=3: (
        "test", [CareerSuggestion("DATA-SCIENCE", "Data Science", 0.8),
                   CareerSuggestion("INFORMATION-TECHNOLOGY", "Information Technology", 0.1)]))
    app = FastAPI()
    register_error_handlers(app)
    app.include_router(testing.router)
    client = TestClient(app)
    client.seen = seen
    return client


def analyse(client, **data):
    return client.post("/testing/analyse", files={"file": ("aina.pdf", make_pdf(), "application/pdf")},
                       data={"role_id": "data-analyst", "level": "junior", **data})


def test_testing_routes_do_not_exist_when_mode_is_off(client):
    assert client.get("/testing/catalog").status_code == 404


def test_other_computers_are_refused(tmp_path, monkeypatch):
    monkeypatch.setattr(logbook, "LOGBOOK_DIR", tmp_path)
    app = FastAPI()
    register_error_handlers(app)
    app.include_router(testing.router)
    assert TestClient(app, client=("203.0.113.9", 50000)).get("/testing/catalog").status_code == 403


def test_catalog_lists_fields_roles_and_levels(local):
    body = local.get("/testing/catalog").json()
    assert len(body["levels"]) == 5
    assert len(body["fields"]) == 17
    assert sum(len(f["roles"]) for f in body["fields"]) == 158


def test_analysis_scores_the_profile_and_keeps_it_in_the_logbook(local, tmp_path):
    response = analyse(local)

    assert response.status_code == 200
    body = response.json()
    assert body["format"] == 2 and body["role"]["title"] == "Data Analyst"
    assert 0 <= body["assessment"]["score"] <= 100
    assert "SQL" in body["assessment"]["core_found"]
    assert body["directions"]["items"]
    assert (tmp_path / f"{body['id']}.json").exists()
    assert local.get("/testing/logbook").json()[0]["id"] == body["id"]


def test_personal_details_never_reach_the_ai(local):
    body = analyse(local).json()

    for private in ("aina@example.com", "012-345 6789", "Aina Rahman"):
        assert private not in local.seen["clean"]
        assert private in body["markdown"]          # the stored full copy keeps them, like the original file


def test_advice_is_added_later_to_the_same_entry(local):
    entry_id = analyse(local).json()["id"]

    advice = local.post(f"/testing/logbook/{entry_id}/advice").json()

    assert advice["advice"]["summary"] == "Great start."
    assert local.get(f"/testing/logbook/{entry_id}").json()["advice"]["summary"] == "Great start."


def test_without_the_ai_service_the_analysis_still_works(local, monkeypatch):
    def unavailable(_, user_id=None):
        raise LLMUnavailable("The AI service is not responding right now.")

    monkeypatch.setattr(testing, "extract_profile", unavailable)
    body = analyse(local).json()

    assert body["assessment"]["basic_mode"] is True
    assert body["profile"] is None and "not responding" in body["profile_error"]


@pytest.mark.parametrize("data, files, message", [
    ({"role_id": "no-such-role", "level": "junior"}, ("a.pdf", make_pdf(), "application/pdf"), "Unknown job title"),
    ({"role_id": "data-analyst", "level": "expert"}, ("a.pdf", make_pdf(), "application/pdf"), "Unknown experience level"),
    ({"role_id": "data-analyst", "level": "junior"}, ("a.txt", b"just some text", "text/plain"), ""),
])
def test_bad_requests_get_a_clear_400(local, data, files, message):
    response = local.post("/testing/analyse", files={"file": files}, data=data)

    assert response.status_code == 400
    assert message in response.json()["error"]["message"]


def test_logbook_ids_cannot_reach_other_files(local):
    assert local.get("/testing/logbook/..%2F..%2F.env").status_code == 404
    assert local.get("/testing/logbook/20261018-000000-abcdef").status_code == 404


def test_analysis_is_enriched_and_supports_whatif_and_feedback(local):
    entry = analyse(local).json()
    detail = entry["assessment"]["skills_detail"]
    assert detail and all({"name", "core", "share", "found"} <= set(d) for d in detail)
    assert all("gain" in d for d in detail if not d["found"])
    assert set(entry["level_scores"]) == {"entry", "junior", "mid", "senior", "lead"}
    assert entry["related_roles"] and all(r["title"] != "Data Analyst" for r in entry["related_roles"])

    missing = next(d["name"] for d in detail if not d["found"])
    preview = local.post(f"/testing/logbook/{entry['id']}/whatif", json={"level": "junior", "skills": [missing]}).json()
    assert preview["score"] >= entry["assessment"]["score"]
    assert local.post(f"/testing/logbook/{entry['id']}/whatif", json={"level": "boss"}).status_code == 400

    saved = local.post(f"/testing/logbook/{entry['id']}/feedback",
                       json={"section": "score", "helpful": False, "note": "Experience looks too low"})
    assert saved.json() == {"saved": 1}
    assert local.get(f"/testing/logbook/{entry['id']}").json()["feedback"][0]["helpful"] is False


def test_corrected_profile_is_saved_and_scored_again(local, tmp_path):
    entry = analyse(local, use_llm="true").json()
    local.post(f"/testing/logbook/{entry['id']}/advice")
    fixed = dict(PROFILE, skills=["Python", "SQL", "Power BI", "Excel", "Tableau", "Statistics", "sql"],
                 headline="  ")
    response = local.put(f"/testing/logbook/{entry['id']}/profile", json={"profile": fixed})

    assert response.status_code == 200
    body = response.json()
    assert body["profile"]["skills"].count("SQL") == 1 and "sql" not in body["profile"]["skills"]
    assert "Tableau" in body["profile"]["skills"] and body["profile"]["headline"] is None
    assert body["profile_original"]["skills"] == PROFILE["skills"]  # the first reading is kept
    assert body["advice_stale"] is True
    assert body["assessment"]["score"] >= entry["assessment"]["score"]
    saved = local.get(f"/testing/logbook/{entry['id']}").json()
    assert saved["profile"] == body["profile"] and saved["assessment"]["score"] == body["assessment"]["score"]


@pytest.mark.parametrize("change", [
    {"experience": [{"title": "Analyst", "start": "Jan 2023"}]},
    {"education": [{"level": "Degree"}]},
    {"skills": ["x" * 81]},
    {"skills": [""]},
])
def test_bad_profile_corrections_are_refused(local, change):
    entry = analyse(local).json()
    response = local.put(f"/testing/logbook/{entry['id']}/profile", json={"profile": dict(PROFILE, **change)})
    assert response.status_code == 422


def test_background_task_goes_from_pending_to_completed(local):
    response = local.post("/testing/tasks", files={"file": ("aina.pdf", make_pdf(), "application/pdf")},
                          data={"role_id": "data-analyst", "level": "junior"})
    assert response.status_code == 200
    started = response.json()
    assert started["status"] == "pending"

    task = local.get(f"/testing/tasks/{started['id']}").json()  # the test client runs the task before returning
    assert task["status"] == "completed" and task["error"] is None
    assert task["entry"]["id"] == task["entry_id"]
    assert local.get(f"/testing/logbook/{task['entry_id']}").status_code == 200


def test_background_task_reports_a_failed_file(local):
    started = local.post("/testing/tasks", files={"file": ("notes.txt", b"just text", "text/plain")},
                         data={"role_id": "data-analyst", "level": "junior"}).json()
    task = local.get(f"/testing/tasks/{started['id']}").json()
    assert task["status"] == "failed" and task["error"]
    assert "entry" not in task


def test_unknown_task_is_404(local):
    assert local.get("/testing/tasks/nope").status_code == 404


def test_usage_shows_ai_requests_left_today(local):
    body = local.get("/testing/usage").json()
    assert {"used_today", "daily_limit", "left_today", "monthly_alert"} <= body.keys()
    assert "spent_usd" not in body
