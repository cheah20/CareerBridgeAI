"""Read the local role catalogue (data/catalog/roles.json)."""

import json
from functools import lru_cache

from app.ml.catalog import DATA_DIR

CATALOG_FILE = DATA_DIR / "catalog" / "roles.json"


class UnknownRole(LookupError):
    pass


@lru_cache
def load_roles() -> list[dict]:
    if not CATALOG_FILE.exists():
        raise FileNotFoundError("Role catalogue not built. Run: python -m app.catalog.build_roles && python -m app.catalog.build_skills")
    return json.loads(CATALOG_FILE.read_text(encoding="utf-8"))["roles"]


def find_role(name: str) -> dict:
    """Find a role by id, title or alternative name (case-insensitive)."""
    wanted = name.strip().lower()
    for role in load_roles():
        if wanted in {role["id"], role["title"].lower(), *(a.lower() for a in role["aka"])}:
            return role
    close = [r["title"] for r in load_roles() if wanted in r["title"].lower()][:5]
    hint = f" Did you mean: {', '.join(close)}?" if close else ""
    raise UnknownRole(f"Unknown job title: {name}.{hint}")


def fields() -> dict[str, list[str]]:
    """Field -> job titles, for the Job Seeker's selection menu."""
    out: dict[str, list[str]] = {}
    for role in load_roles():
        out.setdefault(role["field"], []).append(role["title"])
    return out
