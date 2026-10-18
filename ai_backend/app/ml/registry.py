"""Model versions: which models exist, how they scored, which one is deployed.

Stored as models/registry.json so versions can be compared and rolled back
(requirements §14). Model files themselves stay local.
"""

import json
from typing import Any

from app.ml.catalog import MODELS_DIR, REGISTRY_FILE


def load() -> dict[str, Any]:
    if REGISTRY_FILE.exists():
        return json.loads(REGISTRY_FILE.read_text(encoding="utf-8"))
    return {"deployed": None, "versions": []}


def save(registry: dict[str, Any]) -> None:
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    REGISTRY_FILE.write_text(json.dumps(registry, indent=2), encoding="utf-8")


def next_version(registry: dict[str, Any]) -> str:
    return f"v{len(registry['versions']) + 1}"


def deployed_entry(registry: dict[str, Any]) -> dict[str, Any] | None:
    return next((v for v in registry["versions"] if v["version"] == registry["deployed"]), None)


def set_deployed(registry: dict[str, Any], version: str) -> None:
    """Deploy one version; the previous one stays available for rollback."""
    if not any(v["version"] == version for v in registry["versions"]):
        raise ValueError(f"Unknown model version: {version}")
    for entry in registry["versions"]:
        if entry["version"] == version:
            entry["status"] = "deployed"
        elif entry["status"] == "deployed":
            entry["status"] = "previous"
    registry["deployed"] = version
