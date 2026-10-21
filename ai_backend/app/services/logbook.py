"""Local logbook for testing mode: every analysis is kept on this computer, not in Supabase."""

import json
import re
import uuid
from datetime import UTC, datetime
from pathlib import Path

from app.ml.catalog import DATA_DIR

LOGBOOK_DIR = DATA_DIR / "logbook"
_ID = re.compile(r"^[0-9]{8}-[0-9]{6}-[0-9a-f]{6}$")


def new_id() -> str:
    return f"{datetime.now(UTC):%Y%m%d-%H%M%S}-{uuid.uuid4().hex[:6]}"


def save(entry: dict, file_bytes: bytes, file_name: str, folder: Path | None = None) -> None:
    folder = folder or LOGBOOK_DIR
    (folder / "files").mkdir(parents=True, exist_ok=True)
    suffix = Path(file_name).suffix.lower()[:8] if Path(file_name).suffix else ""
    (folder / "files" / f"{entry['id']}{suffix}").write_bytes(file_bytes)
    (folder / f"{entry['id']}.json").write_text(json.dumps(entry, ensure_ascii=False, indent=1), encoding="utf-8")


def update(entry: dict, folder: Path | None = None) -> None:
    """Rewrite an existing entry (e.g. after the AI advice arrives)."""
    path = (folder or LOGBOOK_DIR) / f"{entry['id']}.json"
    path.write_text(json.dumps(entry, ensure_ascii=False, indent=1), encoding="utf-8")


def list_entries(folder: Path | None = None, limit: int = 200) -> list[dict]:
    """Newest first, summary fields only."""
    folder = folder or LOGBOOK_DIR
    out = []
    for path in sorted(folder.glob("*.json"), reverse=True)[:limit]:
        e = json.loads(path.read_text(encoding="utf-8"))
        result = e.get("assessment") or e.get("fit")  # format 1 entries used "fit"
        out.append({"id": e["id"], "created_at": e["created_at"], "file_name": e["file"]["name"],
                    "role": e["role"]["title"], "level": e["level"], "score": result["score"],
                    "label": result["label"], "top_direction": (e["directions"]["items"] or [{}])[0].get("name"),
                    "with_advice": e.get("advice") is not None, "format": e.get("format", 1)})
    return out


def get_entry(entry_id: str, folder: Path | None = None) -> dict | None:
    if not _ID.match(entry_id):  # only ids we created; no path tricks
        return None
    path = (folder or LOGBOOK_DIR) / f"{entry_id}.json"
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None
