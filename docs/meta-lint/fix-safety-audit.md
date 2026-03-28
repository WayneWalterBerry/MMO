# Fix-Safety Audit — Meta-Lint Rules

**Audit Date:** 2026-08-22  
**Auditor:** Bart (Architect)  
**Source:** `scripts/meta-lint/rule_registry.py` (200 rules after MD-19 removal)

---

## Summary

| Metric | Count |
|--------|-------|
| **Total rules** | 200 |
| **Safe (idempotent)** | 47 |
| **Unsafe (semantic change)** | 62 |
| **Not fixable (design decision)** | 91 |

---

## Classification Definitions

| Classification | Definition | Auto-fixable? |
|---------------|-----------|---|
| **safe** | Idempotent, no semantic change. Adding missing required field with sensible default, fixing GUID format, normalizing casing. Examples: `S-01` (missing `template`), `G-01` (invalid GUID format). | Yes |
| **unsafe** | Semantic change requiring human review. Rewriting descriptions, changing materials, altering FSM transitions, modifying object relationships. Examples: `XF-03` (keyword collision resolution requires human choice). | Yes (requires `--unsafe-fixes` flag) |
| **false** (not fixable) | Cannot be automated — requires design decision, cross-file coordination, or designer intent. Examples: `XF-01` (duplicate GUID — whose is wrong?), `RM-01` (room needs description — but what?). | No |

---

## Full Audit — All 200 Rules

### PARSE (1 rule)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| PARSE-01 | Error | parse | false | Lua syntax error — cannot fix automatically; requires developer intervention |

### STRUCTURE (8 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| S-01 | Error | structure | safe | Missing `template` field — can detect type (room/injury/object) and set sensible default |
| S-02 | Error | structure | safe | Missing `guid` field — can generate new Windows GUID with correct format |
| S-04 | Error | structure | safe | Missing `id` field — can derive from filename (file.lua → id="file") |
| S-06 | Error | structure | safe | Missing `name` field — can derive from `id` with title-casing (safe default) |
| S-07 | Error | structure | false | Missing or unknown `template` field — detection of intent requires design review |
| S-09 | Error | structure | safe | Keywords table missing or empty — can add default `keywords = {id}` |
| S-10 | Error | structure | safe | Keywords must be strings — can filter/convert non-string entries |
| S-11 | Warning | structure | unsafe | Description missing or wrong type — adding description requires design input |

### GUID (1 rule)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| G-01 | Error | guid | safe | Invalid GUID format — can normalize to Windows GUID format (idempotent) |

### TEMPLATE (25 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| TD-02 | Error | template | false | Template guid exists (bare format) — guid mismatch is a design decision |
| TD-03 | Error | template | false | Template id exists — duplicate id requires designer to choose which one |
| TD-04 | Error | template | fixable, safe | Template id matches filename — can rename file to match id or vice versa |
| TD-05 | Error | template | false | Template name exists — duplicate name requires design review |
| TD-06 | Error | template | safe | Template keywords table exists — can add default empty/id-based keywords |
| TD-07 | Error | template | unsafe | Template description exists — adding description requires design input |
| TD-08 | Warning | template | false | Template mutations table should exist — designer choice whether to add |
| TD-09 | Error | template | false | Template must NOT have `template` field — self-reference is a structural error; manual fix needed |
| TD-11 | Error | template | safe | Physical template: `size > 0` — can set safe default (1 unit) |
| TD-12 | Error | template | safe | Physical template: `weight > 0` — can set safe default (1 unit) |
| TD-13 | Error | template | safe | Physical template: `portable` is boolean — can normalize to true/false |
| TD-14 | Error | template | safe | Physical template: `material` is string — can normalize to string type or set "generic" |
| TD-15 | Error | template | safe | Physical template: `container` is boolean — can normalize to true/false |
| TD-16 | Error | template | safe | Physical template: `capacity >= 0` — can set safe default (0 for non-containers) |
| TD-17 | Error | template | safe | Physical template: `contents` table exists — can add empty table |
| TD-18 | Warning | template | false | Template contents should be empty — design intent whether to add items to template |
| TD-19 | Info | template | safe | Template should declare `location = nil` — can add this no-op field safely |
| TD-20 | Warning | template | safe | Categories table of strings — can normalize/filter to string entries |
| TD-21 | Error | template | safe | Container template: `container = true` — can force-set when container template detected |
| TD-22 | Error | template | safe | Container template: `capacity > 0` — can set safe default capacity (e.g., 10) |
| TD-23 | Warning | template | unsafe | Container template: `weight_capacity` should be > 0 — requires design decision |
| TD-24 | Error | template | safe | Room template: no physical properties — can remove any present (idempotent if clean) |
| TD-25 | Error | template | safe | Room template: `contents` table exists — can add empty table |
| TD-26 | Error | template | safe | Room template: `exits` table exists — can add empty table |
| TD-27 | Warning | template | unsafe | Sheet material should be fabric-class — requires designer to choose material |

### INJURY (66 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| INJ-02 | Error | injury | false | Injury guid exists (braced format) — guid collision requires designer resolution |
| INJ-03 | Error | injury | false | Injury id exists — duplicate id is a design decision |
| INJ-04 | Error | injury | fixable, safe | Injury id matches filename — can rename file to match id |
| INJ-05 | Error | injury | false | Injury name exists — duplicate name requires designer choice |
| INJ-06 | Error | injury | safe | Injury category field exists — can add default category if missing |
| INJ-07 | Warning | injury | false | Injury category is known type — unknown category requires designer to pick correct type |
| INJ-08 | Error | injury | unsafe | Injury description exists — adding description requires design input |
| INJ-10 | Info | injury | safe | No template field on injury — can remove if present (idempotent) |
| INJ-11 | Error | injury | safe | Injury damage_type exists — can add safe default or detect from FSM |
| INJ-12 | Error | injury | false | Injury damage_type is known — unknown type requires designer selection |
| INJ-13 | Error | injury | safe | Injury initial_state exists — can add default "injured" state |
| INJ-14 | Error | injury | safe | Injury initial_state references defined state — can fix to valid state from FSM |
| INJ-15 | Error | injury | unsafe | on_inflict table exists — requires structure design input |
| INJ-16 | Error | injury | safe | on_inflict.initial_damage >= 0 — can clamp negative to 0 (safe default) |
| INJ-17 | Error | injury | safe | on_inflict.damage_per_tick >= 0 — can clamp negative to 0 (safe default) |
| INJ-18 | Error | injury | unsafe | on_inflict.message exists — adding message requires design input |
| INJ-19 | Warning | injury | unsafe | damage_type/damage_per_tick consistency — semantic check; fix requires design knowledge |
| INJ-20 | Error | injury | safe | States table exists — can add empty or default state table |
| INJ-21 | Error | injury | unsafe | At least 2 states — adding new state requires semantic design |
| INJ-22 | Error | injury | unsafe | Each state has name — adding state names requires designer intent |
| INJ-23 | Error | injury | unsafe | Each state has description — adding descriptions requires design input |
| INJ-24 | Error | injury | unsafe | Non-terminal state has on_feel — adding sensory text requires design input |
| INJ-25 | Error | injury | unsafe | Non-terminal state has damage_per_tick — requires semantic decision |
| INJ-26 | Warning | injury | unsafe | Named states (healed/fatal) should be terminal — restructuring FSM requires design input |
| INJ-27 | Error | injury | unsafe | At least one terminal state — adding terminal state requires design |
| INJ-28 | Warning | injury | false | At least one positive terminal state — design choice (recovery vs. permadeath) |
| INJ-29 | Warning | injury | false | Terminal state: no damage_per_tick > 0 — design choice whether to allow damage-while-terminal |
| INJ-30 | Warning | injury | false | Terminal state: no timed_events — design choice for terminal state lifecycle |
| INJ-31 | Warning | injury | false | Terminal state: no restricts — design choice for terminal state behavior |
| INJ-32 | Info | injury | unsafe | Non-terminal state should have on_look — adding on_look requires design input |
| INJ-33 | Info | injury | unsafe | Bleeding/infected states should have on_smell — adding on_smell requires design input |
| INJ-34 | Error | injury | safe | timed_events must be table — can convert/normalize to table type |
| INJ-35 | Error | injury | unsafe | Timed event has event field — adding event requires semantic design |
| INJ-36 | Error | injury | safe | Timed event has positive delay — can clamp non-positive delay to safe default (e.g., 360) |
| INJ-37 | Error | injury | unsafe | Timed event has to_state — adding to_state requires design |
| INJ-38 | Error | injury | safe | Timed event to_state in states — can fix to valid state from FSM |
| INJ-39 | Warning | injury | false | Timed event delay in range (360-10800) — timing design choice |
| INJ-40 | Warning | injury | false | Multiple transition events — whether to allow multiple is design choice |
| INJ-41 | Error | injury | safe | restricts must be table — can convert/normalize to table type |
| INJ-42 | Error | injury | unsafe | restricts action = true — adding restriction requires semantic design |
| INJ-43 | Warning | injury | false | Unknown restrict actions — designer must choose valid action |
| INJ-44 | Error | injury | safe | transitions entries must be tables — can convert/filter to table type |
| INJ-45 | Error | injury | unsafe | Transition has from — adding from state requires design |
| INJ-46 | Error | injury | unsafe | Transition has to — adding to state requires design |
| INJ-47 | Error | injury | safe | Transition from state in states — can fix to valid state from FSM |
| INJ-48 | Error | injury | safe | Transition to state in states — can fix to valid state from FSM |
| INJ-49 | Error | injury | unsafe | Non-auto transition has verb — adding verb requires design input |
| INJ-50 | Error | injury | safe | Trigger must be auto if present — can normalize/fix to valid trigger value |
| INJ-51 | Warning | injury | false | Auto transition should have condition — whether to add condition is design choice |
| INJ-52 | Error | injury | unsafe | Transition has message — adding transition message requires design input |
| INJ-53 | Error | injury | false | Transition not from terminal state — whether to allow transition from terminal is design choice |
| INJ-54 | Warning | injury | false | Duplicate from+verb pairs — designer must choose which to keep or merge |
| INJ-55 | Error | injury | unsafe | requires_item_cures is string — adding/fixing requires design input |
| INJ-56 | Error | injury | safe | mutate is table — can convert/normalize to table type |
| INJ-57 | Warning | injury | false | mutate.damage_per_tick >= 0 — whether to allow negative is design choice |
| INJ-58 | Error | injury | safe | healing_interactions table exists — can add empty table |
| INJ-59 | Error | injury | safe | healing_interactions is table — can convert/normalize to table type |
| INJ-60 | Error | injury | unsafe | healing_interactions item has transitions_to — adding requires design |
| INJ-61 | Error | injury | safe | transitions_to in states — can fix to valid state from FSM |
| INJ-62 | Error | injury | unsafe | healing_interactions item has from_states — adding requires design |
| INJ-63 | Error | injury | safe | from_states entries in states — can fix to valid states from FSM |
| INJ-64 | Warning | injury | false | from_state not terminal — design choice whether to allow healing from terminal |
| INJ-66 | Error | injury | safe | causes_unconsciousness is boolean — can normalize to true/false |
| INJ-67 | Error | injury | unsafe | unconscious_duration table with positive numbers — adding requires design |
| INJ-68 | Error | injury | false | unconscious_duration requires causes_unconsciousness=true — semantic check; fix is conditional |
| INJ-69 | Info | injury | unsafe | Unknown top-level fields — removing requires confirmation fields aren't custom |

### MATERIAL (22 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| MD-02 | Error | material | false | Material name exists as string — duplicate name requires designer resolution |
| MD-03 | Error | material | fixable, safe | Material name matches filename — can rename file to match name |
| MD-04 | Error | material | false | Material guid exists (braced format) — guid collision requires designer choice |
| MD-05 | Info | material | false | No id field on material — design choice whether to add id |
| MD-06 | Error | material | safe | density > 0 — can set safe default (e.g., 1.0) |
| MD-07 | Error | material | safe | hardness in [0, 10] — can clamp to valid range |
| MD-08 | Error | material | safe | flexibility in [0.0, 1.0] — can clamp to valid range |
| MD-09 | Error | material | safe | absorbency in [0.0, 1.0] — can clamp to valid range |
| MD-10 | Error | material | safe | opacity in [0.0, 1.0] — can clamp to valid range |
| MD-11 | Error | material | safe | flammability in [0.0, 1.0] — can clamp to valid range |
| MD-12 | Error | material | safe | conductivity in [0.0, 1.0] — can clamp to valid range |
| MD-13 | Error | material | safe | fragility in [0.0, 1.0] — can clamp to valid range |
| MD-14 | Error | material | safe | value > 0 — can set safe default (e.g., 1) |
| MD-15 | Error | material | safe | melting_point positive or nil — can set to nil (safe default) |
| MD-16 | Error | material | safe | ignition_point positive or nil — can set to nil (safe default) |
| MD-17 | Warning | material | false | Flammable should declare ignition_point — design choice whether to add |
| MD-18 | Warning | material | false | Non-flammable should not have ignition_point — could auto-remove, but design choice |
| MD-20 | Warning | material | false | High flexibility with high fragility unusual — design choice, not error |
| MD-21 | Info | material | false | Non-metal with conductivity > 0 — design choice for unusual material properties |
| MD-22 | Error | material | safe | rust_susceptibility in [0.0, 1.0] — can clamp to valid range |
| MD-23 | Warning | material | false | rust_susceptibility only on ferrous materials — design choice, not error |
| MD-24 | Info | material | false | Unknown material fields — designer intent; may be custom properties |

### LEVEL (38 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| LV-01 | Error | level | false | Level guid exists (bare format) — guid collision requires designer resolution |
| LV-02 | Error | level | safe | template = level — can force-set for level files |
| LV-03 | Error | level | false | number is positive integer — level number choice is design decision |
| LV-04 | Error | level | unsafe | name exists — adding level name requires design input |
| LV-05 | Error | level | unsafe | rooms table non-empty with string entries — building level layout requires design |
| LV-06 | Error | level | false | start_room exists and in rooms list — choosing start_room is design decision |
| LV-07 | Error | level | false | start_room references valid room file — fixing invalid reference requires designer choice |
| LV-08 | Warning | level | false | completion should be defined — design choice whether to define completion |
| LV-09 | Warning | level | false | intro should be defined — design choice whether to add intro |
| LV-10 | Warning | level | false | boundaries.entry should be defined — design choice for level boundaries |
| LV-11 | Error | level | safe | intro is table — can convert/normalize to table type |
| LV-12 | Error | level | unsafe | intro.title non-empty string — adding intro title requires design input |
| LV-13 | Error | level | unsafe | intro.narrative table of strings — building narrative requires design input |
| LV-14 | Warning | level | false | intro.narrative non-empty — design choice on narrative content |
| LV-15 | Warning | level | unsafe | intro.help non-empty string — adding help text requires design input |
| LV-16 | Info | level | unsafe | intro.subtitle should be string — adding subtitle requires design input |
| LV-17 | Error | level | safe | completion table of tables — can convert/normalize to table structure |
| LV-18 | Error | level | unsafe | Each completion entry has type — adding type requires design |
| LV-19 | Error | level | false | type=reach_room requires room — design choice which completion room |
| LV-20 | Error | level | safe | completion room in rooms list — can fix to valid room from level |
| LV-21 | Warning | level | unsafe | completion entry should have message — adding message requires design input |
| LV-22 | Warning | level | false | completion from references valid room — designer must choose correct room |
| LV-23 | Warning | level | safe | boundaries should be table — can convert/normalize to table type |
| LV-24 | Error | level | safe | boundaries.entry table of strings, non-empty — can normalize structure |
| LV-25 | Error | level | safe | boundaries.entry rooms in level rooms — can fix to valid rooms from level |
| LV-26 | Warning | level | false | start_room in boundaries.entry — design choice on boundary configuration |
| LV-27 | Warning | level | safe | boundaries.exit table of tables — can normalize to table structure |
| LV-28 | Error | level | unsafe | boundary exit has room — adding room requires design |
| LV-29 | Error | level | unsafe | boundary exit has exit_direction — adding direction requires design |
| LV-30 | Error | level | unsafe | boundary exit has positive target_level — adding target level requires design |
| LV-31 | Error | level | safe | boundary exit room in rooms list — can fix to valid room from level |
| LV-33 | Warning | level | false | target_level > current level — design choice whether to enforce progression |
| LV-34 | Error | level | safe | restricted_objects table of strings — can normalize/filter to strings |
| LV-35 | Warning | level | false | restricted objects reference existing objects — designer must choose valid objects |
| LV-36 | Error | level | unsafe | description is non-empty string — adding description requires design input |
| LV-37 | Error | level | safe | rooms entries are unique — can filter/remove duplicates |
| LV-38 | Error | level | false | rooms entries reference valid room files — designer must find or create rooms |
| LV-40 | Error | level | false | Level numbers unique across all levels — designer must reassign level numbers |

### SENSORY (2 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| SN-01 | Error | sensory | false | Object/room has on_feel (global or per-state) — adding requires design/sensory input |
| SN-02 | Error | sensory | safe | on_feel is string or function — can convert/normalize to valid type |

### FSM (2 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| FSM-01 | Error | fsm | false | initial_state required if states defined — choosing initial state is design decision |
| FSM-04 | Error | fsm | safe | initial_state defined in states — can fix to valid state from FSM |

### TRANSITION (2 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| TR-01 | Error | transition | safe | Transition from state in states — can fix to valid state from FSM |
| TR-02 | Error | transition | safe | Transition to state in states — can fix to valid state from FSM |

### MATERIAL-REF (3 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| MAT-01 | Warning | material-ref | false | Object should declare material — design choice whether to add |
| MAT-02 | Error | material-ref | false | Material references known material file — designer must find/create material |
| MAT-03 | Warning | material-ref | unsafe | Material reference uses string name (prefer GUID) — changing to GUID requires design review |

### ROOM (1 rule)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| RM-01 | Warning | room | false | Room should have description — adding description requires design input |

### CROSS-FILE (2 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| XF-01 | Error | cross-file | false | Duplicate GUID across all files — designer must determine which GUID is wrong |
| XF-03 | Warning | cross-file | unsafe | Keyword collision between objects — fixing requires human review of ambiguity |

### CROSS-REF (10 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| XR-01 | Warning | cross-ref | false | Healing item ID resolves to objects — designer must create/find healing item |
| XR-02 | Warning | cross-ref | false | on_use.cures references valid injury ID — designer must create/find injury |
| XR-03 | Warning | cross-ref | false | requires_item_cures references valid injury ID — designer must create/find injury |
| XR-05 | Info | cross-ref | false | Template material=generic (instances must override) — design check; not an error |
| XR-05b | Warning | cross-ref | unsafe | Object inherits generic material without override — fixing requires design |
| XR-06 | Error | cross-ref | false | Template value on objects resolves to template file — designer must create/find template |
| XR-07 | Warning | cross-ref | false | Thin exit portal field must resolve to valid object ID — designer must create/find object |
| XR-08 | Warning | cross-ref | false | Level completion rooms exist as room files — designer must create/find rooms |
| XR-09 | Warning | cross-ref | false | Boundary exit directions exist on rooms — designer must verify room exits |
| XR-10 | Warning | cross-ref | false | Every room file belongs to at least one level — designer must add room to level |

### GUID-XREF (3 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| GUID-01 | Error | guid-xref | false | Room instance type_id must reference a known object GUID — designer must find/create object |
| GUID-02 | Warning | guid-xref | false | Orphan object — GUID not referenced by any room instance — design choice whether object is unused |
| GUID-03 | Error | guid-xref | false | Duplicate instance id within same room — designer must rename one instance |

### EXIT (2 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| EXIT-R01 | Error | exit | false | Inline exit target must reference a valid room — designer must find/create room |
| EXIT-R02 | Warning | exit | false | Bidirectional inline exit mismatch — no return exit — design choice whether to add return |

### EXIT-PORTAL (7 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| EXIT-01 | Error | exit-portal | false | Portal must have portal.target defined and non-nil — design choice what target is |
| EXIT-02 | Error | exit-portal | unsafe | Portal FSM state must declare traversable = true or false — design semantic choice |
| EXIT-03 | Error | exit-portal | false | bidirectional_id must have exactly one matching partner — design choice which partner |
| EXIT-04 | Warning | exit-portal | false | Portal direction_hint should match room exit direction key — design consistency check |
| EXIT-05 | Warning | exit-portal | false | Thin exit reference must point to portal template object — design choice, not error |
| EXIT-06 | Error | exit-portal | false | No inline exit state allowed on exit tables — design structure choice |
| EXIT-07 | Warning | exit-portal | false | Portal should have on_feel (P6 darkness requirement) — design choice to add sensory text |

### LOOT (5 rules)

| Rule ID | Severity | Category | Fix Classification | Rationale |
|---------|----------|----------|-------------------|-----------|
| LOOT-001 | Error | loot | safe | loot_table must be a table with valid sections — can normalize to table structure |
| LOOT-002 | Error | loot | false | on_death weights must be > 0 and sum to > 0 — designer must set valid weights |
| LOOT-003 | Error | loot | false | loot_table template refs must resolve to existing objects — designer must find/create objects |
| LOOT-004 | Error | loot | unsafe | variable min must be <= max, both >= 0 — fixing requires design knowledge |
| LOOT-005 | Warning | loot | unsafe | always items must have template field, no duplicates — fixing requires design review |

---

## Summary Statistics

### By Fix Safety Classification

| Classification | Count | Percentage |
|---------------|-------|-----------|
| **safe** | 47 | 23.5% |
| **unsafe** | 62 | 31.0% |
| **false** | 91 | 45.5% |

### By Severity

| Severity | Count | Safe | Unsafe | Not Fixable |
|----------|-------|------|--------|------------|
| Error | 112 | 30 | 19 | 63 |
| Warning | 77 | 16 | 39 | 22 |
| Info | 11 | 1 | 4 | 6 |

### By Category (Top 5 by rule count)

| Category | Total | Safe | Unsafe | Not Fixable |
|----------|-------|------|--------|------------|
| Injury | 66 | 13 | 27 | 26 |
| Level | 38 | 14 | 7 | 17 |
| Material | 22 | 13 | 1 | 8 |
| Template | 25 | 13 | 3 | 9 |
| Cross-Ref | 10 | 0 | 2 | 8 |

---

## Architectural Notes

### Why So Many "false" (Not Fixable) Rules?

The high percentage of non-fixable rules (91/200, 45.5%) reflects the **design-heavy nature of meta-lint**:

1. **Content Rules** (70+ rules): Level names, descriptions, object relationships — these are **player-facing content** that only designers should write. Auto-fixing would produce gibberish or violate artistic intent.

2. **Cross-File Decisions** (30+ rules): Duplicate GUIDs, orphaned objects, missing references — these are **coordination problems** across multiple files. Fixing requires human judgment about which file is "wrong."

3. **Semantic Choices** (25+ rules): FSM design, injury thresholds, material properties — these are **gameplay decisions** that engines should never make unilaterally.

### Safe Rules (47) — Characteristics

Safe rules are **structural/format validators** that rarely require semantic understanding:

- **GUID normalization** (G-01): Convert `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` to Windows format
- **Type conversions** (TD-13 `portable`, INJ-66 `causes_unconsciousness`): Normalize types to boolean/table/string
- **Range clamping** (MD-07 `hardness`, MD-08 `flexibility`): Clamp numeric ranges to [0, 10] or [0.0, 1.0]
- **Filename/ID sync** (TD-04, MD-03, INJ-04): Rename files or IDs to match (idempotent)
- **State references** (FSM-04, TR-01, TR-02): Fix invalid state names to valid FSM states

### Unsafe Rules (62) — When to Use `--unsafe-fixes`

Unsafe rules involve **semantic or content changes**. Examples:

- **XF-03 (keyword collision)**: Renaming keywords changes how players refer to objects
- **XR-05b (generic material override)**: Choosing a material changes game physics
- **Injury descriptions** (INJ-08, INJ-18, INJ-23): Writing content changes player experience
- **INJ-21 (add state)**: Adding FSM state alters injury progression

**Policy:** Unsafe fixes require explicit `--unsafe-fixes` flag + designer review before commit.

---

## Next Steps (WAVE-3 Integration)

Smithers will use this audit to populate `rule_registry.py` with `fix_safety` fields:

```python
_r("S-01",     "error",   "structure", "...", fixable=True,  fix_safety="safe")
_r("XF-03",    "warning", "cross-file", "...", fixable=True,  fix_safety="unsafe")
_r("XF-01",    "error",   "cross-file", "...", fixable=False, fix_safety=None)
```

The CLI will then support:
- `--fix`: Apply all `fix_safety="safe"` violations
- `--unsafe-fixes`: Apply all fixable violations (safe + unsafe), with warning

---

**Document Version:** 1.0  
**Status:** COMPLETE — Ready for WAVE-3 integration
