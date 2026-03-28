"""
Tests for CREATURE-* creature validation rules (CREATURE-001 through CREATURE-020).

These tests define the TDD contract for creature linting. Bart is implementing
the rules in parallel — tests will fail until his code is in place.

References: WAVE-4, plans/linter/linter-improvement-implementation-phase1.md
Fixture dir: test/linter/fixtures/creatures/ (Flanders creating in parallel)
"""

import sys
from pathlib import Path

import pytest

_test_linter_dir = Path(__file__).resolve().parent
if str(_test_linter_dir) not in sys.path:
    sys.path.insert(0, str(_test_linter_dir))

from helpers import write_file, MINIMAL_MATERIAL_WOOL, MINIMAL_TEMPLATE


def _scaffold(root):
    """Write shared material + template scaffolding."""
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


def _creature_violations(violations):
    return [v for v in violations if v["rule_id"].startswith("CREATURE-")]


# ---------------------------------------------------------------------------
# Valid creature Lua — all CREATURE-* rules should pass
# ---------------------------------------------------------------------------

VALID_CREATURE = '''\
return {
    guid = "{30000000-0000-0000-0000-000000000001}",
    template = "creature",
    id = "test-rat",
    name = "a large rat",
    keywords = {"rat", "large rat"},
    description = "A mangy brown rat, almost as big as a cat.",
    on_feel = "Coarse, greasy fur over a bony frame.",
    material = "wool",
    animate = true,
    alive = true,
    health = 10,
    max_health = 10,
    size = "small",
    weight = 2,
    behavior = {
        drives = {
            hunger = { weight = 0.5 },
            fear = { weight = 0.4 },
        },
        states = {
            idle = { description = "The rat sits, nose twitching." },
            fleeing = { description = "The rat scurries away." },
        },
    },
    reactions = {
        hit = { drive_deltas = { fear = 0.3 } },
        feed = { drive_deltas = { hunger = -0.5 } },
    },
    initial_state = "idle",
    _state = "idle",
    states = {
        idle = { description = "The rat sits still." },
        fleeing = { description = "The rat darts between shadows." },
        dead = { description = "The rat lies still.", animate = false, portable = true },
    },
}'''

VALID_CREATURE_WITH_BODY_TREE = VALID_CREATURE.replace(
    '    states = {',
    '    body_tree = {\n'
    '        torso = { hp = 5 },\n'
    '        head = { hp = 3 },\n'
    '    },\n'
    '    states = {'
)


def _make_creature(**replacements):
    """Return VALID_CREATURE with specific lines replaced or removed.

    Pass field=None to remove that line; field="new content" to replace.
    Replacement targets the first line containing '    field = '.
    """
    lines = VALID_CREATURE.split('\n')
    for field, value in replacements.items():
        target = f"    {field} = "
        lines = [l for l in lines if not l.strip().startswith(f"{field} = ")]
        if value is not None:
            # Insert after the 'return {' line
            for i, l in enumerate(lines):
                if l.strip().startswith("return {"):
                    lines.insert(i + 1, f"    {field} = {value},")
                    break
    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_valid_creature_no_violations(tmp_meta_dir, lint_runner):
    """A fully valid creature should produce zero CREATURE-* violations."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/creatures/test-rat.lua", VALID_CREATURE)
    _, violations = lint_runner()
    hits = _creature_violations(violations)
    assert len(hits) == 0, (
        f"Valid creature should have no CREATURE-* violations, got: "
        f"{[(v['rule_id'], v['message']) for v in hits]}")


def test_missing_animate_creature001(tmp_meta_dir, lint_runner):
    """Creature without animate = true triggers CREATURE-001 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace("    animate = true,\n", "")
    write_file(tmp_meta_dir, "src/meta/creatures/no-animate.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-001"]
    assert len(hits) > 0, "Missing animate must trigger CREATURE-001"
    assert all(v["severity"] == "error" for v in hits)


def test_missing_behavior_creature002(tmp_meta_dir, lint_runner):
    """Creature without behavior table triggers CREATURE-002 error."""
    _scaffold(tmp_meta_dir)
    # Remove entire behavior block (multi-line)
    lua = VALID_CREATURE.replace(
        '    behavior = {\n'
        '        drives = {\n'
        '            hunger = { weight = 0.5 },\n'
        '            fear = { weight = 0.4 },\n'
        '        },\n'
        '        states = {\n'
        '            idle = { description = "The rat sits, nose twitching." },\n'
        '            fleeing = { description = "The rat scurries away." },\n'
        '        },\n'
        '    },\n', '')
    write_file(tmp_meta_dir, "src/meta/creatures/no-behavior.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-002"]
    assert len(hits) > 0, "Missing behavior table must trigger CREATURE-002"
    assert all(v["severity"] == "error" for v in hits)


def test_empty_drives_creature003(tmp_meta_dir, lint_runner):
    """Creature with empty drives triggers CREATURE-003 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '        drives = {\n'
        '            hunger = { weight = 0.5 },\n'
        '            fear = { weight = 0.4 },\n'
        '        },',
        '        drives = {},')
    write_file(tmp_meta_dir, "src/meta/creatures/empty-drives.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-003"]
    assert len(hits) > 0, "Empty drives must trigger CREATURE-003"
    assert all(v["severity"] == "error" for v in hits)


def test_no_idle_state_creature004(tmp_meta_dir, lint_runner):
    """Creature behavior.states missing idle key triggers CREATURE-004 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '            idle = { description = "The rat sits, nose twitching." },\n', '')
    write_file(tmp_meta_dir, "src/meta/creatures/no-idle.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-004"]
    assert len(hits) > 0, "Missing idle in behavior.states must trigger CREATURE-004"
    assert all(v["severity"] == "error" for v in hits)


def test_non_numeric_health_creature005(tmp_meta_dir, lint_runner):
    """Creature with non-numeric health triggers CREATURE-005 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace('    health = 10,', '    health = "ten",')
    write_file(tmp_meta_dir, "src/meta/creatures/bad-health.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-005"]
    assert len(hits) > 0, "Non-numeric health must trigger CREATURE-005"
    assert all(v["severity"] == "error" for v in hits)


def test_drive_weight_over_one_creature007(tmp_meta_dir, lint_runner):
    """Drive weight exceeding 1.0 triggers CREATURE-007 warning."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '            hunger = { weight = 0.5 },',
        '            hunger = { weight = 1.5 },')
    write_file(tmp_meta_dir, "src/meta/creatures/high-weight.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-007"]
    assert len(hits) > 0, "Drive weight > 1.0 must trigger CREATURE-007"
    assert all(v["severity"] == "warning" for v in hits)


def test_drive_weights_sum_over_one_creature008(tmp_meta_dir, lint_runner):
    """Drive weights summing over 1.0 triggers CREATURE-008 warning."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '            hunger = { weight = 0.5 },\n'
        '            fear = { weight = 0.4 },',
        '            hunger = { weight = 0.7 },\n'
        '            fear = { weight = 0.6 },')
    write_file(tmp_meta_dir, "src/meta/creatures/sum-over-one.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-008"]
    assert len(hits) > 0, "Drive weights sum > 1.0 must trigger CREATURE-008"
    assert all(v["severity"] == "warning" for v in hits)


def test_missing_reactions_creature009(tmp_meta_dir, lint_runner):
    """Creature without reactions table triggers CREATURE-009 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '    reactions = {\n'
        '        hit = { drive_deltas = { fear = 0.3 } },\n'
        '        feed = { drive_deltas = { hunger = -0.5 } },\n'
        '    },\n', '')
    write_file(tmp_meta_dir, "src/meta/creatures/no-reactions.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-009"]
    assert len(hits) > 0, "Missing reactions must trigger CREATURE-009"
    assert all(v["severity"] == "error" for v in hits)


def test_invalid_size_creature011(tmp_meta_dir, lint_runner):
    """Creature with invalid size string triggers CREATURE-011 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace('    size = "small",', '    size = "enormous",')
    write_file(tmp_meta_dir, "src/meta/creatures/bad-size.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-011"]
    assert len(hits) > 0, "Invalid size enum must trigger CREATURE-011"
    assert all(v["severity"] == "error" for v in hits)


def test_missing_dead_state_creature017(tmp_meta_dir, lint_runner):
    """Creature FSM without dead state triggers CREATURE-017 error."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '        dead = { description = "The rat lies still.", animate = false, portable = true },\n',
        '')
    write_file(tmp_meta_dir, "src/meta/creatures/no-dead-state.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-017"]
    assert len(hits) > 0, "Missing dead FSM state must trigger CREATURE-017"
    assert all(v["severity"] == "error" for v in hits)


def test_dead_state_no_animate_false_creature018(tmp_meta_dir, lint_runner):
    """Dead state without animate = false triggers CREATURE-018 warning."""
    _scaffold(tmp_meta_dir)
    lua = VALID_CREATURE.replace(
        '        dead = { description = "The rat lies still.", animate = false, portable = true },',
        '        dead = { description = "The rat lies still." },')
    write_file(tmp_meta_dir, "src/meta/creatures/dead-no-animate.lua", lua)
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "CREATURE-018"]
    assert len(hits) > 0, "dead state without animate=false must trigger CREATURE-018"
    assert all(v["severity"] == "warning" for v in hits)


def test_valid_creature_with_body_tree(tmp_meta_dir, lint_runner):
    """Valid creature with optional body_tree should produce no CREATURE-* violations."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/creatures/rat-with-body.lua",
               VALID_CREATURE_WITH_BODY_TREE)
    _, violations = lint_runner()
    hits = _creature_violations(violations)
    assert len(hits) == 0, (
        f"Valid creature with body_tree should have no CREATURE-* violations, got: "
        f"{[(v['rule_id'], v['message']) for v in hits]}")
