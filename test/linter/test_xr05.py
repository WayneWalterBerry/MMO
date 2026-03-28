"""
Tests for XR-05 — generic material detection.

Validates that XR-05 correctly handles template vs object files:
templates with generic material are suppressed (intentional placeholder),
objects with generic material trigger XR-05b WARNING.

References: Issue #196, WAVE-1 implementation plan.
"""

import sys
from pathlib import Path

import pytest

_test_linter_dir = Path(__file__).resolve().parent
if str(_test_linter_dir) not in sys.path:
    sys.path.insert(0, str(_test_linter_dir))

from helpers import write_file, MINIMAL_MATERIAL_WOOL


def _xr05_violations(violations):
    return [v for v in violations if v["rule_id"] == "XR-05"]


def _xr05b_violations(violations):
    return [v for v in violations if v["rule_id"] == "XR-05b"]


# --- Shared scaffolding ---

def _scaffold_with_generic_template(root):
    """Write material + a template that uses generic material."""
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua",
        'return { guid = "00000000-0000-0000-0000-000000000001", '
        'id = "small-item", name = "Small Item", keywords = {}, '
        'description = "test", size = 1, weight = 1, portable = true, '
        'material = "generic", container = false, capacity = 0, contents = {} }')


# ---------------------------------------------------------------------------
# Test 1: Template with material = "generic" → no XR-05 violation
# ---------------------------------------------------------------------------

def test_template_generic_no_violation(tmp_meta_dir, lint_runner):
    """A template file with material = 'generic' should NOT trigger XR-05.
    Templates intentionally use generic as a placeholder for instances."""
    _scaffold_with_generic_template(tmp_meta_dir)

    _, violations = lint_runner()
    xr05 = _xr05_violations(violations)

    assert len(xr05) == 0, (
        f"Template with generic material should be suppressed, "
        f"but got {len(xr05)} XR-05 violations: {xr05}")


# ---------------------------------------------------------------------------
# Test 2: Object with material = "generic" inheriting generic template → XR-05b
# ---------------------------------------------------------------------------

def test_object_generic_fires_warning(tmp_meta_dir, lint_runner):
    """An object inheriting a generic-material template without overriding
    material should trigger XR-05b as WARNING."""
    _scaffold_with_generic_template(tmp_meta_dir)

    write_file(tmp_meta_dir, "src/meta/objects/generic-obj.lua",
        'return { guid = "{10000006-0000-0000-0000-000000000001}", '
        'id = "generic-obj", template = "small-item", name = "generic thing", '
        'keywords = {"thing"}, description = "A generic thing.", '
        'on_feel = "Nondescript.", material = "generic" }')

    _, violations = lint_runner()
    xr05b = _xr05b_violations(violations)

    assert len(xr05b) > 0, (
        "Object with material='generic' inheriting generic template should trigger XR-05b")
    for v in xr05b:
        assert v["severity"] == "warning", (
            f"XR-05b on object should be WARNING, got {v['severity']}")


# ---------------------------------------------------------------------------
# Test 3: Object with real material → no XR-05 or XR-05b violation
# ---------------------------------------------------------------------------

def test_object_real_material_no_violation(tmp_meta_dir, lint_runner):
    """An object file with material = 'wool' should NOT trigger XR-05 or XR-05b.
    Only 'generic' material is flagged."""
    write_file(tmp_meta_dir, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(tmp_meta_dir, "src/meta/templates/small-item.lua",
        'return { guid = "00000000-0000-0000-0000-000000000001", '
        'id = "small-item", name = "Small Item", keywords = {}, '
        'description = "test", size = 1, weight = 1, portable = true, '
        'material = "wool", container = false, capacity = 0, contents = {} }')

    write_file(tmp_meta_dir, "src/meta/objects/wool-cloak.lua",
        'return { guid = "{10000006-0000-0000-0000-000000000002}", '
        'id = "wool-cloak", template = "small-item", name = "a wool cloak", '
        'keywords = {"cloak"}, description = "A warm wool cloak.", '
        'on_feel = "Soft wool.", material = "wool" }')

    _, violations = lint_runner()
    xr05 = _xr05_violations(violations)
    xr05b = _xr05b_violations(violations)

    assert len(xr05) == 0, (
        f"Object with real material 'wool' should not trigger XR-05: {xr05}")
    assert len(xr05b) == 0, (
        f"Object with real material 'wool' should not trigger XR-05b: {xr05b}")
