"""
Tests for --fix and --unsafe-fixes CLI flags.

Validates the fix-mode CLI contract: --fix applies safe-only,
--unsafe-fixes applies all, --fix + --format json is rejected,
and normal mode shows no fix tags.

References: WAVE-3, D-LINTER-FIX-AUDIT.
"""

import subprocess
import sys
from pathlib import Path

import pytest

_test_dir = Path(__file__).resolve().parent
if str(_test_dir) not in sys.path:
    sys.path.insert(0, str(_test_dir))

from helpers import write_file, MINIMAL_MATERIAL_WOOL, MINIMAL_TEMPLATE, LINT_PY


def _scaffold(root):
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


# Object triggers G-01 (safe: invalid GUID) and S-11 (unsafe: missing description)
FIXTURE_MIXED = (
    'return {\n'
    '    guid = "not-a-valid-guid",\n'
    '    id = "fix-target",\n'
    '    template = "small-item",\n'
    '    name = "a test object",\n'
    '    keywords = {"test"},\n'
    '    on_feel = "Smooth.",\n'
    '    material = "wool"\n'
    '}'
)


def _run_text(root, extra_flags=None):
    """Run lint.py in text mode, return (returncode, stdout, stderr)."""
    cmd = [sys.executable, str(LINT_PY),
           str(root / "src" / "meta"), "--no-cache"]
    if extra_flags:
        cmd.extend(extra_flags)
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(root))
    return r.returncode, r.stdout, r.stderr


# ---------------------------------------------------------------------------

def test_fix_shows_safe_tag(tmp_meta_dir):
    """--fix output should contain [FIXABLE-SAFE] for safe violations."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/fix-target.lua", FIXTURE_MIXED)
    _, stdout, _ = _run_text(tmp_meta_dir, ["--fix"])
    assert "[FIXABLE-SAFE]" in stdout, (
        f"--fix should tag safe fixes\nSTDOUT:\n{stdout}")


def test_fix_hides_unsafe_tag(tmp_meta_dir):
    """--fix should NOT show [FIXABLE-UNSAFE] (safe-only mode)."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/fix-target.lua", FIXTURE_MIXED)
    _, stdout, _ = _run_text(tmp_meta_dir, ["--fix"])
    assert "[FIXABLE-UNSAFE]" not in stdout, (
        f"--fix must not show unsafe tags\nSTDOUT:\n{stdout}")


def test_unsafe_fixes_shows_both_tags(tmp_meta_dir):
    """--unsafe-fixes should show both [FIXABLE-SAFE] and [FIXABLE-UNSAFE]."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/fix-target.lua", FIXTURE_MIXED)
    _, stdout, _ = _run_text(tmp_meta_dir, ["--unsafe-fixes"])
    assert "[FIXABLE-SAFE]" in stdout, (
        f"--unsafe-fixes should include safe tags\nSTDOUT:\n{stdout}")
    assert "[FIXABLE-UNSAFE]" in stdout, (
        f"--unsafe-fixes should include unsafe tags\nSTDOUT:\n{stdout}")


def test_fix_with_json_format_errors(tmp_meta_dir):
    """--fix combined with --format json must fail or warn incompatibility."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/fix-target.lua", FIXTURE_MIXED)
    rc, stdout, stderr = _run_text(tmp_meta_dir, ["--fix", "--format", "json"])
    combined = (stdout + stderr).lower()
    assert rc != 0 or "incompatible" in combined or "cannot" in combined, (
        f"--fix --format json should be rejected\n"
        f"RC={rc}\nOUT:\n{stdout}\nERR:\n{stderr}")


def test_no_flags_no_fix_tags(tmp_meta_dir):
    """Normal mode (no --fix/--unsafe-fixes) should not emit [FIXABLE tags."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/fix-target.lua", FIXTURE_MIXED)
    _, stdout, _ = _run_text(tmp_meta_dir)
    assert "[FIXABLE" not in stdout, (
        f"Normal output must not contain [FIXABLE tags\nSTDOUT:\n{stdout}")
