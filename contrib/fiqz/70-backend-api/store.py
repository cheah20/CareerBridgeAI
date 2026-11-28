import json
from pathlib import Path

FILE = Path(__file__).parent / "sample_data.json"


def load() -> dict:
    return json.loads(FILE.read_text(encoding="utf-8"))


def save(data: dict) -> None:
    FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
