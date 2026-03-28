"""
Tests for XF-03 — keyword collision detection.

Validates smart keyword filtering: room-awareness, disambiguator
detection, and config-based allow-listing.

References: Issue #190, WAVE-1 implementation plan.
"""

import sys
from pathlib import Path

import pytest

_test_linter_dir = Path(__file__).resolve().parent
if str(_test_linter_dir) not in sys.path:
    sys.path.insert(0, str(_test_linter_dir))

from helpers import write_file, MINIMAL_MATERIAL_WOOL, MINIMAL_TEMPLATE


# ---------------------------------------------------------------------------
# Helpers: write standard scaffolding files that all tests need
# ---------------------------------------------------------------------------

def _scaffold(root):
    """Write shared material + template files so object-level rules don't drown XF-03."""
    write_file(root, "src/meta/materials/wool.lua", MINIMAL_MATERIAL_WOOL)
    write_file(root, "src/meta/templates/small-item.lua", MINIMAL_TEMPLATE)


def _xf03_violations(violations):
    return [v for v in violations if v["rule_id"] == "XF-03"]


def _make_room_with_instances(room_id, room_name, type_ids):
    """Build a room .lua string with instances referencing given GUIDs."""
    instances = ", ".join(
        f'{{ id = "inst-{i}", type_id = "{tid}" }}'
        for i, tid in enumerate(type_ids)
    )
    guid_hex = room_id.replace("-", "")[:32].ljust(32, "0")
    guid = f"{{{guid_hex[:8]}-{guid_hex[8:12]}-{guid_hex[12:16]}-{guid_hex[16:20]}-{guid_hex[20:32]}}}"
    return (
        f'return {{ guid = "{guid}", '
        f'id = "{room_id}", template = "room", name = "{room_name}", '
        f'description = "A test room.", on_feel = "Cold floor.", '
        f'keywords = {{"{room_id}"}}, '
        f'instances = {{ {instances} }}, '
        f'exits = {{}} }}'
    )


# ---------------------------------------------------------------------------
# Test 1: Same-room objects sharing keyword, no disambiguator → WARNING
# ---------------------------------------------------------------------------

def test_same_room_shared_keyword_warns(tmp_meta_dir, lint_runner):
    """Two objects in the SAME room sharing keyword 'shiny' with identical
    keyword sets should produce an XF-03 WARNING."""
    _scaffold(tmp_meta_dir)

    obj_a_guid = "{10000001-0000-0000-0000-000000000001}"
    obj_b_guid = "{10000001-0000-0000-0000-000000000002}"

    write_file(tmp_meta_dir, "src/meta/objects/bauble.lua",
        f'return {{ guid = "{obj_a_guid}", '
        'id = "bauble", template = "small-item", name = "a shiny bauble", '
        'keywords = {"shiny", "trinket"}, description = "A shiny bauble.", '
        'on_feel = "Smooth.", material = "wool" }')

    write_file(tmp_meta_dir, "src/meta/objects/coin.lua",
        f'return {{ guid = "{obj_b_guid}", '
        'id = "coin", template = "small-item", name = "a shiny coin", '
        'keywords = {"shiny", "trinket"}, description = "A shiny coin.", '
        'on_feel = "Flat.", material = "wool" }')

    # Place both objects in the SAME room
    write_file(tmp_meta_dir, "src/meta/world/bedroom.lua",
        _make_room_with_instances("bedroom", "Bedroom",
                                  [obj_a_guid, obj_b_guid]))

    _, violations = lint_runner()
    xf03 = _xf03_violations(violations)

    assert len(xf03) > 0, "Shared keyword between same-room objects should trigger XF-03"
    for v in xf03:
        assert v["severity"] == "warning", (
            f"Same-room ambiguous collision should be WARNING, got {v['severity']}")


# ---------------------------------------------------------------------------
# Test 2: Different-room objects sharing keyword → INFO (downgraded)
# ---------------------------------------------------------------------------

def test_different_room_shared_keyword_info(tmp_meta_dir, lint_runner):
    """Two objects in DIFFERENT rooms sharing keyword 'match' should
    produce an XF-03 INFO (downgraded from WARNING)."""
    _scaffold(tmp_meta_dir)

    obj_a_guid = "{10000002-0000-0000-0000-000000000001}"
    obj_b_guid = "{10000002-0000-0000-0000-000000000002}"

    write_file(tmp_meta_dir, "src/meta/objects/matchbox-a.lua",
        f'return {{ guid = "{obj_a_guid}", '
        'id = "matchbox-a", template = "small-item", name = "a matchbox", '
        'keywords = {"matchbox", "match"}, description = "A matchbox.", '
        'on_feel = "Small box.", material = "wool" }')

    write_file(tmp_meta_dir, "src/meta/objects/matchbox-b.lua",
        f'return {{ guid = "{obj_b_guid}", '
        'id = "matchbox-b", template = "small-item", name = "a matchbox", '
        'keywords = {"matchbox", "match"}, description = "Another matchbox.", '
        'on_feel = "Small box.", material = "wool" }')

    # Place objects in DIFFERENT rooms
    write_file(tmp_meta_dir, "src/meta/world/bedroom.lua",
        _make_room_with_instances("bedroom", "Bedroom", [obj_a_guid]))
    write_file(tmp_meta_dir, "src/meta/world/kitchen.lua",
        _make_room_with_instances("kitchen", "Kitchen", [obj_b_guid]))

    _, violations = lint_runner()
    xf03 = _xf03_violations(violations)
    match_violations = [v for v in xf03 if "match" in v["message"]]

    assert len(match_violations) > 0, "Cross-room shared keyword should still produce XF-03"
    for v in match_violations:
        assert v["severity"] == "info", (
            f"Cross-room collision should be INFO, got {v['severity']}")


# ---------------------------------------------------------------------------
# Test 3: Keyword in allowed config list → no violation
# ---------------------------------------------------------------------------

def test_allowed_keyword_no_violation(tmp_meta_dir, lint_runner):
    """Keywords listed in the config keyword_allowlist should not trigger XF-03."""
    _scaffold(tmp_meta_dir)

    write_file(tmp_meta_dir, "src/meta/objects/blade-a.lua",
        'return { guid = "{10000003-0000-0000-0000-000000000001}", '
        'id = "blade-a", template = "small-item", name = "a rusty blade", '
        'keywords = {"blade", "rusty"}, description = "A blade.", '
        'on_feel = "Cold.", material = "wool" }')

    write_file(tmp_meta_dir, "src/meta/objects/blade-b.lua",
        'return { guid = "{10000003-0000-0000-0000-000000000002}", '
        'id = "blade-b", template = "small-item", name = "a sharp blade", '
        'keywords = {"blade", "sharp"}, description = "Another blade.", '
        'on_feel = "Sharp.", material = "wool" }')

    _, violations = lint_runner(config={"keyword_allowlist": ["blade"]})
    xf03 = _xf03_violations(violations)
    blade_violations = [v for v in xf03 if "blade" in v["message"]]

    assert len(blade_violations) == 0, (
        "Allowlisted keyword 'blade' should not trigger XF-03")


# ---------------------------------------------------------------------------
# Test 4: One object has disambiguating keyword → no violation
# ---------------------------------------------------------------------------

def test_disambiguating_keyword_suppresses(tmp_meta_dir, lint_runner):
    """If two objects sharing a keyword have unique disambiguating keywords,
    XF-03 should NOT fire as WARNING — the player can resolve ambiguity."""
    _scaffold(tmp_meta_dir)

    obj_a_guid = "{10000004-0000-0000-0000-000000000001}"
    obj_b_guid = "{10000004-0000-0000-0000-000000000002}"

    write_file(tmp_meta_dir, "src/meta/objects/red-gem.lua",
        f'return {{ guid = "{obj_a_guid}", '
        'id = "red-gem", template = "small-item", name = "a red gem", '
        'keywords = {"gem", "red gem", "ruby"}, description = "A red gem.", '
        'on_feel = "Smooth facets.", material = "wool" }')

    write_file(tmp_meta_dir, "src/meta/objects/blue-gem.lua",
        f'return {{ guid = "{obj_b_guid}", '
        'id = "blue-gem", template = "small-item", name = "a blue gem", '
        'keywords = {"gem", "blue gem", "sapphire"}, description = "A blue gem.", '
        'on_feel = "Cool facets.", material = "wool" }')

    # Place both in same room to test disambiguation (not cross-room downgrade)
    write_file(tmp_meta_dir, "src/meta/world/cave.lua",
        _make_room_with_instances("cave", "Crystal Cave",
                                  [obj_a_guid, obj_b_guid]))

    _, violations = lint_runner()
    xf03 = _xf03_violations(violations)
    gem_warnings = [v for v in xf03
                    if "gem" in v["message"] and v["severity"] == "warning"]

    assert len(gem_warnings) == 0, (
        "Each object has unique disambiguating keywords (ruby/sapphire), "
        "so shared 'gem' should not trigger XF-03 WARNING")


# ---------------------------------------------------------------------------
# Test 5: Regression — genuinely ambiguous keywords still trigger WARNING
# ---------------------------------------------------------------------------

def test_genuinely_ambiguous_still_warns(tmp_meta_dir, lint_runner):
    """Two objects with identical keyword sets and no disambiguator
    should still trigger XF-03 WARNING — this is a real collision."""
    _scaffold(tmp_meta_dir)

    obj_a_guid = "{10000005-0000-0000-0000-000000000001}"
    obj_b_guid = "{10000005-0000-0000-0000-000000000002}"

    write_file(tmp_meta_dir, "src/meta/objects/stick-a.lua",
        f'return {{ guid = "{obj_a_guid}", '
        'id = "stick-a", template = "small-item", name = "a wooden stick", '
        'keywords = {"stick", "twig"}, description = "A stick.", '
        'on_feel = "Rough bark.", material = "wool" }')

    write_file(tmp_meta_dir, "src/meta/objects/stick-b.lua",
        f'return {{ guid = "{obj_b_guid}", '
        'id = "stick-b", template = "small-item", name = "another stick", '
        'keywords = {"stick", "twig"}, description = "Another stick.", '
        'on_feel = "Smooth bark.", material = "wool" }')

    # Place both in same room — identical keywords = ambiguous
    write_file(tmp_meta_dir, "src/meta/world/forest.lua",
        _make_room_with_instances("forest", "Dark Forest",
                                  [obj_a_guid, obj_b_guid]))

    _, violations = lint_runner()
    xf03 = _xf03_violations(violations)

    assert len(xf03) > 0, "Genuinely ambiguous keywords must still trigger XF-03"
    assert any(v["severity"] == "warning" for v in xf03), (
        "Genuinely ambiguous collisions should remain WARNING severity")
