"""DeepSeek chat client with JSON output, caching, usage logging, budget limits and a daily limit per user."""

import hashlib
import json
import logging
from dataclasses import dataclass
from datetime import UTC, datetime

import httpx

from app.core.config import Settings, get_settings
from app.ml.catalog import DATA_DIR

LLM_DIR = DATA_DIR / "llm"
CACHE_DIR = LLM_DIR / "cache"
USAGE_LOG = LLM_DIR / "usage.jsonl"

logger = logging.getLogger(__name__)

# deepseek-flash reasons before answering; reasoning tokens count against max_tokens.
REASONING_HEADROOM = 1500


class LLMUnavailable(RuntimeError):
    """The LLM cannot be used right now. The message is safe to show users."""


class BudgetExceeded(LLMUnavailable):
    pass


class DailyLimitReached(LLMUnavailable):
    pass


@dataclass(frozen=True)
class LLMReply:
    data: dict
    cached: bool
    cost_usd: float


def month_spend(now: datetime | None = None) -> float:
    if not USAGE_LOG.exists():
        return 0.0
    month = (now or datetime.now(UTC)).strftime("%Y-%m")
    total = 0.0
    for line in USAGE_LOG.read_text(encoding="utf-8").splitlines():
        entry = json.loads(line)
        if entry["timestamp"].startswith(month):
            total += entry.get("cost_usd", 0.0)
    return round(total, 6)


def budget_status(settings: Settings | None = None) -> dict:
    s = settings or get_settings()
    spent = month_spend()
    share = spent / s.llm_monthly_budget_usd if s.llm_monthly_budget_usd else 1.0
    return {"spent_usd": spent, "budget_usd": s.llm_monthly_budget_usd, "used": round(share, 4),
            "alert": share >= 0.8, "limited": share >= 1.0}


def requests_today(user_id: str, now: datetime | None = None) -> int:
    """AI requests this user sent today (UTC). Cache hits and blocked requests are not counted."""
    if not USAGE_LOG.exists():
        return 0
    day = (now or datetime.now(UTC)).strftime("%Y-%m-%d")
    count = 0
    for line in USAGE_LOG.read_text(encoding="utf-8").splitlines():
        entry = json.loads(line)
        if entry.get("user") == user_id and entry["timestamp"].startswith(day) and entry["status"] in ("ok", "error"):
            count += 1
    return count


def user_status(user_id: str, settings: Settings | None = None) -> dict:
    s = settings or get_settings()
    used = requests_today(user_id)
    return {"used_today": used, "daily_limit": s.llm_daily_requests_per_user,
            "left_today": max(s.llm_daily_requests_per_user - used, 0)}


def _log(entry: dict) -> None:
    LLM_DIR.mkdir(parents=True, exist_ok=True)
    with USAGE_LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def chat_json(
    messages: list[dict],
    *,
    purpose: str,
    essential: bool = False,
    max_tokens: int = 2500,
    temperature: float = 0.3,
    thinking: bool = True,
    user_id: str | None = None,
    settings: Settings | None = None,
) -> LLMReply:
    """Send a chat request that must return a JSON object. The prompt must mention JSON.

    user_id: who asked, for the daily limit. None means a developer tool (no daily limit).
    """
    s = settings or get_settings()
    if not s.deepseek_api_key:
        raise LLMUnavailable("AI explanations are not configured on this server.")

    payload = {
        "model": s.deepseek_model,
        "messages": messages,
        "response_format": {"type": "json_object"},
        "max_tokens": max_tokens + (REASONING_HEADROOM if thinking else 0),
        "temperature": temperature,
    }
    if not thinking:  # plain extraction work: no reasoning step, much faster
        payload["thinking"] = {"type": "disabled"}
    key = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
    cache_file = CACHE_DIR / f"{key}.json"
    if cache_file.exists():
        _log({"timestamp": datetime.now(UTC).isoformat(timespec="seconds"), "purpose": purpose, "model": s.deepseek_model,
              "user": user_id, "status": "cache_hit", "cost_usd": 0.0})
        return LLMReply(json.loads(cache_file.read_text(encoding="utf-8")), cached=True, cost_usd=0.0)

    if user_id is not None and requests_today(user_id) >= s.llm_daily_requests_per_user:
        _log({"timestamp": datetime.now(UTC).isoformat(timespec="seconds"), "purpose": purpose, "model": s.deepseek_model,
              "user": user_id, "status": "blocked_daily", "cost_usd": 0.0})
        raise DailyLimitReached("You have used today's AI requests. They reset tomorrow, and your score still works without them.")

    status = budget_status(s)
    if status["limited"] and not essential:
        _log({"timestamp": datetime.now(UTC).isoformat(timespec="seconds"), "purpose": purpose, "model": s.deepseek_model,
              "user": user_id, "status": "blocked_budget", "cost_usd": 0.0})
        raise BudgetExceeded("The monthly AI budget has been reached. AI explanations will return next month.")
    if status["alert"]:
        logger.warning("LLM budget alert: %.0f%% of USD %.2f used", status["used"] * 100, status["budget_usd"])

    entry = {"timestamp": datetime.now(UTC).isoformat(timespec="seconds"), "purpose": purpose, "model": s.deepseek_model,
             "user": user_id}
    usage_total: dict[str, int] = {}
    data = None
    request = dict(payload)
    for attempt in range(2):  # one retry: empty/invalid JSON or the token limit ran out while reasoning
        try:
            response = httpx.post(
                f"{s.deepseek_base_url.rstrip('/')}/chat/completions",
                headers={"Authorization": f"Bearer {s.deepseek_api_key}"},
                json=request,
                timeout=180,
            )
            response.raise_for_status()
            body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            _log({**entry, "status": "error", "error": type(exc).__name__, "cost_usd": 0.0})
            raise LLMUnavailable("The AI service is not responding right now. Please try again later.") from exc
        for k, v in body.get("usage", {}).items():
            if isinstance(v, int):
                usage_total[k] = usage_total.get(k, 0) + v
        usage_total["reasoning_tokens"] = usage_total.get("reasoning_tokens", 0) + (
            body.get("usage", {}).get("completion_tokens_details", {}).get("reasoning_tokens", 0))
        choice = body["choices"][0]
        try:
            data = json.loads(choice["message"].get("content") or "")
            break
        except json.JSONDecodeError:
            if choice.get("finish_reason") == "length":
                request["max_tokens"] = request["max_tokens"] * 2
    if data is None:
        _log({**entry, "status": "error", "error": "empty_or_invalid_json", "cost_usd": 0.0})
        raise LLMUnavailable("The AI service returned an incomplete answer. Please try again.")

    usage = usage_total
    hit = usage.get("prompt_cache_hit_tokens", 0)
    miss = usage.get("prompt_cache_miss_tokens", usage.get("prompt_tokens", 0) - hit)
    out = usage.get("completion_tokens", 0)
    cost = (hit * s.llm_price_input_hit + miss * s.llm_price_input_miss + out * s.llm_price_output) / 1_000_000
    _log({**entry, "status": "ok", "prompt_tokens": usage.get("prompt_tokens", 0), "cache_hit_tokens": hit,
          "completion_tokens": out, "reasoning_tokens": usage.get("reasoning_tokens", 0), "cost_usd": round(cost, 6)})

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(data), encoding="utf-8")
    return LLMReply(data, cached=False, cost_usd=round(cost, 6))
