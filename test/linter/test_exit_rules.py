"""
Tests for EXIT-* portal validation rules (EXIT-01 through EXIT-07).

Validates portal metadata, bidirectional pairing, direction consistency,
inline state detection, and darkness sensory requirements.

References: WAVE-4, plans/linter/linter-improvement-implementation-phase1.md
Fixtures: test/linter/fixtures/portals/ (created by Sideshow Bob)
"""

import sys
from pathlib import Path

import pytest

_test_linter_dir = Path(__file__).resolve().parent
if str(_test_linter_dir) not in sys.path:
    sys.path.insert(0, str(_test_linter_dir))

from helpers import write_file, MINIMAL_MATERIAL_WOOL, MINIMAL_TEMPLATE

FIXTURES_DIR = _test_linter_dir / "fixtures" / "portals"


def _scaffold(root):
    """Write shared material + template files so OBJ-level rules don't drown EXIT-* checks."""
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


def _load_fixture(name):
    """Read a portal fixture from fixtures/portals/."""
    return (FIXTURES_DIR / name).read_text(encoding="utf-8")


def _exit_violations(violations):
    return [v for v in violations if v["rule_id"].startswith("EXIT-0")]


# Bidirectional partner for valid-portal.lua so EXIT-03 doesn't fire
PARTNER_PORTAL = (
    'return {\n'
    '    guid = "{00000000-0000-0000-0000-000000000002}",\n'
    '    template = "portal",\n'
    '    id = "test-valid-portal-partner",\n'
    '    name = "a test door (south side)",\n'
    '    keywords = {"door", "south door"},\n'
    '    size = 6, weight = 100, portable = false,\n'
    '    portal = {\n'
    '        target = "test-room-south",\n'
    '        bidirectional_id = "{00000000-0000-0000-0000-000000000002}",\n'
    '        direction_hint = "south",\n'
    '    },\n'
    '    description = "The south side of the test door.",\n'
    '    on_feel = "Solid wood under your hand.",\n'
    '    initial_state = "closed", _state = "closed",\n'
    '    states = {\n'
    '        closed = { traversable = false, name = "closed", description = "Closed." },\n'
    '        open = { traversable = true, name = "open", description = "Open." },\n'
    '    },\n'
    '}'
)


def test_valid_portal_no_exit_violations(tmp_meta_dir, lint_runner):
    """Fully valid portal pair should produce zero EXIT-* violations."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/valid-portal.lua",
               _load_fixture("valid-portal.lua"))
    write_file(tmp_meta_dir, "src/meta/objects/valid-portal-partner.lua",
               PARTNER_PORTAL)
    _, violations = lint_runner()
    evs = _exit_violations(violations)
    assert len(evs) == 0, (
        f"Valid portal pair should produce no EXIT-* violations, got: "
        f"{[(v['rule_id'], v['message']) for v in evs]}")


def test_missing_target_exit01(tmp_meta_dir, lint_runner):
    """Portal without portal.target triggers EXIT-01 error."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/missing-target.lua",
               _load_fixture("missing-target.lua"))
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "EXIT-01"]
    assert len(hits) > 0, "Missing portal.target must trigger EXIT-01"
    assert all(v["severity"] == "error" for v in hits)


def test_missing_traversable_exit02(tmp_meta_dir, lint_runner):
    """Portal FSM states without traversable declaration triggers EXIT-02 error."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/missing-traversable.lua",
               _load_fixture("missing-traversable.lua"))
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "EXIT-02"]
    assert len(hits) > 0, "Missing traversable in FSM states must trigger EXIT-02"
    assert all(v["severity"] == "error" for v in hits)


def test_orphan_bidirectional_exit03(tmp_meta_dir, lint_runner):
    """Portal with bidirectional_id but no partner triggers EXIT-03 error."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/orphan-bidir.lua",
               _load_fixture("orphan-bidirectional.lua"))
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "EXIT-03"]
    assert len(hits) > 0, "Orphan bidirectional_id must trigger EXIT-03"
    assert all(v["severity"] == "error" for v in hits)


def test_mismatched_direction_exit04(tmp_meta_dir, lint_runner):
    """Portal direction_hint disagreeing with room exit key triggers EXIT-04 warning."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/mismatched-dir.lua",
               _load_fixture("mismatched-direction.lua"))
    # Room references portal via "south" exit, but portal says direction_hint = "north"
    write_file(tmp_meta_dir, "src/meta/world/mismatch-room.lua",
        'return {\n'
        '    guid = "{20000000-0000-0000-0000-000000000040}",\n'
        '    id = "test-room-mismatch", template = "room",\n'
        '    name = "Mismatch Room",\n'
        '    description = "A room for direction mismatch testing.",\n'
        '    keywords = {"room"}, instances = {},\n'
        '    exits = {\n'
        '        south = { portal = "test-mismatched-direction",\n'
        '                  target = "test-room-elsewhere" }\n'
        '    }\n'
        '}')
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "EXIT-04"]
    assert len(hits) > 0, "direction_hint/exit-key mismatch must trigger EXIT-04"
    assert all(v["severity"] == "warning" for v in hits)


def test_inline_state_exit06(tmp_meta_dir, lint_runner):
    """Room exit with inline open/locked fields triggers EXIT-06 error."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/world/inline-room.lua",
               _load_fixture("inline-state-exit.lua"))
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "EXIT-06"]
    assert len(hits) > 0, "Inline exit state fields must trigger EXIT-06"
    assert all(v["severity"] == "error" for v in hits)


def test_no_on_feel_portal_exit07(tmp_meta_dir, lint_runner):
    """Portal without on_feel triggers EXIT-07 warning (P6 darkness)."""
    _scaffold(tmp_meta_dir)
    write_file(tmp_meta_dir, "src/meta/objects/no-on-feel-portal.lua",
               _load_fixture("no-on-feel-portal.lua"))
    _, violations = lint_runner()
    hits = [v for v in violations if v["rule_id"] == "EXIT-07"]
    assert len(hits) > 0, "Portal missing on_feel must trigger EXIT-07"
    assert all(v["severity"] == "warning" for v in hits)
