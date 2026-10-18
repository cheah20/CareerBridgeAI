"""LLM safety: personal details are removed, usage is logged, duplicate calls are cached,
and the monthly budget is enforced. No real API calls are made."""

import json

import httpx
import pytest

from app.core.config import Settings
from app.llm import client
from app.llm.redact import redact_personal_info


def test_redaction_removes_contact_details_and_ids():
    resume = """AINA BINTI RAHMAN
No 12, Jalan Merdeka, 75000 Melaka
aina.rahman@example.com | +60 12-345 6789 | linkedin.com/in/aina
IC No: 990101-04-5678
Date of birth: 1 Jan 1999
SKILLS
SQL, Python, Power BI
Data Analyst, Retail Group, 2024 - Present"""
    out = redact_personal_info(resume)
    for secret in ["AINA", "Jalan Merdeka", "gmail", "345 6789", "990101", "1 Jan 1999", "linkedin.com/in/aina"]:
        assert secret not in out
    # Content needed for advice stays.
    for kept in ["SQL, Python, Power BI", "Data Analyst, Retail Group, 2024 - Present"]:
        assert kept in out


def test_known_names_are_removed_anywhere():
    out = redact_personal_info("Summary\nLim Wei Jie is a data analyst.", known_names=["Lim Wei Jie"])
    assert "Lim Wei Jie" not in out


@pytest.fixture
def llm(tmp_path, monkeypatch):
    monkeypatch.setattr(client, "LLM_DIR", tmp_path)
    monkeypatch.setattr(client, "CACHE_DIR", tmp_path / "cache")
    monkeypatch.setattr(client, "USAGE_LOG", tmp_path / "usage.jsonl")
    calls = []

    def fake_post(url, headers, json, timeout):
        calls.append(json)
        body = {"choices": [{"message": {"content": '{"summary": "ok"}'}}],
                "usage": {"prompt_tokens": 1000, "prompt_cache_hit_tokens": 0, "prompt_cache_miss_tokens": 1000,
                          "completion_tokens": 500}}
        return httpx.Response(200, json=body, request=httpx.Request("POST", url))

    monkeypatch.setattr(client.httpx, "post", fake_post)
    settings = Settings(supabase_url="https://x.supabase.co", supabase_publishable_key="k",
                        deepseek_api_key="sk-test", llm_monthly_budget_usd=1.0)
    return settings, calls


MESSAGES = [{"role": "user", "content": "Reply in json"}]


def test_reply_cost_is_logged(llm):
    settings, _ = llm
    reply = client.chat_json(MESSAGES, purpose="test", settings=settings)
    assert reply.data == {"summary": "ok"}
    assert reply.cost_usd == pytest.approx((1000 * 0.30 + 500 * 1.20) / 1e6)
    entry = json.loads(client.USAGE_LOG.read_text().splitlines()[0])
    assert entry["status"] == "ok" and entry["completion_tokens"] == 500


def test_identical_requests_are_served_from_cache(llm):
    settings, calls = llm
    client.chat_json(MESSAGES, purpose="test", settings=settings)
    second = client.chat_json(MESSAGES, purpose="test", settings=settings)
    assert second.cached and second.cost_usd == 0
    assert len(calls) == 1


def test_budget_limit_blocks_non_essential_requests(llm):
    settings, calls = llm
    client.USAGE_LOG.write_text(json.dumps({"timestamp": client.datetime.now(client.UTC).isoformat(), "cost_usd": 1.5}) + "\n")
    with pytest.raises(client.BudgetExceeded):
        client.chat_json(MESSAGES, purpose="test", settings=settings)
    assert calls == []
    assert client.chat_json(MESSAGES, purpose="test", settings=settings, essential=True).data == {"summary": "ok"}


def test_missing_key_gives_a_clear_message():
    settings = Settings(supabase_url="https://x.supabase.co", supabase_publishable_key="k", deepseek_api_key="")
    with pytest.raises(client.LLMUnavailable, match="not configured"):
        client.chat_json(MESSAGES, purpose="test", settings=settings)
