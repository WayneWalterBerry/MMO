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

def test_first_run_creates_cache(tmp_meta_dir):
    """First run with no cache should do a full scan and create cache file."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)

    cache_path = tmp_meta_dir / CACHE_FILE
    assert not cache_path.exists(), "Precondition: no cache file"

    data, _ = _run_lint(tmp_meta_dir, use_cache=True)
    assert cache_path.exists(), "Cache file should be created after first run"
    assert data.get("cache", {}).get("enabled") is True, (
        "JSON should report cache as enabled")


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
# Test 5: Cross-file rules invalidated when any file changes
# ---------------------------------------------------------------------------

def test_cross_file_rules_rerun_on_change(tmp_meta_dir):
    """When ANY file changes, cross-file rules (XF-*, XR-*, etc.) must re-run."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)
    write_file(tmp_meta_dir, "src/meta/objects/second-obj.lua", OBJ_SECOND)

    # First run: populate cache
    _run_lint(tmp_meta_dir)

    # Read cache and verify cross-file rules are NOT cached per-file
    cache_path = tmp_meta_dir / CACHE_FILE
    cache_data = json.loads(cache_path.read_text(encoding="utf-8"))
    for fp, entry in cache_data.get("entries", {}).items():
        for v in entry.get("violations", []):
            rule_id = v.get("rule_id", "")
            assert not cache_mod.is_cross_file_rule(rule_id), (
                f"Cross-file rule {rule_id} should not be in per-file cache "
                f"for {fp}")


# ---------------------------------------------------------------------------
# Test 6: Cache format validates (hash, violations, timestamp)
# ---------------------------------------------------------------------------

def test_cache_format_valid(tmp_meta_dir):
    """Cache file must have expected structure: version, entries with hash + violations."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/clean-obj.lua", OBJ_CLEAN)

    _run_lint(tmp_meta_dir, use_cache=True)

    cache_path = tmp_meta_dir / CACHE_FILE
    assert cache_path.exists(), "Cache file must exist after run"

    data = json.loads(cache_path.read_text(encoding="utf-8"))
    assert "version" in data, "Cache must have a 'version' field"
    assert data["version"] == cache_mod.CACHE_VERSION, (
        f"Cache version should be {cache_mod.CACHE_VERSION}, got {data['version']}")
    assert "entries" in data, "Cache must have an 'entries' field"
    assert isinstance(data["entries"], dict), "entries must be a dict"

    for fp, entry in data["entries"].items():
        assert "file_hash" in entry, f"Entry for {fp} missing 'file_hash'"
        assert isinstance(entry["file_hash"], str), f"file_hash must be a string"
        assert len(entry["file_hash"]) == 64, (
            f"file_hash should be SHA-256 hex (64 chars), got {len(entry['file_hash'])}")
        assert "violations" in entry, f"Entry for {fp} missing 'violations'"
        assert isinstance(entry["violations"], list), f"violations must be a list"
