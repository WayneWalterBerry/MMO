"""Tests for MD-19 removal — dual thermal properties no longer flagged (#195)."""

import shutil
import sys
from pathlib import Path

_test_linter_dir = Path(__file__).resolve().parent
if str(_test_linter_dir) not in sys.path:
    sys.path.insert(0, str(_test_linter_dir))

from helpers import assert_no_violation, assert_violation

FIXTURES = _test_linter_dir / "fixtures"


def _stage_material(tmp_meta_dir, fixture_name):
    """Copy a fixture into the tmp materials dir and return the root."""
    src = FIXTURES / f"{fixture_name}.lua"
    dst = tmp_meta_dir / "src" / "meta" / "materials" / f"{fixture_name}.lua"
    shutil.copy2(src, dst)
    return tmp_meta_dir


def test_both_thermal_no_md19(tmp_meta_dir, lint_runner):
    """Material with both melting_point and ignition_point → no MD-19."""
    _stage_material(tmp_meta_dir, "material-both-thermal")
    _, violations = lint_runner(target="src/meta/materials/")
    output = {"violations": violations}
    assert_no_violation(output, "MD-19", "MD-19 should be removed — dual thermal is valid")


def test_melting_only_no_md19(tmp_meta_dir, lint_runner):
    """Material with only melting_point → no MD-19."""
    _stage_material(tmp_meta_dir, "material-melting-only")
    _, violations = lint_runner(target="src/meta/materials/")
    output = {"violations": violations}
    assert_no_violation(output, "MD-19", "MD-19 should not fire for melting-only materials")


def test_other_md_rules_still_fire(tmp_meta_dir, lint_runner):
    """Regression: other MD-* rules (e.g., MD-02 missing name) still work."""
    _stage_material(tmp_meta_dir, "material-no-name")
    _, violations = lint_runner(target="src/meta/materials/")
    output = {"violations": violations}
    assert_violation(output, "MD-02", "MD-02 (missing name) should still fire after MD-19 removal")
