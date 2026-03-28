"""
Tests for squad routing — rule-to-owner mapping and --by-owner output.

TDD contract for WAVE-5 routing enhancements.
Bart updates routing table + JSON owner field; these tests define the spec.

References: WAVE-5, plans/linter/linter-improvement-implementation-phase1.md
"""

import json
import subprocess
import sys
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

squad_routing_mod = _load_mod("squad_routing")


# ---------------------------------------------------------------------------
# Test 1: S-01 routes to "Smithers"
# ---------------------------------------------------------------------------

def test_s01_routes_to_smithers():
    """S-01 (structure rule) should route to Smithers."""
    router = squad_routing_mod.SquadRouter()
    assert router.owner_for("S-01") == "Smithers", (
        f"S-01 should route to Smithers, got '{router.owner_for('S-01')}'")


# ---------------------------------------------------------------------------
# Test 2: CREATURE-001 routes to "Flanders"
# ---------------------------------------------------------------------------

def test_creature001_routes_to_flanders():
    """CREATURE-001 should route to Flanders."""
    router = squad_routing_mod.SquadRouter()
    assert router.owner_for("CREATURE-001") == "Flanders", (
        f"CREATURE-001 should route to Flanders, got '{router.owner_for('CREATURE-001')}'")


# ---------------------------------------------------------------------------
# Test 3: EXIT-01 routes to "Sideshow Bob"
# ---------------------------------------------------------------------------

def test_exit01_routes_to_sideshow_bob():
    """EXIT-01 should route to Sideshow Bob."""
    router = squad_routing_mod.SquadRouter()
    assert router.owner_for("EXIT-01") == "Sideshow Bob", (
        f"EXIT-01 should route to Sideshow Bob, got '{router.owner_for('EXIT-01')}'")


# ---------------------------------------------------------------------------
# Test 4: JSON output includes "owner" field
# ---------------------------------------------------------------------------

def _scaffold(root):
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


OBJ_BAD_GUID = (
    'return {\n'
    '    guid = "not-a-valid-guid",\n'
    '    id = "bad-obj",\n'
    '    template = "small-item",\n'
    '    name = "a bad object",\n'
    '    keywords = {"bad"},\n'
    '    description = "Broken GUID.",\n'
    '    on_feel = "Rough.",\n'
    '    material = "wool"\n'
    '}'
)


def test_json_includes_owner_field(tmp_meta_dir):
    """JSON violations must contain an 'owner' field for squad routing."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/bad-obj.lua", OBJ_BAD_GUID)

    cmd = [sys.executable, str(LINT_PY),
           str(tmp_meta_dir / "src" / "meta"),
           "--format", "json", "--no-cache"]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(tmp_meta_dir))
    data = json.loads(r.stdout)
    violations = data.get("violations", [])
    assert len(violations) > 0, "Precondition: need at least one violation"
    for v in violations:
        assert "owner" in v, f"Violation missing 'owner' field: {v}"
        assert isinstance(v["owner"], str) and len(v["owner"]) > 0, (
            f"owner must be a non-empty string, got: {v['owner']!r}")


# ---------------------------------------------------------------------------
# Test 5: --by-owner groups violations by agent name
# ---------------------------------------------------------------------------

def test_by_owner_groups_output(tmp_meta_dir):
    """--by-owner flag should group text output under === Owner === headers."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/bad-obj.lua", OBJ_BAD_GUID)

    cmd = [sys.executable, str(LINT_PY),
           str(tmp_meta_dir / "src" / "meta"),
           "--no-cache", "--by-owner"]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(tmp_meta_dir))
    stdout = r.stdout
    # --by-owner should produce section headers like "=== Bart (N violations) ==="
    assert "===" in stdout, (
        f"--by-owner should produce === Owner === section headers.\n"
        f"STDOUT:\n{stdout}")
    assert "violations)" in stdout.lower(), (
        f"--by-owner headers should contain violation counts.\n"
        f"STDOUT:\n{stdout}")
