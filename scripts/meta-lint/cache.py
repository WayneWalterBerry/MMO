"""
Incremental Analysis Cache for meta-check.

Hashes each .lua file (SHA-256) and caches per-file violations.
On re-run, unchanged files skip single-file validation.

Cross-file rules (XF-*, XR-*, GUID-*, EXIT-*, LV-40) always re-run
because any file change can alter cross-file results.

Specific cross-file rules (EXIT-03, CREATURE-019, CREATURE-020) are
also invalidated when any file changes.

Cache file: .meta-lint-cache.json in project root.
"""

from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set

CROSS_FILE_RULE_PREFIXES = frozenset({
    "XF-", "XR-", "GUID-", "EXIT-", "LV-40",
})

CROSS_FILE_EXACT_RULES = frozenset({
    "EXIT-03", "CREATURE-019", "CREATURE-020",
})

CACHE_VERSION = 2
CACHE_FILENAME = ".meta-lint-cache.json"


def _hash_file(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()


def is_cross_file_rule(rule_id: str) -> bool:
    if rule_id in CROSS_FILE_EXACT_RULES:
        return True
    return any(rule_id.startswith(prefix) for prefix in CROSS_FILE_RULE_PREFIXES)


@dataclass
class CacheEntry:
    file_hash: str
    violations: List[dict]
    timestamp: str = ""


@dataclass
class LintCache:
    version: int = CACHE_VERSION
    entries: Dict[str, CacheEntry] = field(default_factory=dict)

    def get_cached(self, file_path: str, current_hash: str) -> Optional[List[dict]]:
        entry = self.entries.get(file_path)
        if entry and entry.file_hash == current_hash:
            return entry.violations
        return None

    def update(self, file_path: str, file_hash: str, violations: List[dict]) -> None:
        single_file = [v for v in violations if not is_cross_file_rule(v.get("rule_id", ""))]
        ts = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        self.entries[file_path] = CacheEntry(
            file_hash=file_hash, violations=single_file, timestamp=ts,
        )

    def invalidate(self, file_path: str) -> None:
        self.entries.pop(file_path, None)

    def prune(self, valid_paths: Set[str]) -> None:
        stale = [k for k in self.entries if k not in valid_paths]
        for k in stale:
            del self.entries[k]


def load_cache(project_root: Path) -> LintCache:
    cache_path = project_root / CACHE_FILENAME
    if not cache_path.exists():
        return LintCache()
    try:
        data = json.loads(cache_path.read_text(encoding="utf-8"))
        if data.get("version") != CACHE_VERSION:
            return LintCache()
        entries = {}
        for file_path, entry_data in data.get("entries", {}).items():
            entries[file_path] = CacheEntry(
                file_hash=entry_data["file_hash"],
                violations=entry_data["violations"],
                timestamp=entry_data.get("timestamp", ""),
            )
        return LintCache(version=CACHE_VERSION, entries=entries)
    except (json.JSONDecodeError, KeyError, TypeError):
        return LintCache()


def save_cache(project_root: Path, cache: LintCache) -> None:
    cache_path = project_root / CACHE_FILENAME
    data = {
        "version": cache.version,
        "entries": {
            fp: {
                "file_hash": e.file_hash,
                "violations": e.violations,
                "timestamp": e.timestamp,
            }
            for fp, e in cache.entries.items()
        },
    }
    cache_path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def hash_file(path: Path) -> str:
    return _hash_file(path)
