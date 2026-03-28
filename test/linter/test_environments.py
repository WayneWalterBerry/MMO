"""
Tests for --env environment profiles (strict/moderate/permissive).

TDD contract for WAVE-5 environment variant feature.
Bart implements config.ENVIRONMENTS + --env CLI flag; these tests define the spec.

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


def _scaffold(root):
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


def _make_room(room_id, type_ids):
    instances = ", ".join(
        f'{{ id = "inst-{i}", type_id = "{tid}" }}' for i, tid in enumerate(type_ids)
    )
    h = room_id.replace("-", "")[:32].ljust(32, "0")
    guid = f"{{{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}}}"
    return (
        f'return {{ guid = "{guid}", id = "{room_id}", template = "room", '
        f'name = "Room", description = "A room.", on_feel = "Cold.", '
        f'keywords = {{"{room_id}"}}, instances = {{ {instances} }}, exits = {{}} }}'
    )


# Two objects sharing keyword → triggers XF-03
OBJ_A = (
    'return { guid = "{10000000-0000-0000-0000-000000000001}", '
    'id = "stick-a", template = "small-item", name = "a wooden stick", '
    'keywords = {"stick", "twig"}, description = "A stick.", '
    'on_feel = "Rough.", material = "wool" }'
)
OBJ_B = (
    'return { guid = "{10000000-0000-0000-0000-000000000002}", '
    'id = "stick-b", template = "small-item", name = "another stick", '
    'keywords = {"stick", "twig"}, description = "Another stick.", '
    'on_feel = "Smooth.", material = "wool" }'
)

# Object with generic material → triggers XR-05b
GENERIC_TEMPLATE = (
    'return { guid = "00000000-0000-0000-0000-000000000001", '
    'id = "small-item", name = "Small Item", keywords = {}, '
    'description = "test", size = 1, weight = 1, portable = true, '
    'material = "generic", container = false, capacity = 0, contents = {} }'
)
OBJ_GENERIC = (
    'return { guid = "{10000000-0000-0000-0000-000000000003}", '
    'id = "generic-thing", template = "small-item", name = "a thing", '
    'keywords = {"thing"}, description = "Nondescript.", '
    'on_feel = "Smooth.", material = "generic" }'
)


def _run_json(root, extra_flags=None):
    cmd = [sys.executable, str(LINT_PY), str(root / "src" / "meta"),
           "--format", "json", "--no-cache"]
    if extra_flags:
        cmd.extend(extra_flags)
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=str(root))
    return r.returncode, r.stdout, r.stderr


def _parse(stdout):
    return json.loads(stdout)


# ---------------------------------------------------------------------------
# Test 1: --env level-01 (strict) → all rules active
# ---------------------------------------------------------------------------

def test_env_level01_strict_all_rules(tmp_meta_dir):
    """--env level-01 uses strict profile — all rules remain active."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/stick-a.lua", OBJ_A)
    write_file(tmp_meta_dir, "src/meta/objects/stick-b.lua", OBJ_B)
    room = _make_room("testroom", [
        "{10000000-0000-0000-0000-000000000001}",
        "{10000000-0000-0000-0000-000000000002}",
    ])
    write_file(tmp_meta_dir, "src/meta/world/testroom.lua", room)

    rc_base, out_base, _ = _run_json(tmp_meta_dir)
    rc_env, out_env, _ = _run_json(tmp_meta_dir, ["--env", "level-01"])

    base_data = _parse(out_base)
    env_data = _parse(out_env)
    base_rules = {v["rule_id"] for v in base_data["violations"]}
    env_rules = {v["rule_id"] for v in env_data["violations"]}
    assert base_rules == env_rules, (
        f"level-01 (strict) should fire same rules as no --env. "
        f"Missing: {base_rules - env_rules}, Extra: {env_rules - base_rules}")


# ---------------------------------------------------------------------------
# Test 2: --env level-02 (moderate) → skips XF-03
# ---------------------------------------------------------------------------

def test_env_level02_skips_xf03(tmp_meta_dir):
    """--env level-02 uses moderate profile — XF-03 is disabled."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/stick-a.lua", OBJ_A)
    write_file(tmp_meta_dir, "src/meta/objects/stick-b.lua", OBJ_B)
    room = _make_room("testroom", [
        "{10000000-0000-0000-0000-000000000001}",
        "{10000000-0000-0000-0000-000000000002}",
    ])
    write_file(tmp_meta_dir, "src/meta/world/testroom.lua", room)

    # Baseline: XF-03 fires without env
    _, out_base, _ = _run_json(tmp_meta_dir)
    base_xf03 = [v for v in _parse(out_base)["violations"]
                 if v["rule_id"] == "XF-03"]
    assert len(base_xf03) > 0, "Precondition: XF-03 should fire on shared keywords"

    # With --env level-02: XF-03 suppressed
    _, out_env, _ = _run_json(tmp_meta_dir, ["--env", "level-02"])
    env_xf03 = [v for v in _parse(out_env)["violations"]
                if v["rule_id"] == "XF-03"]
    assert len(env_xf03) == 0, (
        f"level-02 (moderate) should suppress XF-03, got {len(env_xf03)}")


# ---------------------------------------------------------------------------
# Test 3: --env sandbox (permissive) → skips S-12, S-13, XR-05
# ---------------------------------------------------------------------------

def test_env_sandbox_skips_permissive_rules(tmp_meta_dir):
    """--env sandbox disables S-12, S-13, and XR-05."""
    write_file(tmp_meta_dir, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(tmp_meta_dir, "src/meta/templates/small-item.lua", GENERIC_TEMPLATE)
    write_file(tmp_meta_dir, "src/meta/objects/generic-thing.lua", OBJ_GENERIC)

    _, out_env, _ = _run_json(tmp_meta_dir, ["--env", "sandbox"])
    violations = _parse(out_env)["violations"]
    disabled = {"S-12", "S-13", "XR-05"}
    found = [v for v in violations if v["rule_id"] in disabled]
    assert len(found) == 0, (
        f"sandbox (permissive) should suppress {disabled}, got: "
        f"{[v['rule_id'] for v in found]}")


# ---------------------------------------------------------------------------
# Test 4: No --env → all rules active (backward compatible)
# ---------------------------------------------------------------------------

def test_no_env_all_rules_active(tmp_meta_dir):
    """Without --env, all rules are active (current default behavior)."""
    write_file(tmp_meta_dir, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(tmp_meta_dir, "src/meta/templates/small-item.lua", GENERIC_TEMPLATE)
    write_file(tmp_meta_dir, "src/meta/objects/generic-thing.lua", OBJ_GENERIC)

    _, out, _ = _run_json(tmp_meta_dir)
    violations = _parse(out)["violations"]
    rule_ids = {v["rule_id"] for v in violations}
    # XR-05b should fire on generic material object (baseline check)
    assert "XR-05b" in rule_ids, (
        f"No --env should keep all rules active; expected XR-05b in {rule_ids}")


# ---------------------------------------------------------------------------
# Test 5: Unknown --env → clear error
# ---------------------------------------------------------------------------

def test_unknown_env_errors(tmp_meta_dir):
    """--env with unknown name should produce a clear error."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/stick-a.lua", OBJ_A)

    rc, stdout, stderr = _run_json(tmp_meta_dir, ["--env", "foobar-99"])
    combined = (stdout + stderr).lower()
    assert rc != 0 or "error" in combined or "unknown" in combined, (
        f"Unknown env should error. RC={rc}\nOUT: {stdout}\nERR: {stderr}")
