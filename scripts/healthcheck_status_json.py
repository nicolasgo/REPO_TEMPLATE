#!/usr/bin/env python3
# cell: healthcheck_status_json_py
# Valide un status.json minimal.
# Usage: python scripts/healthcheck_status_json.py path/to/status.json
import sys, json
from pathlib import Path

REQUIRED = ["run_start", "ok"]

def main(p: Path) -> int:
    obj = json.loads(p.read_text(encoding="utf-8"))
    missing = [k for k in REQUIRED if k not in obj]
    if missing:
        print(f"FAIL missing={missing}")
        return 2
    print("OK")
    return 0

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python scripts/healthcheck_status_json.py <status.json>")
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1])))
