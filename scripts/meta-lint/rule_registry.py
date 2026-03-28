"""
Rule Registry — Central metadata for all meta-check rules.

Each rule has:
  - id: Unique rule identifier (e.g., "XF-03")
  - severity: Default severity ("error", "warning", "info")
  - fixable: Whether the rule violation can be auto-fixed
  - fix_safety: "safe" (idempotent, no semantic change) or "unsafe" (needs human review)
  - category: Grouping for configuration (e.g., "cross-file", "material", "structure")
  - description: Human-readable description of what the rule checks
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional


@dataclass(frozen=True)
class RuleMeta:
    id: str
    severity: str           # "error", "warning", "info"
    fixable: bool           # Can this be auto-fixed?
    fix_safety: Optional[str]  # "safe", "unsafe", or None if not fixable
    category: str           # Grouping key
    description: str        # Human-readable


# Master registry — every rule the linter can emit
_RULES: Dict[str, RuleMeta] = {}


def _r(id: str, severity: str, category: str, description: str,
       fixable: bool = False, fix_safety: Optional[str] = None) -> None:
    _RULES[id] = RuleMeta(
        id=id, severity=severity, fixable=fixable,
        fix_safety=fix_safety, category=category, description=description,
    )


# ── Parse / Structure ────────────────────────────────────────────────────────
_r("PARSE-01", "error",   "parse",     "Lua parse error")
_r("S-01",     "error",   "structure", "File must return a table", fixable=True, fix_safety="safe")
_r("S-02",     "error",   "structure", "Missing guid field", fixable=True, fix_safety="safe")
_r("S-04",     "error",   "structure", "Missing id field", fixable=True, fix_safety="safe")
_r("S-06",     "error",   "structure", "Missing name field", fixable=True, fix_safety="safe")
_r("S-07",     "error",   "structure", "Missing or unknown template field")
_r("S-09",     "error",   "structure", "Keywords table missing or empty", fixable=True, fix_safety="safe")
_r("S-10",     "error",   "structure", "Keywords must be strings", fixable=True, fix_safety="safe")
_r("S-11",     "warning", "structure", "Description missing or wrong type", fixable=True, fix_safety="unsafe")

# ── GUID ─────────────────────────────────────────────────────────────────────
_r("G-01",     "error",   "guid",      "Invalid GUID format", fixable=True, fix_safety="safe")

# ── Template ─────────────────────────────────────────────────────────────────
_r("TD-02",    "error",   "template",  "Template guid exists and valid (bare format)")
_r("TD-03",    "error",   "template",  "Template id exists")
_r("TD-04",    "error",   "template",  "Template id matches filename", fixable=True, fix_safety="safe")
_r("TD-05",    "error",   "template",  "Template name exists")
_r("TD-06",    "error",   "template",  "Template keywords table exists", fixable=True, fix_safety="safe")
_r("TD-07",    "error",   "template",  "Template description exists", fixable=True, fix_safety="unsafe")
_r("TD-08",    "warning", "template",  "Template mutations table should exist")
_r("TD-09",    "error",   "template",  "Template must NOT have template field")
_r("TD-11",    "error",   "template",  "Physical template: size > 0", fixable=True, fix_safety="safe")
_r("TD-12",    "error",   "template",  "Physical template: weight > 0", fixable=True, fix_safety="safe")
_r("TD-13",    "error",   "template",  "Physical template: portable is boolean", fixable=True, fix_safety="safe")
_r("TD-14",    "error",   "template",  "Physical template: material is string", fixable=True, fix_safety="safe")
_r("TD-15",    "error",   "template",  "Physical template: container is boolean", fixable=True, fix_safety="safe")
_r("TD-16",    "error",   "template",  "Physical template: capacity >= 0", fixable=True, fix_safety="safe")
_r("TD-17",    "error",   "template",  "Physical template: contents table exists", fixable=True, fix_safety="safe")
_r("TD-18",    "warning", "template",  "Template contents should be empty")
_r("TD-19",    "info",    "template",  "Template should declare location = nil", fixable=True, fix_safety="safe")
_r("TD-20",    "warning", "template",  "Categories table of strings", fixable=True, fix_safety="safe")
_r("TD-21",    "error",   "template",  "Container template: container = true", fixable=True, fix_safety="safe")
_r("TD-22",    "error",   "template",  "Container template: capacity > 0", fixable=True, fix_safety="safe")
_r("TD-23",    "warning", "template",  "Container template: weight_capacity should be > 0", fixable=True, fix_safety="unsafe")
_r("TD-24",    "error",   "template",  "Room template: no physical properties", fixable=True, fix_safety="safe")
_r("TD-25",    "error",   "template",  "Room template: contents table exists", fixable=True, fix_safety="safe")
_r("TD-26",    "error",   "template",  "Room template: exits table exists", fixable=True, fix_safety="safe")
_r("TD-27",    "warning", "template",  "Sheet material should be fabric-class", fixable=True, fix_safety="unsafe")

# ── Injury ───────────────────────────────────────────────────────────────────
_r("INJ-02",   "error",   "injury",    "Injury guid exists (braced format)")
_r("INJ-03",   "error",   "injury",    "Injury id exists")
_r("INJ-04",   "error",   "injury",    "Injury id matches filename", fixable=True, fix_safety="safe")
_r("INJ-05",   "error",   "injury",    "Injury name exists")
_r("INJ-06",   "error",   "injury",    "Injury category field exists", fixable=True, fix_safety="safe")
_r("INJ-07",   "warning", "injury",    "Injury category is known type")
_r("INJ-08",   "error",   "injury",    "Injury description exists", fixable=True, fix_safety="unsafe")
_r("INJ-10",   "info",    "injury",    "No template field on injury", fixable=True, fix_safety="safe")
_r("INJ-11",   "error",   "injury",    "Injury damage_type exists", fixable=True, fix_safety="safe")
_r("INJ-12",   "error",   "injury",    "Injury damage_type is known")
_r("INJ-13",   "error",   "injury",    "Injury initial_state exists", fixable=True, fix_safety="safe")
_r("INJ-14",   "error",   "injury",    "Injury initial_state references defined state", fixable=True, fix_safety="safe")
_r("INJ-15",   "error",   "injury",    "on_inflict table exists", fixable=True, fix_safety="unsafe")
_r("INJ-16",   "error",   "injury",    "on_inflict.initial_damage >= 0", fixable=True, fix_safety="safe")
_r("INJ-17",   "error",   "injury",    "on_inflict.damage_per_tick >= 0", fixable=True, fix_safety="safe")
_r("INJ-18",   "error",   "injury",    "on_inflict.message exists", fixable=True, fix_safety="unsafe")
_r("INJ-19",   "warning", "injury",    "damage_type/damage_per_tick consistency", fixable=True, fix_safety="unsafe")
_r("INJ-20",   "error",   "injury",    "States table exists", fixable=True, fix_safety="safe")
_r("INJ-21",   "error",   "injury",    "At least 2 states", fixable=True, fix_safety="unsafe")
_r("INJ-22",   "error",   "injury",    "Each state has name", fixable=True, fix_safety="unsafe")
_r("INJ-23",   "error",   "injury",    "Each state has description", fixable=True, fix_safety="unsafe")
_r("INJ-24",   "error",   "injury",    "Non-terminal state has on_feel", fixable=True, fix_safety="unsafe")
_r("INJ-25",   "error",   "injury",    "Non-terminal state has damage_per_tick", fixable=True, fix_safety="unsafe")
_r("INJ-26",   "error",   "injury",    "Named states (healed/fatal) should be terminal", fixable=True, fix_safety="unsafe")
_r("INJ-27",   "error",   "injury",    "At least one terminal state", fixable=True, fix_safety="unsafe")
_r("INJ-28",   "warning", "injury",    "At least one positive terminal state")
_r("INJ-29",   "warning", "injury",    "Terminal state: no damage_per_tick > 0")
_r("INJ-30",   "warning", "injury",    "Terminal state: no timed_events")
_r("INJ-31",   "warning", "injury",    "Terminal state: no restricts")
_r("INJ-32",   "info",    "injury",    "Non-terminal state should have on_look", fixable=True, fix_safety="unsafe")
_r("INJ-33",   "info",    "injury",    "Bleeding/infected states should have on_smell", fixable=True, fix_safety="unsafe")
_r("INJ-34",   "error",   "injury",    "timed_events must be table", fixable=True, fix_safety="safe")
_r("INJ-35",   "error",   "injury",    "Timed event has event field", fixable=True, fix_safety="unsafe")
_r("INJ-36",   "error",   "injury",    "Timed event has positive delay", fixable=True, fix_safety="safe")
_r("INJ-37",   "error",   "injury",    "Timed event has to_state", fixable=True, fix_safety="unsafe")
_r("INJ-38",   "error",   "injury",    "Timed event to_state in states", fixable=True, fix_safety="safe")
_r("INJ-39",   "warning", "injury",    "Timed event delay in range (360-10800)")
_r("INJ-40",   "warning", "injury",    "Multiple transition events")
_r("INJ-41",   "error",   "injury",    "restricts must be table", fixable=True, fix_safety="safe")
_r("INJ-42",   "error",   "injury",    "restricts action = true", fixable=True, fix_safety="unsafe")
_r("INJ-43",   "warning", "injury",    "Unknown restrict actions")
_r("INJ-44",   "error",   "injury",    "transitions entries must be tables", fixable=True, fix_safety="safe")
_r("INJ-45",   "error",   "injury",    "Transition has from", fixable=True, fix_safety="unsafe")
_r("INJ-46",   "error",   "injury",    "Transition has to", fixable=True, fix_safety="unsafe")
_r("INJ-47",   "error",   "injury",    "Transition from state in states", fixable=True, fix_safety="safe")
_r("INJ-48",   "error",   "injury",    "Transition to state in states", fixable=True, fix_safety="safe")
_r("INJ-49",   "error",   "injury",    "Non-auto transition has verb", fixable=True, fix_safety="unsafe")
_r("INJ-50",   "error",   "injury",    "Trigger must be auto if present", fixable=True, fix_safety="safe")
_r("INJ-51",   "warning", "injury",    "Auto transition should have condition")
_r("INJ-52",   "error",   "injury",    "Transition has message", fixable=True, fix_safety="unsafe")
_r("INJ-53",   "error",   "injury",    "Transition not from terminal state")
_r("INJ-54",   "warning", "injury",    "Duplicate from+verb pairs")
_r("INJ-55",   "error",   "injury",    "requires_item_cures is string", fixable=True, fix_safety="unsafe")
_r("INJ-56",   "error",   "injury",    "mutate is table", fixable=True, fix_safety="safe")
_r("INJ-57",   "warning", "injury",    "mutate.damage_per_tick >= 0")
_r("INJ-58",   "error",   "injury",    "healing_interactions table exists", fixable=True, fix_safety="safe")
_r("INJ-59",   "error",   "injury",    "healing_interactions is table", fixable=True, fix_safety="safe")
_r("INJ-60",   "error",   "injury",    "healing_interactions item has transitions_to", fixable=True, fix_safety="unsafe")
_r("INJ-61",   "error",   "injury",    "transitions_to in states", fixable=True, fix_safety="safe")
_r("INJ-62",   "error",   "injury",    "healing_interactions item has from_states", fixable=True, fix_safety="unsafe")
_r("INJ-63",   "error",   "injury",    "from_states entries in states", fixable=True, fix_safety="safe")
_r("INJ-64",   "warning", "injury",    "from_state not terminal")
_r("INJ-66",   "error",   "injury",    "causes_unconsciousness is boolean", fixable=True, fix_safety="safe")
_r("INJ-67",   "error",   "injury",    "unconscious_duration table with positive numbers", fixable=True, fix_safety="unsafe")
_r("INJ-68",   "error",   "injury",    "unconscious_duration requires causes_unconsciousness=true")
_r("INJ-69",   "info",    "injury",    "Unknown top-level fields", fixable=True, fix_safety="unsafe")

# ── Material ─────────────────────────────────────────────────────────────────
_r("MD-02",    "error",   "material",  "Material name exists as string")
_r("MD-03",    "error",   "material",  "Material name matches filename", fixable=True, fix_safety="safe")
_r("MD-04",    "error",   "material",  "Material guid exists (braced format)")
_r("MD-05",    "info",    "material",  "No id field on material")
_r("MD-06",    "error",   "material",  "density > 0", fixable=True, fix_safety="safe")
_r("MD-07",    "error",   "material",  "hardness in [0, 10]", fixable=True, fix_safety="safe")
_r("MD-08",    "error",   "material",  "flexibility in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-09",    "error",   "material",  "absorbency in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-10",    "error",   "material",  "opacity in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-11",    "error",   "material",  "flammability in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-12",    "error",   "material",  "conductivity in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-13",    "error",   "material",  "fragility in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-14",    "error",   "material",  "value > 0", fixable=True, fix_safety="safe")
_r("MD-15",    "error",   "material",  "melting_point positive or nil", fixable=True, fix_safety="safe")
_r("MD-16",    "error",   "material",  "ignition_point positive or nil", fixable=True, fix_safety="safe")
_r("MD-17",    "warning", "material",  "Flammable should declare ignition_point")
_r("MD-18",    "warning", "material",  "Non-flammable should not have ignition_point")
_r("MD-20",    "warning", "material",  "High flexibility with high fragility unusual")
_r("MD-21",    "info",    "material",  "Non-metal with conductivity > 0")
_r("MD-22",    "error",   "material",  "rust_susceptibility in [0.0, 1.0]", fixable=True, fix_safety="safe")
_r("MD-23",    "warning", "material",  "rust_susceptibility only on ferrous materials")
_r("MD-24",    "info",    "material",  "Unknown material fields")

# ── Level ────────────────────────────────────────────────────────────────────
_r("LV-01",    "error",   "level",     "Level guid exists (bare format)")
_r("LV-02",    "error",   "level",     "template = level", fixable=True, fix_safety="safe")
_r("LV-03",    "error",   "level",     "number is positive integer")
_r("LV-04",    "error",   "level",     "name exists", fixable=True, fix_safety="unsafe")
_r("LV-05",    "error",   "level",     "rooms table non-empty with string entries", fixable=True, fix_safety="unsafe")
_r("LV-06",    "error",   "level",     "start_room exists and in rooms list")
_r("LV-07",    "error",   "level",     "start_room references valid room file")
_r("LV-08",    "warning", "level",     "completion should be defined")
_r("LV-09",    "warning", "level",     "intro should be defined")
_r("LV-10",    "warning", "level",     "boundaries.entry should be defined")
_r("LV-11",    "error",   "level",     "intro is table", fixable=True, fix_safety="safe")
_r("LV-12",    "error",   "level",     "intro.title non-empty string", fixable=True, fix_safety="unsafe")
_r("LV-13",    "error",   "level",     "intro.narrative table of strings", fixable=True, fix_safety="unsafe")
_r("LV-14",    "warning", "level",     "intro.narrative non-empty")
_r("LV-15",    "warning", "level",     "intro.help non-empty string", fixable=True, fix_safety="unsafe")
_r("LV-16",    "info",    "level",     "intro.subtitle should be string", fixable=True, fix_safety="unsafe")
_r("LV-17",    "error",   "level",     "completion table of tables", fixable=True, fix_safety="safe")
_r("LV-18",    "error",   "level",     "Each completion entry has type", fixable=True, fix_safety="unsafe")
_r("LV-19",    "error",   "level",     "type=reach_room requires room")
_r("LV-20",    "error",   "level",     "completion room in rooms list", fixable=True, fix_safety="safe")
_r("LV-21",    "warning", "level",     "completion entry should have message", fixable=True, fix_safety="unsafe")
_r("LV-22",    "warning", "level",     "completion from references valid room")
_r("LV-23",    "warning", "level",     "boundaries should be table", fixable=True, fix_safety="safe")
_r("LV-24",    "error",   "level",     "boundaries.entry table of strings, non-empty", fixable=True, fix_safety="safe")
_r("LV-25",    "error",   "level",     "boundaries.entry rooms in level rooms", fixable=True, fix_safety="safe")
_r("LV-26",    "warning", "level",     "start_room in boundaries.entry")
_r("LV-27",    "warning", "level",     "boundaries.exit table of tables", fixable=True, fix_safety="safe")
_r("LV-28",    "error",   "level",     "boundary exit has room", fixable=True, fix_safety="unsafe")
_r("LV-29",    "error",   "level",     "boundary exit has exit_direction", fixable=True, fix_safety="unsafe")
_r("LV-30",    "error",   "level",     "boundary exit has positive target_level", fixable=True, fix_safety="unsafe")
_r("LV-31",    "error",   "level",     "boundary exit room in rooms list", fixable=True, fix_safety="safe")
_r("LV-33",    "warning", "level",     "target_level > current level")
_r("LV-34",    "error",   "level",     "restricted_objects table of strings", fixable=True, fix_safety="safe")
_r("LV-35",    "warning", "level",     "restricted objects reference existing objects")
_r("LV-36",    "error",   "level",     "description is non-empty string", fixable=True, fix_safety="unsafe")
_r("LV-37",    "error",   "level",     "rooms entries are unique", fixable=True, fix_safety="safe")
_r("LV-38",    "error",   "level",     "rooms entries reference valid room files")
_r("LV-40",    "error",   "level",     "Level numbers unique across all levels")

# ── Sensory ──────────────────────────────────────────────────────────────────
_r("SN-01",    "error",   "sensory",   "Object/room has on_feel (global or per-state)")
_r("SN-02",    "error",   "sensory",   "on_feel is string or function", fixable=True, fix_safety="safe")

# ── FSM ──────────────────────────────────────────────────────────────────────
_r("FSM-01",   "error",   "fsm",       "initial_state required if states defined")
_r("FSM-04",   "error",   "fsm",       "initial_state defined in states", fixable=True, fix_safety="safe")

# ── Transition ───────────────────────────────────────────────────────────────
_r("TR-01",    "error",   "transition", "Transition from state in states", fixable=True, fix_safety="safe")
_r("TR-02",    "error",   "transition", "Transition to state in states", fixable=True, fix_safety="safe")

# ── Material Reference ───────────────────────────────────────────────────────
_r("MAT-01",   "warning", "material-ref", "Object should declare material")
_r("MAT-02",   "error",   "material-ref", "Material references known material file")
_r("MAT-03",   "warning", "material-ref", "Material reference uses string name (prefer GUID)", fixable=True, fix_safety="unsafe")

# ── Room ─────────────────────────────────────────────────────────────────────
_r("RM-01",    "warning", "room",      "Room should have description")

# ── Cross-File ───────────────────────────────────────────────────────────────
_r("XF-01",    "error",   "cross-file", "Duplicate GUID across all files")
_r("XF-03",    "warning", "cross-file", "Keyword collision between objects", fixable=True, fix_safety="unsafe")

# ── Cross-Reference ──────────────────────────────────────────────────────────
_r("XR-01",    "warning", "cross-ref",  "Healing item ID resolves to objects")
_r("XR-02",    "warning", "cross-ref",  "on_use.cures references valid injury ID")
_r("XR-03",    "warning", "cross-ref",  "requires_item_cures references valid injury ID")
_r("XR-05",    "info",    "cross-ref",  "Template material=generic (instances must override)")
_r("XR-05b",   "warning", "cross-ref",  "Object inherits generic material without override", fixable=True, fix_safety="unsafe")
_r("XR-06",    "error",   "cross-ref",  "Template value on objects resolves to template file")
_r("XR-08",    "warning", "cross-ref",  "Level completion rooms exist as room files")
_r("XR-09",    "warning", "cross-ref",  "Boundary exit directions exist on rooms")
_r("XR-10",    "warning", "cross-ref",  "Every room file belongs to at least one level")

# ── GUID Cross-Reference (Phase 2) ──────────────────────────────────────────
_r("GUID-01",  "error",   "guid-xref",  "Room instance type_id must reference a known object GUID")
_r("GUID-02",  "warning", "guid-xref",  "Orphan object — GUID not referenced by any room instance")
_r("GUID-03",  "error",   "guid-xref",  "Duplicate instance id within same room")

# ── EXIT Legacy Inline Validation ────────────────────────────────────────────
_r("EXIT-R01", "error",   "exit",        "Inline exit target must reference a valid room")
_r("EXIT-R02", "warning", "exit",        "Bidirectional inline exit mismatch — no return exit")

# ── EXIT Portal Validation (Phase 4) ────────────────────────────────────────
_r("EXIT-01",  "error",   "exit-portal", "Portal must have portal.target defined and non-nil")
_r("EXIT-02",  "error",   "exit-portal", "Portal FSM state must declare traversable = true or false", fixable=True, fix_safety="unsafe")
_r("EXIT-03",  "error",   "exit-portal", "bidirectional_id must have exactly one matching partner")
_r("EXIT-04",  "warning", "exit-portal", "Portal direction_hint should match room exit direction key")
_r("EXIT-05",  "warning", "exit-portal", "Thin exit reference must point to portal template object")
_r("EXIT-06",  "error",   "exit-portal", "No inline exit state allowed on exit tables")
_r("EXIT-07",  "warning", "exit-portal", "Portal should have on_feel (P6 darkness requirement)")

# ── Cross-Reference (Portal) ────────────────────────────────────────────────
_r("XR-07",    "warning", "cross-ref",   "Thin exit portal field must resolve to valid object ID")

# ── Loot Table (Phase 4 WAVE-2) ─────────────────────────────────────────────
_r("LOOT-001", "error",   "loot",        "loot_table must be a table with valid sections", fixable=True, fix_safety="safe")
_r("LOOT-002", "error",   "loot",        "on_death weights must be > 0 and sum to > 0")
_r("LOOT-003", "error",   "loot",        "loot_table template refs must resolve to existing objects")
_r("LOOT-004", "error",   "loot",        "variable min must be <= max, both >= 0", fixable=True, fix_safety="unsafe")
_r("LOOT-005", "warning", "loot",        "always items must have template field, no duplicates", fixable=True, fix_safety="unsafe")

# ── Creature (Phase 4 WAVE-4) ───────────────────────────────────────────────
_r("CREATURE-001", "error",   "creature", "animate = true must exist", fixable=True, fix_safety="safe")
_r("CREATURE-002", "error",   "creature", "behavior table must exist")
_r("CREATURE-003", "error",   "creature", "behavior must have >= 1 drive entry")
_r("CREATURE-004", "error",   "creature", "behavior.states must include idle key")
_r("CREATURE-005", "error",   "creature", "health and max_health must be numbers")
_r("CREATURE-006", "error",   "creature", "alive must be boolean", fixable=True, fix_safety="safe")
_r("CREATURE-007", "warning", "creature", "Drive weights must each be 0.0-1.0")
_r("CREATURE-008", "warning", "creature", "Drive weights must sum to <= 1.0")
_r("CREATURE-009", "error",   "creature", "reactions table must exist with >= 1 entry")
_r("CREATURE-010", "warning", "creature", "Each reaction should have drive_deltas table")
_r("CREATURE-011", "error",   "creature", "size must be string enum (tiny/small/medium/large/huge)")
_r("CREATURE-012", "error",   "creature", "weight must be positive number")
_r("CREATURE-013", "warning", "creature", "material must resolve to registered material")
_r("CREATURE-014", "error",   "creature", "Standard OBJ on_feel check (reuse)")
_r("CREATURE-015", "error",   "creature", "Standard OBJ keywords check (reuse)")
_r("CREATURE-016", "error",   "creature", "Standard OBJ description check (reuse)")
_r("CREATURE-017", "error",   "creature", "FSM must include dead state")
_r("CREATURE-018", "warning", "creature", "dead state should set animate=false, portable=true")
_r("CREATURE-019", "warning", "creature", "Room spawn GUIDs in placement must resolve to existing rooms")
_r("CREATURE-020", "warning", "creature", "Loot table GUIDs must resolve to existing objects")


def get_rule(rule_id: str) -> Optional[RuleMeta]:
    """Look up rule metadata by ID."""
    return _RULES.get(rule_id)


def get_all_rules() -> Dict[str, RuleMeta]:
    """Return a copy of the full rule registry."""
    return dict(_RULES)


def get_rules_by_category(category: str) -> Dict[str, RuleMeta]:
    """Return all rules in a given category."""
    return {k: v for k, v in _RULES.items() if v.category == category}


def get_default_severity(rule_id: str) -> str:
    """Return the default severity for a rule, or 'warning' if unknown."""
    rule = _RULES.get(rule_id)
    return rule.severity if rule else "warning"


def is_fixable(rule_id: str) -> bool:
    """Return whether a rule violation can be auto-fixed."""
    rule = _RULES.get(rule_id)
    return rule.fixable if rule else False


def get_fix_safety(rule_id: str) -> str:
    """Return 'safe' or 'unsafe' for a rule's auto-fix."""
    rule = _RULES.get(rule_id)
    return rule.fix_safety if rule else "unsafe"
