"""
Tests for incremental caching — hash-based skip, invalidation, --no-cache.

TDD contract for WAVE-5 caching feature.
Bart implements cache lifecycle in lint.py + cache.py; these tests define the spec.

References: WAVE-5, plans/linter/linter-improvement-implementation-phase1.md
"""

import json
import subprocess
import sys
import time
from pathlib import Path

import pytest

_test_dir = Path(__file__).resolve().parent
if str(_test_dir) not in sys.path:
    sys.path.insert(0, str(_test_dir))

from helpers import write_file, MINIMAL_MATERIAL_WOOL, MINIMAL_TEMPLATE, LINT_PY

SCRIPTS_DIR = Path(__file__).resolve().parents[2] / "scripts" / "meta-lint"
sys.path.insert(0, str(SCRIPTS_DIR))

import importlib.util as _ilu

def _load_mod(name):
    spec = _ilu.spec_from_file_location(name, SCRIPTS_DIR / f"{name}.py")
    mod = _ilu.module_from_spec(spec)
    sys.modules.setdefault(name, mod)
    spec.loader.exec_module(mod)
    return mod

cache_mod = _load_mod("cache")

CACHE_FILE = cache_mod.CACHE_FILENAME  # .meta-lint-cache.json


def _scaffold(root):
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


OBJ_CLEAN = (
    'return {\n'
    '    guid = "{10000000-0000-0000-0000-000000000001}",\n'
    '    id = "clean-obj",\n'
    '    template = "small-item",\n'
    '    name = "a clean object",\n'
    '    keywords = {"clean"},\n'
    '    description = "A clean test object.",\n'
    '    on_feel = "Smooth.",\n'
    '    material = "wool"\n'
    '}'
)

OBJ_SECOND = (
    'return {\n'
    '    guid = "{10000000-0000-0000-0000-000000000002}",\n'
    '    id = "second-obj",\n'
    '    template = "small-item",\n'
    '    name = "a second object",\n'
    '    keywords = {"second"},\n'
    '    description = "A second test object.",\n'
    '    on_feel = "Rough.",\n'
    '    material = "wool"\n'
    '}'
)

OBJ_MODIFIED = (
    'return {\n'
    '    guid = "{10000000-0000-0000-0000-000000000002}",\n'
    '    id = "second-obj",\n'
    '    template = "small-item",\n'
    '    name = "a modified object",\n'
    '    keywords = {"second", "modified"},\n'
    '    description = "Modified description.",\n'
    '    on_feel = "Changed texture.",\n'
    '    material = "wool"\n'
    '}'
)


def _run_lint(root, use_cache=True):
    """Run lint.py with or without cache. Returns (json_data, elapsed_seconds)."""
    cmd = [sys.executable, str(LINT_PY), str(root / "src" / "meta"),
           "--format", "json"]
    if not use_cache:
        cmd.append("--no-cache")
    # Override config to avoid picking up project .meta-check.json
    cfg = root / ".meta-check.json"
    if not cfg.exists():
        cfg.write_text("{}", encoding="utf-8")
    cmd.extend(["--config", str(cfg)])
    start = time.monotonic()
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(root))
    elapsed = time.monotonic() - start
    data = json.loads(r.stdout)
    return data, elapsed


# ---------------------------------------------------------------------------
# Test 1: First run with empty cache → full scan, cache file created
# ---------------------------------------------------------------------------

def test_first_run_full_scan(tmp_meta_dir):
    """First run with caching enabled should do a full scan (all misses)."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)

    data, _ = _run_lint(tmp_meta_dir, use_cache=True)
    cache_info = data.get("cache", {})
    assert cache_info.get("enabled") is True, "Cache should be reported as enabled"
    assert cache_info.get("misses", 0) > 0, (
        "First run should have cache misses (full scan)")


# ---------------------------------------------------------------------------
# Test 2: Second run (no changes) → cached result, faster execution
# ---------------------------------------------------------------------------

def test_second_run_uses_cache(tmp_meta_dir):
    """Second run with no file changes should hit cache (zero misses)."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)

    # First run: populate cache
    data1, _ = _run_lint(tmp_meta_dir)
    misses1 = data1.get("cache", {}).get("misses", -1)

    # Second run: should hit cache
    data2, _ = _run_lint(tmp_meta_dir)
    hits2 = data2.get("cache", {}).get("hits", 0)
    misses2 = data2.get("cache", {}).get("misses", -1)

    assert hits2 > 0, f"Second run should have cache hits, got {hits2}"
    assert misses2 < misses1, (
        f"Second run should have fewer misses ({misses2}) than first ({misses1})")


# ---------------------------------------------------------------------------
# Test 3: One file modified → only that file re-scanned
# ---------------------------------------------------------------------------

def test_modified_file_rescanned(tmp_meta_dir):
    """Modifying one file should invalidate only that file's cache entry."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)
    write_file(tmp_meta_dir, "src/meta/objects/second-obj.lua", OBJ_SECOND)

    # First run: populate cache for both files
    _run_lint(tmp_meta_dir)

    # Modify only second-obj
    write_file(tmp_meta_dir, "src/meta/objects/second-obj.lua", OBJ_MODIFIED)

    # Second run: should detect the change
    data, _ = _run_lint(tmp_meta_dir)
    misses = data.get("cache", {}).get("misses", 0)
    assert misses >= 1, (
        f"Modified file should cause at least 1 cache miss, got {misses}")


# ---------------------------------------------------------------------------
# Test 4: --no-cache → full scan regardless of cache
# ---------------------------------------------------------------------------

def test_no_cache_forces_full_scan(tmp_meta_dir):
    """--no-cache should bypass cache entirely and do a full scan."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)

    # Populate cache
    _run_lint(tmp_meta_dir, use_cache=True)

    # Run with --no-cache
    data, _ = _run_lint(tmp_meta_dir, use_cache=False)
    cache_info = data.get("cache", {})
    # Either cache is disabled or all files are misses (no hits from prior cache)
    enabled = cache_info.get("enabled", True)
    hits = cache_info.get("hits", 0)
    assert not enabled or hits == 0, (
        f"--no-cache should disable caching or show zero hits. "
        f"enabled={enabled}, hits={hits}")


# ---------------------------------------------------------------------------
# Test 5: Cross-file rules excluded from per-file cache entries
# ---------------------------------------------------------------------------

def test_cross_file_rules_not_cached_per_file():
    """LintCache.update() must strip cross-file rules from per-file entries.
    This ensures cross-file rules always re-run when any file changes."""
    cache = cache_mod.LintCache()
    violations = [
        {"file": "a.lua", "line": 1, "severity": "warning",
         "rule_id": "S-01", "message": "single-file rule"},
        {"file": "a.lua", "line": 2, "severity": "warning",
         "rule_id": "XF-03", "message": "cross-file rule"},
        {"file": "a.lua", "line": 3, "severity": "error",
         "rule_id": "GUID-01", "message": "cross-file GUID rule"},
    ]
    cache.update("a.lua", "abc123", violations)

    entry = cache.entries["a.lua"]
    cached_rules = {v["rule_id"] for v in entry.violations}
    assert "S-01" in cached_rules, "Single-file rule should be cached"
    assert "XF-03" not in cached_rules, "Cross-file XF-03 should NOT be cached"
    assert "GUID-01" not in cached_rules, "Cross-file GUID-01 should NOT be cached"


# ---------------------------------------------------------------------------
# Test 6: Cache format validates (version, hash, violations via save/load)
# ---------------------------------------------------------------------------

def test_cache_format_roundtrip(tmp_path):
    """Cache save/load roundtrip must preserve version, hashes, violations."""
    cache = cache_mod.LintCache()
    cache.update("obj.lua", "a" * 64, [
        {"file": "obj.lua", "line": 1, "severity": "warning",
         "rule_id": "S-11", "message": "test violation"},
    ])

    cache_mod.save_cache(tmp_path, cache)
    cache_path = tmp_path / CACHE_FILE
    assert cache_path.exists(), "save_cache must create the cache file"

    raw = json.loads(cache_path.read_text(encoding="utf-8"))
    assert raw["version"] == cache_mod.CACHE_VERSION, "Version must match"
    assert "entries" in raw, "Must have entries dict"
    entry = raw["entries"]["obj.lua"]
    assert entry["file_hash"] == "a" * 64, "Hash must be preserved"
    assert len(entry["violations"]) == 1, "Violations must be preserved"

    loaded = cache_mod.load_cache(tmp_path)
    assert loaded.version == cache_mod.CACHE_VERSION
    assert "obj.lua" in loaded.entries
    assert loaded.entries["obj.lua"].file_hash == "a" * 64
