# cell: core_py
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Mapping


def _now_utc_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


@dataclass(frozen=True)
class Status:
    run_start: str
    run_end: str | None
    ok: bool
    version: str
    contract_version: str
    metrics: Mapping[str, Any]
    error: str | None = None
