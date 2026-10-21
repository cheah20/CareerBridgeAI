"""Manage model versions: list, deploy, roll back."""

import argparse
import json
from datetime import UTC, datetime

from app.ml import registry
from app.ml.catalog import MODELS_DIR

AUDIT_LOG = MODELS_DIR / "deployments.jsonl"


def _audit(action: str, version: str, previous: str | None) -> None:
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    with AUDIT_LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"timestamp": datetime.now(UTC).isoformat(timespec="seconds"),
                            "action": action, "version": version, "previous": previous}) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("list")
    deploy = sub.add_parser("deploy")
    deploy.add_argument("version")
    sub.add_parser("rollback")
    args = parser.parse_args()

    reg = registry.load()
    if args.command == "list":
        print(f"{'version':8} {'status':10} {'algorithm':20} {'F1':>6} {'acc':>6} {'top-3':>6}  dataset")
        for v in reg["versions"]:
            m = v["metrics"]
            print(f"{v['version']:8} {v['status']:10} {v['algorithm']:20} {m['f1_macro']:6.3f} {m['accuracy']:6.3f} "
                  f"{m.get('top3_accuracy', float('nan')):6.3f}  {v['dataset']['name']}")
        return 0

    previous = reg["deployed"]
    if args.command == "deploy":
        target = args.version
    else:
        earlier = [v["version"] for v in reg["versions"] if v["status"] == "previous"]
        if not earlier:
            print("Nothing to roll back to.")
            return 1
        target = earlier[-1]
    registry.set_deployed(reg, target)
    registry.save(reg)
    _audit(args.command, target, previous)
    print(f"{args.command}: {previous} → {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
