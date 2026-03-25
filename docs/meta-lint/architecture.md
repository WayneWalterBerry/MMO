# Meta-Check: Architecture

**Date:** 2026-03-24  
**Version:** 1.0  
**Author:** Brockman (Documentation), technical specs from Bart  

---

## High-Level Pipeline

Meta-check is a **6-phase compiler pipeline** proven by Bart's Lark grammar prototype:

```
INPUT: Lua object/room/level files
  ↓
[Phase 1] Tokenization
  Lua source → custom tokenizer → token stream
  Handles: strings, comments, keywords, nesting depth
  ↓
[Phase 2] Preprocessing
  Strip preamble (local declarations, functions)
  Neutralize function bodies → __FUNC__ placeholders
  ↓
[Phase 3] Lark Earley Parser
  Tokenized source → AST (nested table structure)
  Grammar: return { key = value, ... } with arrays, booleans, nil
  ↓
[Phase 4] Semantic Analysis
  Validate AST against template-specific schemas
  Check required fields, field types, value ranges
  Check FSM consistency (states reachable, transitions valid)
  ↓
[Phase 5] Cross-File Analysis
  GUID uniqueness (no duplicate IDs across all objects)
  Keyword collisions (no exact duplicates per material)
  Reference resolution (type_id → guid, exit targets, material references)
  ↓
[Phase 6] Error Reporter
  Collect all violations → structured output
  Format: file, line, severity (🔴 ERROR / 🟡 WARNING / 🟢 INFO)
         rule ID, message, suggestion
OUTPUT: Exit code (0=pass, 1=errors, 2=warnings only)
```

---

## Phase 1: Tokenization

**Purpose:** Convert raw Lua source into a token stream, preserving position information for error reporting.

**Input:** Lua source string  
**Output:** List of (type, value, position) tuples

**Token Types:**
- **WS** — Whitespace (spaces, tabs, newlines)
- **COMMENT** — Line comments (`--`) or block comments (`--[[...]]`)
- **STRING** — Quoted strings (`"..."` or `'...'`) or long strings (`[[...]]`)
- **NUMBER** — Integers, floats, hex, scientific notation
- **KEYWORD** — Lua keywords (`function`, `end`, `if`, `return`, etc.)
- **IDENT** — Identifiers (`candle`, `on_feel`, etc.)
- **PUNCT** — Operators (`{`, `}`, `=`, `,`, etc.)

**Challenges Handled:**
- Escape sequences in strings
- Nested block comments (`--[[--[[...]]]]`)
- String concatenation operator (`..`)
- Hex numbers and scientific notation

**Example:**
```lua
-- Input:
return { id = "candle", on_feel = "Waxy." }

-- Output tokens:
KEYWORD(return), PUNCT({), IDENT(id), PUNCT(=), STRING("candle"), ...
```

---

## Phase 2: Preprocessing

**Purpose:** Normalize the token stream for the Lark parser by:
1. Removing preamble (local declarations, helper functions)
2. Neutralizing function bodies (opaque to static analysis)
3. Stripping comments and whitespace

**Phase 2a: Strip Preamble**

Many object files have local function declarations before the main `return`:

```lua
-- nightstand.lua
local function look_with_top(context, ...)
    -- complex logic
end

return {
    guid = "...",
    id = "nightstand",
    on_look = look_with_top,
    -- ...
}
```

The tokenizer tracks block depth (`function`/`if`/`for`/`end` nesting) to find the **top-level `return`** (depth = 0), then strips everything before it.

**Phase 2b: Neutralize Functions**

Function bodies are opaque to static analysis (Lua runtime validates the logic). Replace them with `__FUNC__` placeholder:

```lua
-- Before:
on_feel = function(context) return "Waxy." end,
on_look = function(ctx) ... end,

-- After:
on_feel = __FUNC__ ,
on_look = __FUNC__ ,
```

This allows the Lark grammar to parse the table structure without tracking Lua control flow inside functions.

**Phase 2c: Strip Whitespace & Comments**

Reduce token stream by removing WS and COMMENT tokens. Output is space-joined tokens.

**Example:**
```lua
-- Input (with preamble):
local function helper() return "X" end
return { id = "x", name = "X" }

-- After strip_preamble():
return { id = "x", name = "X" }

-- After neutralize_functions():
return { id = "x", name = "X" }

-- After full preprocessing():
return{id=x,name=X}  (conceptually)
```

---

## Phase 3: Lark Earley Parser

**Purpose:** Parse the preprocessed Lua token stream into an Abstract Syntax Tree (AST).

**Grammar (simplified):**
```
start: "return" table

table: "{" "}"
     | "{" field_list "}"

field_list: field ("," field)* ","?

field: NAME "=" value          → named_field
     | "[" value "]" "=" value → bracket_field
     | value                   → positional_field

?value: DQ_STRING              → string_val
      | SQ_STRING              → string_val
      | LONG_STRING            → string_val
      | NUMBER                 → number_val
      | "-" NUMBER             → neg_number_val
      | "true"                 → true_val
      | "false"                → false_val
      | "nil"                  → nil_val
      | table
      | "__FUNC__"             → func_placeholder
      | NAME                   → ident_ref
```

**Key Features:**
- Handles nested tables (states, transitions, mutations, parts)
- Supports arrays (keywords, categories, aliases)
- Allows trailing commas (Lua-style: `{1, 2, 3,}`)
- Tracks identifier references (`wall-clock` pattern: `states = states`)
- Passes function bodies as opaque `__FUNC__` nodes

**Parser Algorithm:** Earley parser (handles ambiguous grammars gracefully)

**Output:** Tree structure representing the entire object:
```
start
  table
    field_list
      named_field: id, "candle"
      named_field: name, "a tallow candle"
      named_field: on_feel, __FUNC__
      named_field: states, table
        field_list
          named_field: lit, table
            ...
          named_field: unlit, table
            ...
```

---

## Phase 4: Semantic Analysis

**Purpose:** Validate the AST against template-specific schemas.

**Inputs:**
- AST from Phase 3
- Object's declared template (e.g., `template = "small-item"`)
- Schema definitions for that template (Phase 5 describes schemas)

**Validation Steps:**

1. **Extract fields from AST**
   - Traverse field_list nodes, extract (name, value_type, value)
   - Record position (line, column) for each field

2. **Check required fields**
   - For `small-item`: must have `guid`, `id`, `name`, `size`, `weight`, `material`
   - For `container`: additionally must have `capacity`, `contents`
   - For `furniture`: no additional requirements, but `portable = false` is typical
   - For `room`: must have `exits`, `instances`, `description`

3. **Validate field types**
   - `guid` → string, matches UUID regex
   - `size`, `weight`, `capacity` → number, positive
   - `keywords` → array of strings
   - `container` → boolean
   - `portable` → boolean
   - `material` → string (stored for Phase 5 cross-check)

4. **Validate FSM if present**
   - If object has `states` table: check `initial_state` value
   - Verify `initial_state` is a key in `states` table
   - For each transition in `transitions` array:
     - Verify `from` and `to` reference existing states
     - Verify `verb` is a non-empty string
   - Detect orphan states (no path leads to them from `initial_state`)
   - Detect dead-end non-terminal states (no transitions out, `terminal != true`)

5. **Validate sensory fields**
   - All objects must have `on_feel` (primary sense in darkness) — 🔴 ERROR
   - Other senses (`on_smell`, `on_listen`, `on_taste`) recommended but optional — 🟡 WARNING

6. **Validate mutations if present**
   - For each mutation: `becomes` and `spawns` fields stored for Phase 5 resolution

**Output:** List of violations (file, line, field, error message)

---

## Phase 5: Cross-File Analysis

**Purpose:** Validate references across the entire `src/meta/` directory.

**Inputs:**
- All object ASTs (Phase 4 complete)
- All room definitions
- Material registry (`src/engine/materials/init.lua`)
- Template registry (`src/meta/templates/`)

**Validation Checks:**

1. **GUID Uniqueness**
   - Collect all `guid` values from all objects
   - Verify no duplicates
   - Verify all GUIDs match UUID format (with or without braces)
   - Report: `DUPLICATE_GUID: guid 'X' appears in candle.lua and torch.lua`

2. **Material Reference Validation**
   - For each object's declared `material`:
     - Verify material exists in `src/engine/materials/init.lua`
     - Report: `UNKNOWN_MATERIAL: 'adamantium' not in registry`

3. **Template Reference Validation**
   - For each object's `template`:
     - Verify template file exists in `src/meta/templates/`
     - Report: `UNKNOWN_TEMPLATE: 'mega-item' not found`

4. **Room Type-ID Resolution**
   - For each room file's `instances` array:
     - For each instance with `type_id`:
       - Verify an object with matching `guid` exists
       - Report: `TYPE_ID_MISMATCH: room 'start-room' instance 'candle' type_id 'X' has no matching object guid`

5. **Exit Target Resolution**
   - For each room's `exits` table:
     - For each exit with `target`:
       - Verify a room with matching `id` exists OR mark as PENDING (planned expansion)
       - Report: `UNRESOLVED_EXIT: hallway→level-2 (PENDING future content)`

6. **Mutation Target Resolution**
   - For each object's mutation `becomes`:
     - Verify object with that `id` exists
     - Report: `MUTATION_TARGET_NOT_FOUND: candle mutation 'break' references 'candle-broken' which doesn't exist`
   - For each mutation `spawns` array:
     - Verify each spawned object exists
     - Report: `SPAWN_TARGET_NOT_FOUND: ...`

7. **Keyword Collision Detection**
   - Build keyword index: (keyword, material) → object
   - For each keyword/material pair:
     - If appears on 2+ objects, flag as collision
     - Report: `KEYWORD_COLLISION: 'brass bowl' appears on brass-spittoon and candle-holder`

**Output:** List of cross-file violations

---

## Phase 6: Error Reporter

**Purpose:** Format all violations into structured output for CI and human review.

**Error Format:**
```
{file} : {line} : {severity} : {rule_id} : {message} : {suggestion}
```

**Example Output:**
```
src/meta/objects/candle.lua : 5 : ERROR : S-01 : missing guid field : add guid = "..." (Windows GUID format)
src/meta/objects/candle.lua : 12 : ERROR : S-04 : missing id field : add id = "candle" (kebab-case)
src/meta/objects/candle.lua : 20 : ERROR : SF-REQ-ON_FEEL : on_feel required : every object needs tactile description
src/meta/objects/candle.lua : 25 : WARNING : S-05 : id has uppercase : change id = "Candle" to id = "candle"
src/meta/rooms/start-room.lua : 10 : WARNING : UNRESOLVED_EXIT : hallway→level-2 : marked PENDING (planned future expansion)
src/meta/ : global : ERROR : DUPLICATE_GUID : guid 'abc-123' appears in candle.lua and candle-broken.lua
```

**Exit Codes:**
- **0** — All checks passed
- **1** — Errors found (must fix before merge)
- **2** — Warnings only (author should review, but non-blocking)

**Output Modes:**
- **Human-readable** — Pretty-printed with colors (terminal)
- **JSON** — Machine-parseable (CI integration)
- **TAP** — Test Anything Protocol (pre-commit hooks)

---

## Key Technical Decisions

### Why Python + Lark?

1. **Proven:** Lark successfully parsed **83/83 objects** in Bart's prototype
2. **Robust:** Earley parser handles ambiguities gracefully
3. **Extensible:** Grammar can expand to room files, level files, future formats
4. **Zero dependencies:** No external Lua runtime required (Fengari-compatible)
5. **Easy CI integration:** Python is standard in CI pipelines

### Why Function Bodies Are Opaque

**Observation:** 82/83 objects are pure data tables. Function bodies (`on_look`, `on_feel`, `factory`) contain game logic that Lua validates at runtime. Meta-check validates the **data layer** only.

**Implication:** Wall-clock.lua (the 1 programmatic outlier) is treated as "pass-through"—meta-lint can't validate computed values, only the Lua runtime can.

### Why Lark Over PEG / Antlr / Hand Parser

| Tool | Pros | Cons |
|------|------|------|
| **Lark** | Earley handles ambiguity, clean grammar, proven on 83 objects | Slight startup overhead |
| **PEG** | Fast, simple | Ambiguity causes silent failures, backtracking issues |
| **Antlr** | Industrial-strength | Overkill, Java dependency |
| **Hand-parser** | No dependencies | Fragile, hard to extend |

---

## Performance Characteristics

| Phase | Time (est.) | Complexity |
|-------|------------|-----------|
| Phase 1: Tokenization | 10 ms | O(n) — linear in source size |
| Phase 2: Preprocessing | 5 ms | O(n) — single pass |
| Phase 3: Lark Parse | 20 ms | O(n) — depends on ambiguity |
| Phase 4: Semantic | 50 ms | O(n × m) — per-object, m fields |
| Phase 5: Cross-file | 100 ms | O(n²) worst case (keyword collisions) |
| Phase 6: Reporting | 10 ms | O(violations) |
| **Total** | ~195 ms | Fast enough for pre-commit |

**Optimization opportunities:**
- Cache parse trees for unchanged files (pre-commit hook)
- Parallelize object validation (Phase 4)
- Build keyword index with hash-based dedup (Phase 5)

---

## Error Recovery & Reporting

Meta-check is **not a fail-fast validator**. It collects **all violations** and reports them together:

```
Example: Run on a completely broken object

src/meta/objects/broken.lua
  Line 1: ERROR S-02 — missing guid
  Line 3: ERROR S-04 — missing id
  Line 5: ERROR S-06 — missing name
  Line 7: ERROR S-10 — keywords is not a table
  (global) ERROR CROSS-FILE FAIL: candle references non-existent template
  (global) ERROR CROSS-FILE FAIL: candle has unknown material "fake-metal"
```

This allows developers to fix multiple issues in a single pass.

---

## References

- **Lark Documentation:** https://lark-parser.readthedocs.io/ (Earley parser, tree patterns)
- **Bart's Grammar Prototype:** `scripts/meta-lint/lua_grammar.py` (~420 lines, battle-tested on 83 objects)
- **Acceptance Criteria (Lisa):** `docs/meta-lint/acceptance-criteria.md` (144 rules across 15 categories)

