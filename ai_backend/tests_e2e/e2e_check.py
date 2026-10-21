"""End-to-end check against the real Supabase project and a running backend (task 1.6)."""

import sys
from pathlib import Path

import httpx

from app.core.config import get_settings

API = "http://localhost:8000"
WEB_ORIGIN = "http://localhost:8080"
ACCOUNTS = Path.home() / ".careerbridge" / "test-accounts.txt"
AREAS = {"job_seeker": "/seeker/home", "recruiter": "/recruiter/home", "admin": "/admin/home"}

results: list[tuple[str, bool, str]] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    results.append((name, ok, detail))
    print(f"  {'PASS' if ok else 'FAIL'}  {name}{'  (' + detail + ')' if detail else ''}")


def load_accounts() -> list[tuple[str, str, str]]:
    rows = []
    for line in ACCOUNTS.read_text(encoding="utf-8").splitlines():
        if line.strip() and not line.startswith("#"):
            role, email, password = line.split("\t")[:3]
            rows.append((role.strip(), email.strip(), password.strip()))
    return rows


def sign_in(email: str, password: str) -> str:
    s = get_settings()
    r = httpx.post(f"{s.supabase_url.rstrip('/')}/auth/v1/token", params={"grant_type": "password"},
                   headers={"apikey": s.supabase_publishable_key}, json={"email": email, "password": password},
                   timeout=20)
    r.raise_for_status()
    return r.json()["access_token"]


def main() -> int:
    client = httpx.Client(base_url=API, timeout=20)
    print("Backend")
    try:
        r = client.get("/health")
        check("GET /health", r.status_code == 200, f"HTTP {r.status_code}")
    except httpx.HTTPError:
        print(f"  Cannot reach {API}. Start it with: fastapi dev app/main.py")
        return 2

    print("Without a valid token")
    for path in ["/me", *AREAS.values()]:
        r = client.get(path)
        check(f"GET {path} without token -> 401", r.status_code == 401, f"HTTP {r.status_code}")

    seen_roles = set()
    for role, email, password in load_accounts():
        label = f"{role} ({email.split('@')[0].split('+')[-1]})"
        print(f"Account: {label}")
        try:
            token = sign_in(email, password)
            check("Supabase login", True)
        except httpx.HTTPError as exc:
            check("Supabase login", False, type(exc).__name__)
            continue
        auth = {"Authorization": f"Bearer {token}"}
        r = client.get("/me", headers=auth)
        got = r.json().get("role") if r.status_code == 200 else None
        check("GET /me returns the right role", got == role, f"HTTP {r.status_code}, role={got}")
        for area_role, path in AREAS.items():
            r = client.get(path, headers=auth)
            want = 200 if area_role == role else 403
            check(f"GET {path} -> {want}", r.status_code == want, f"HTTP {r.status_code}")
        if role not in seen_roles:
            tampered = token[:-4] + ("AAAA" if not token.endswith("AAAA") else "BBBB")
            r = client.get("/me", headers={"Authorization": f"Bearer {tampered}"})
            check("tampered token -> 401", r.status_code == 401, f"HTTP {r.status_code}")
        seen_roles.add(role)

    print("Browser access (CORS)")
    pre = {"Access-Control-Request-Method": "GET", "Access-Control-Request-Headers": "authorization"}
    r = client.options("/me", headers={"Origin": WEB_ORIGIN, **pre})
    check(f"web app origin {WEB_ORIGIN} allowed", r.headers.get("access-control-allow-origin") == WEB_ORIGIN)
    r = client.options("/me", headers={"Origin": "https://evil.example", **pre})
    check("other origins refused", "access-control-allow-origin" not in r.headers)

    failed = [n for n, ok, _ in results if not ok]
    print(f"\n{len(results) - len(failed)} of {len(results)} checks passed" + (f"; failed: {failed}" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
