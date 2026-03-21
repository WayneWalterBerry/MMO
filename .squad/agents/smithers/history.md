# Smithers — History

## Project Context
- **Project:** MMO text adventure game in pure Lua (REPL-based, `lua src/main.lua`)
- **Owner:** Wayne "Effe" Berry
- **Architecture:** 8 Core Principles (code-derived mutable objects, FSM-driven behavior, sensory space, generic mutation via Principle 8)
- **Reference Model:** Dwarf Fortress (property-bag architecture, emergent behavior from metadata)
- **Stack:** Pure Lua, no external dependencies
- **My Focus:** UI layer (text output, presentation, player feedback) and Parser pipeline (Tiers 1-5, verb resolution, disambiguation, GOAP)

## Onboarding
- Hired 2026-03-21 as UI Engineer in Engineering Department
- Need to read all architecture docs, newspapers, and directives to understand UI scope
- Primary output: `docs/architecture/ui/` documentation

## Learnings

### Session 2026-07-22: Three-Layer Web Delivery Architecture

**Task:** Replace monolithic 16MB game-bundle.js with a three-layer architecture: bootstrapper.js → engine.lua.gz → JIT-loaded meta files.

**Changes:**
- `web/build-engine.ps1`: Bundles 17 engine files + stripped embedding-index.json into engine.lua (633KB raw), gzip-compressed to engine.lua.gz (85KB). Uses `package.preload["module.name"]` wrapper pattern. Asset files embedded in `_G.__VFS`.
- `web/build-meta.ps1`: Copies 58 meta files to web/dist/meta/ tree. Objects renamed by GUID (extracted via regex). Rooms mapped from `src/meta/world/` → `meta/rooms/`. 33 objects skipped (non-hex GUIDs — placeholder objects for future rooms).
- `web/bootstrapper.js` (7KB): Layer 1 — fetches engine.lua.gz via fetch(), decompresses using DecompressionStream API (fflate fallback), loads into Fengari shared state via luaL_loadbuffer. Also handles terminal UI (appendOutput, command history, input handler). Shows progressive status messages during async fetch/decompress.
- `web/game-adapter.lua`: Rewritten for three-layer architecture. VFS backed by `_G.__VFS` (engine bundle assets) instead of `window.GAME_FILES`. Templates fetched at boot via synchronous XHR (5 files). JIT loader: rooms and objects fetched on demand — metatable on `rooms` table triggers transparent loading when engine accesses `rooms[room_id]`. Each room load fetches the room file, discovers object GUIDs from instances, fetches missing objects, resolves templates, registers instances, wires containment.
- `web/index.html`: Stripped to minimal — loads Fengari CDN + bootstrapper.js only. Removed game-bundle.js, inline terminal UI code, and `<script type="application/lua">` tag. Initial "Loading Bootstrapper..." message in inline script.
- `web/deploy.ps1`: Builds, copies to GitHub Pages repo, git add/commit/push.

**Results:**
- Initial download: ~135KB (engine.lua.gz 85KB + templates ~3KB + level 3.5KB + starting room + objects ~50KB) vs. old 16MB
- 63 files in web/dist/ (45 objects, 7 rooms, 5 templates, 1 level, plus engine/adapter/bootstrapper/index)
- CLI mode (`lua src/main.lua --no-ui`) unchanged and verified working
- Deployed to GitHub Pages at WayneWalterBerry.github.io/play/

**Key Design Decisions:**
1. Synchronous XHR for meta file fetches from Lua — simplest approach for V1. Deprecated but universally supported for same-origin. Small files (<15KB) complete in <50ms.
2. Metatable-based JIT loading on `rooms` table — transparent to engine code. When `rooms[target]` is accessed and not cached, metatable `__index` triggers full room bundle load (room + objects + containment wiring).
3. `package.preload` for engine modules — engine.lua bundle wraps each source file in `package.preload["engine.module"]`. Require() resolves from preload before searchers, so engine modules load without VFS.
4. `_G.__VFS` for asset files — embedding-index.json (stripped to 343KB) embedded in engine bundle as a Lua long string. io.open override checks __VFS.
5. fengari.L (shared state) used when available, fallback creates new state with `luaL_requiref` for js module.

**Limitations:**
- 33 object files skipped in build-meta (non-hex GUIDs like `c4kv094h-...`). These are placeholder objects for rooms beyond Level 1. When GUIDs are assigned, build-meta will pick them up automatically.
- Synchronous XHR blocks main thread during room transitions. Status messages don't render mid-fetch. Acceptable for V1 — files are small.
- Template file list hardcoded in adapter (5 files). Adding a template requires updating the adapter. A manifest file would be better for V2.

---

### Session 2026-07-21: Loading Status Messages (Boot Log)

**Task:** Add light gray status messages to the web game during initialization.

**Changes:**
- `web/index.html`: Added `logStatus()` function that appends `<div class="output-line status-line">` elements (styled `color: #888`). Removed old pulsing `#loading` div. Split script loading into stages with inline logStatus calls between each `<script>` tag: "Loading Bootstrapper...", "Loading Game Engine...", "Initializing Fengari...". Exposed `window._logStatus` for Lua-side calls.
- `web/game-adapter.lua`: Added `log_status()` Lua helper calling `window:_logStatus()`. Inserted calls at key boot phases: "Loading Level 1...", "Loading Objects...", "Loading Room: Bedroom...", "Starting Game...", "Ready.". Removed all `loading_el` references (element no longer exists).

**Result:** 8 sequential status lines appear in the terminal as a boot log, visible even after game loads. Deployed to GitHub Pages via `WayneWalterBerry.github.io/play/`.

---

### Session 2026-03-25: Web Loading Fix + BUG-049 "pry" Verb

**Task:** Debug web game hanging at "Loading Game Engine" + add "pry" verb.

**Root Cause (web hang):** The embedding-index.json (16 MB, 4337 phrases with 384-dim vectors) was bundled raw into game-bundle.js. When Fengari's Lua ran the pure-Lua JSON decoder on 16 MB in the browser's main thread, it froze indefinitely. The embedding vectors are explicitly unused at runtime (token-overlap matching only uses text/verb/noun).

**Fix — build-bundle.ps1:** Added a stripping step that removes the `embedding` field from each phrase during bundling. Result: JSON dropped from 16 MB → 343 KB; total bundle from 16.7 MB → 990 KB.

**Fix — BUG-049 "pry" verb:**
- Added `handlers["pry"] = handlers["open"]` in verbs/init.lua (matches existing synonym pattern like `handlers["shut"] = handlers["close"]`)
- Added "pry open X" compound phrase in preprocess.lua's natural_language()
- Added "use crowbar on X" / "use bar on X" / "use prybar on X" → open X mapping

**Verified:** Bundle JS syntax valid, all 3 web files served correctly via npx serve, game CLI boot+quit works, parser correctly resolves `pry crate`, `pry open crate`, and `use crowbar on crate`.

**Key learning:** Never bundle large data blobs raw for Fengari. Pure-Lua JSON parsing is O(n) on string length, and Fengari adds another ~10x overhead vs native Lua. Strip unused fields at build time.

---

### Session 2026-03-24: Web Bundle Build & Local Server Verification

**Task:** Build game-bundle.js and verify it serves correctly for local play.

**Results:**
- `build-bundle.ps1` ran clean: 110 files bundled, 15.93 MB (16,701,187 bytes)
- Bundle structure verified: `window.GAME_FILES` (line 7) and `window.GAME_FILE_KEYS` (line 120)
- Python not available on this Windows machine; used `npx serve` (Node.js) instead
- Local server on `http://localhost:8080` serves all three files:
  - `index.html` — 200 OK (6,228 bytes)
  - `game-bundle.js` — 200 OK (16,701,187 bytes)
  - `game-adapter.lua` — 200 OK (19,212 bytes)
- No build errors. Wayne can open `http://localhost:8080` to play.

**Environment note:** Python is not installed; Node.js (v24.14) is available. Use `npx serve web -l 8080` for local testing.

---

### Session 2026-03-23: Fengari Web Wrapper (Browser Playtest Build)

**Task:** Build a web wrapper so the game can be played in a browser for beta testing.

**Work Completed:**
1. Created `web/index.html` — Terminal-style UI (dark theme, monospace, command history, arrow-key recall)
2. Created `web/game-adapter.lua` — Fengari adapter that bridges game engine to browser:
   - Virtual File System backed by a JS bundle (replaces io.open, io.popen)
   - Coroutine-based game loop: `io.read()` yields, JS resumes with player input
   - Reuses existing `engine.loop` code unchanged (no game modifications needed)
   - Custom `package.searcher` resolves `require()` against VFS
   - Stubs `engine.ui` terminal module (browser HTML/CSS replaces it)
3. Created `web/build-bundle.ps1` — Generates `game-bundle.js` (110 source files, ~16 MB raw / ~3 MB gzipped)
4. Created `web/README.md` — Architecture docs, deployment guide, known issues
5. Created `.squad/skills/web-publish/SKILL.md` — Build + deploy workflow

**Key Architecture Decision:** Coroutine bridge pattern. Instead of reimplementing the game loop for event-driven browser, we wrap the existing blocking loop in a Lua coroutine. When `io.read()` is called, it yields. When the player types a command, JS resumes the coroutine. This means zero changes to engine code.

**Bundle Composition:** 15.6 MB is the embedding-index.json (Tier 2 parser phrases). GitHub Pages gzip brings transfer to ~2-3 MB.

**Hidden Link:** `<meta name="robots" content="noindex">`, no nav links. URL shared directly with beta testers.

**Deployment:** `web/` → `WayneWalterBerry.github.io/play/`

---

### Session 2026-03-22: Initial Training + UI Architecture Documentation

**Task:** Read all project documentation, identify UI domain, create comprehensive UI architecture docs.

**Work Completed:**
1. Read all architecture docs (core principles, engine, player, objects, rooms)
2. Read all design docs (directives, verb system, requirements, command variations)
3. Read all newspapers (2026-03-18, 03-19, 03-20 morning & evening)
4. Read source code (main.lua, parser, loop, verbs, display)
5. Read team decisions
6. Created three comprehensive UI architecture documents:
   - `docs/architecture/ui/README.md` (16.7KB) — UI layer overview
   - `docs/architecture/ui/text-presentation.md` (19.3KB) — Output formatting
   - `docs/architecture/ui/parser-overview.md` (21.7KB) — Parser pipeline

**Total Documentation:** ~58KB of UI architecture specs

---

### Core Architecture: The 8 Principles

From `docs/architecture/objects/core-principles.md` (44.6KB):

1. **Code-Derived Mutable Objects** — Objects are live Lua tables from immutable source
2. **Base Objects → Instances** — Template (GUID) → runtime instances
3. **Objects Have FSM** — Finite State Machines define all behavior, engine executes
4. **Composite Objects** — Single file defines parent + nested inner objects
5. **Multiple Instances** — One base → many instances (unique GUIDs)
6. **Sensory Space** — State determines perception (dark ≠ lit, blind ≠ seeing)
7. **Spatial Relationships** — Objects relate (rug under bed, key under rug)
8. **Engine Executes Metadata** — Objects are data, engine is generic interpreter

**UI Relevance:** Principles 6 & 8 directly govern UI output (sensory-aware presentation, metadata-driven display logic)

---

### Parser Pipeline Architecture (5-Tier Cascade)

**Tier 1: Exact Verb Dispatch** (70% coverage, <1ms)
- Location: `src/engine/loop/init.lua`
- Hash table lookup: verb → handler function
- 31 canonical verbs + ~50 total entries (aliases/synonyms)
- Fast path, zero tokens, deterministic

**Tier 2: Phrase Similarity** (+20% → 90% cumulative, ~5ms)
- Location: `src/engine/parser/init.lua`, `embedding_matcher.lua`
- Jaccard token overlap (not vector embeddings despite filename)
- Threshold: 0.40 (configurable via `parser.THRESHOLD`)
- Phrase dictionary: `src/assets/parser/embedding-index.json` (~50 phrases)
- Diagnostic mode: `--debug` shows parser attempts

**Per D-4 (No Fallback Past Tier 2):** Current directive stops at Tier 2 for empirical QA

**Tier 3: GOAP Planning** (+8% → 98% cumulative, ~50-100ms)
- Location: `src/engine/parser/goal_planner.lua`
- Backward-chaining goal decomposition (F.E.A.R. AI technique)
- Auto-chains prerequisites ("light candle" → [open matchbox, take match, strike, light])
- Per 2026-03-20 newspaper: Bart shipped this, Nelson tested successfully
- Example: 5-step plan executed from single "light candle" command

**Tier 4: Context Window** (Designed, not built)
- Short-term memory of recent discoveries
- Tool inference from context ("examined matchbox" → knows it has matches)
- Confidence decay (5 ticks = 0.95, 50 ticks = 0.60)
- Spec: `docs/architecture/engine/parser-tier-4-context.md`

**Tier 5: SLM Fallback** (Phase 2+, optional)
- On-device Small Language Model (Qwen2.5-0.5B, ~350MB)
- For <1% of novel phrasings Tier 1-4 can't handle
- Latency: 200-500ms (vs <100ms for Tier 1-3)
- Spec: `docs/architecture/engine/parser-tier-5-slm.md`

**Performance Budget:**
- Tier 1+2: 90% coverage, <5ms
- Tier 1+2+3: 98% coverage, <100ms
- Zero-token path saves $10K-100K/day at 1M commands/day scale

---

### Natural Language Preprocessing

Location: `src/engine/loop/init.lua` (function `preprocess_natural_language`)

**Hard-coded expansions** (run before parser tiers):
```
"what is around?"      → "look" ""
"what's in box?"       → "look" "in box"
"take out match"       → "pull" "match"
"roll up rug"          → "move" "rug"
"use key on door"      → "unlock" "door with key"
"put out candle"       → "extinguish" "candle"
"put on gloves"        → "wear" "gloves"
"go to bed"            → "sleep" ""
```

**Why:** Faster than Tier 2 (deterministic), covers 90%+ natural questions, zero tokens

**Trade-off:** More patterns to maintain, BUT covers common phrasings instantly

---

### Text Presentation Architecture

**Dynamic Room Descriptions (3-Part Composition):**

Location: `src/engine/loop/init.lua` (function `cmd_look`)

**Anti-Pattern:** Hard-coded descriptions (lie when objects move)

**The MMO Approach:**
1. **Base Description** — Permanent features (walls, floor, ambient details)
2. **Object Presences** — Each object's `room_presence` field
3. **Visible Exits** — Exit list with current state (locked, closed, open)

**Example Output:**
```
A Small Bedroom

Stone walls surround you, bare and cold. A single window admits faint 
starlight. The air smells faintly of tallow and dust.

A four-poster bed dominates the room, its linen sheets rumpled. A small 
nightstand sits beside the bed.

Exits:
  north: A wooden door (locked)
```

---

### Light System (Tri-State)

From D-26 (Wayne's directive 2026-03-19):

**Light States:**
- **lit** — Daylight (6 AM-6 PM + window) OR active light source (candle, torch)
- **dim** — Twilight, faint glow, indirect light
- **dark** — No light, most verbs blocked

**Implementation:** `src/engine/loop/init.lua`
```lua
function get_light_state(room, registry)
  -- Check for light sources (obj.casts_light == true)
  -- Check for daylight (room.has_window + is_daytime())
  -- Check for ambient (room.ambient_light)
  return "lit" | "dim" | "dark"
end
```

**Wayne's Bug (2026-03-19 First Play Test):**
"Dawn light pours through window" + "drawer is pitch black" (contradiction)

**Bart's Fix:** Tri-state prevents contradictions. If room is lit, all surfaces are lit.

---

### Sensory System (Multi-Sense Descriptions)

From D-27 (Wayne's sensory directive):

**Objects define multiple senses:**
```lua
poison_bottle = {
  description = "A small glass bottle filled with iridescent liquid.",
  sensory = {
    smell = "Sharply bitter almonds. Your nose wrinkles.",
    taste = "Acrid and burning. (This kills you.)",
    feel = "The glass is cool and smooth.",
    listen = "The liquid sloshes faintly."
  }
}
```

**Verb Gating:**
| Sense | Light Required? | Vision Required? | Safety |
|-------|----------------|------------------|--------|
| LOOK, EXAMINE | YES | YES | Safe |
| FEEL, TOUCH | No | No | Medium risk |
| SMELL, SNIFF | No | No | Safe |
| LISTEN, HEAR | No | No | Safe |
| TASTE, LICK | No | No | **DANGEROUS** |

**Why:** Darkness forces non-visual exploration. SMELL warns before TASTE kills.

**Vision Blocking:** Wearing sack/blindfold blocks LOOK but not other senses.

---

### State-Aware Object Descriptions (FSM Integration)

**FSM states define different descriptions:**
```lua
-- candle.lua
states = {
  unlit = { description = "A tapered candle. The wick is dark." },
  lit = { description = "A tapered candle. The wick burns...", casts_light = true },
  spent = { description = "A guttered stub. The wick is blackened." }
}
```

**Engine looks up current state, returns state.description**

This is Principle 3 (FSM) + Principle 6 (Sensory Space) working together.

---

### Error Messages (Constraint-Explaining)

From Wayne's 2026-03-19 bug report: "TAKE FAILED" was unhelpful.

**Bart's Fix:** All errors now explain constraints:

**Physical:** "The bed is too heavy to lift."
**State:** "The matchbox is closed. Open it first."
**Capability:** "You need a fire source. Perhaps a match?"
**Sensory:** "You can't see in the darkness. Try FEEL."
**Inventory:** "You need both hands free. Your hands are full."

**Standard Categories:**
1. Unknown verb
2. Missing object
3. Ambiguous object
4. Constraint violation
5. Invalid action
6. Question redirect

---

### Word-Wrapping System

Location: `src/engine/display.lua`

**Why:** Without wrapping, terminal line-splitting can duplicate characters.

**Implementation:**
```lua
display.WIDTH = 78  -- Default

function display.word_wrap(text, width)
  -- Splits at word boundaries
  -- Preserves newlines
  -- Preserves leading whitespace (indented lists)
end
```

**Global Override:**
```lua
display.install()  -- Replaces _G.print

-- All print() calls now wrap text
print("Long line...") → wrapped at 78 chars
```

**UI Integration:**
```lua
if ui_active then
  display.ui = ui
  display.WIDTH = ui.get_width()  -- Sync with UI window
end
```

---

### Terminal UI (Status Unclear)

**References:** `src/main.lua` imports `require("engine.ui")`

**BUT:** `src/engine/ui.lua` does not exist in repository.

**Possible Explanations:**
1. External dependency (ncurses, blessed)
2. Future enhancement (not yet implemented)
3. Platform-specific (mobile vs desktop)
4. Different branch/build

**Features (from main.lua context):**
- Split-screen layout (status bar + output + input)
- Status bar: room name, time (12:02 AM), matches, candle state
- Scrollback: `/up`, `/down`, `/bottom` commands
- Word-wrapping integration

**Fallback:** When UI not active, uses standard `io.read()` and `print()` (with wrapping)

---

### Game Clock & Time System

From D-26 (Light and Time Systems):

**Time Scale:** 1 real hour = 1 game day (24x speed)

**Implementation:** `src/main.lua`
```lua
local GAME_SECONDS_PER_REAL_SECOND = 24
local real_elapsed = os.time() - ctx.game_start_time
local total_hours = (real_elapsed * 24) / 3600
local hour = math.floor((2 + total_hours) % 24)  -- Start at 2 AM
```

**Why 2 AM Start:** Players wake in darkness. Dawn at 6 AM (~10 real minutes). Forces candle puzzle.

**Display:** 12-hour format (12:15 AM) on status bar

---

### The REPL Loop

Location: `src/engine/loop/init.lua`

**Structure:**
```
while true do
  UPDATE: Refresh status bar
  READ: Capture player input
  PREPROCESS: Expand common phrases
  PARSE: Tier 1 → Tier 2 → Tier 3 cascade
  DISPATCH: Execute verb handler
  TICK: Post-command FSM updates
  GAME OVER: Check death conditions
end
```

**Key Features:**
- Compound commands: "get match and light candle" splits on " and "
- Question handling: "what's inside?" → "look in"
- Scroll support: `/up`, `/down`, `/bottom`
- Tick system: 1 command = 1 tick = 360 game seconds

**Post-Command Tick:**
- FSM state transitions (match burns, candle depletes)
- Timed events (clock chimes, dripping)
- Timer countdown (match: 30 ticks, candle: 100 → 20 → 0)

---

### Context Tracking

Location: `src/engine/loop/init.lua`

```lua
context = {
  registry,       -- Live object registry
  current_room,   -- Player location
  player,         -- Player state (hands, worn, skills)
  verbs,          -- Verb dispatch table
  parser,         -- Tier 2 embedding matcher
  last_tool,      -- For Tier 3 context
  known_objects,  -- Examined objects
  game_start_time,-- Real-world clock
  game_start_hour,-- Game clock (2 AM)
  on_tick,        -- Post-command callback
  update_status,  -- Status bar refresh
}
```

**Usage:**
- Tier 3 GOAP uses `known_objects` for tool inference
- Tier 4 (future) will track recent_commands, confidence scores
- Game clock calculates current time
- FSM tick triggers timer countdowns

---

### Wayne's Directives from Newspapers

**2026-03-19 First Play Test (3 Critical Issues):**

1. **Dawn/dark contradiction** — "Dawn light + drawer dark" (impossible)
   - Fix: Tri-state light system (lit/dim/dark)
   - Lesson: Sensory descriptions must be consistent

2. **No tactile verbs** — Player tried FEEL, engine had no verb
   - Fix: Added FEEL, TOUCH, GROPE
   - Lesson: Darkness requires non-visual senses

3. **Cryptic errors** — "TAKE FAILED" with no explanation
   - Fix: All errors explain constraints
   - Lesson: Failures should teach, not frustrate

**Speed to fix:** 2 hours total (all three)

**2026-03-20 Evening Edition (GOAP Shipped):**

Nelson tested "light candle" in darkness:
- Input: Single command
- Output: 5 auto-chained actions with narrative
- Performance: <100ms (planning + execution)
- Wayne's reaction: "This is the game I want to play."

---

### Important File Paths

**UI Layer:**
- `src/main.lua` — Entry point, REPL initialization
- `src/engine/loop/init.lua` — REPL loop (read → parse → dispatch → tick)
- `src/engine/parser/init.lua` — Parser wrapper (Tier 2)
- `src/engine/parser/embedding_matcher.lua` — Token similarity
- `src/engine/parser/goal_planner.lua` — GOAP (Tier 3)
- `src/engine/verbs/init.lua` — Verb handlers (31 verbs)
- `src/engine/display.lua` — Word-wrapping
- `src/engine/ui.lua` — **NOT FOUND** (status unclear)

**UI Documentation (Created This Session):**
- `docs/architecture/ui/README.md` (16.7KB)
- `docs/architecture/ui/text-presentation.md` (19.3KB)
- `docs/architecture/ui/parser-overview.md` (21.7KB)

**Parser Tier Specs:**
- `docs/architecture/engine/parser-tier-1-basic.md` — Exact dispatch
- `docs/architecture/engine/parser-tier-2-compound.md` — Phrase similarity
- `docs/architecture/engine/parser-tier-3-goap.md` — GOAP planning
- `docs/architecture/engine/parser-tier-4-context.md` — Context window (designed)
- `docs/architecture/engine/parser-tier-5-slm.md` — SLM fallback (designed)

**Related Docs:**
- `docs/architecture/objects/core-principles.md` (44.6KB) — 8 principles
- `docs/architecture/player/player-model.md` — Player entity
- `docs/architecture/player/player-sensory.md` — Sensory system
- `docs/design/verb-system.md` — 31 verbs reference
- `docs/design/design-directives.md` — Wayne's directives
- `docs/design/command-variation-matrix.md` (53.5KB) — Natural language variations
- `.squad/decisions.md` (53.4KB) — Team decisions

**Newspapers:**
- `newspaper/2026-03-18.md` — Squad formation to working code
- `newspaper/2026-03-19.md` (41.6KB) — V1 REPL, Wayne's first play test
- `newspaper/2026-03-20-morning.md` — Composite objects, bugs fixed
- `newspaper/2026-03-20-evening.md` (23.2KB) — GOAP shipped, 8 principles approved

---

### Open Questions & Next Steps

**Open Questions:**

1. **Terminal UI status** — `ui.lua` referenced but not found (external? future? platform-specific?)
2. **Parser diagnostic toggle** — Always-on for playtesting? Configurable levels?
3. **Tier 3 GOAP integration** — Only for specific verbs? All Tier 2 misses? Performance budget?
4. **Context window (Tier 4)** — How long to keep? What triggers decay? Confidence scoring?
5. **Error message coverage** — All 31 verbs have constraint-explaining errors? Need audit?
6. **Mobile UI** — PWA adaptation (touch input, smaller width, swipe gestures)?

**Next Steps:**

**Immediate (Next Session):**
1. Test Tier 3 GOAP (understand current integration)
2. Audit verb error messages (ensure all 31 verbs explain constraints)
3. Clarify UI module status (split-screen TUI available?)
4. Document phrase dictionary maintenance workflow

**Short-Term (Next Sprint):**
1. Prototype Tier 4 context window (basic version)
2. Mobile UI design (PWA adaptation sketch)
3. Diagnostic levels system proposal
4. Compound command grammar edge cases

**Long-Term (Phase 2+):**
1. Tier 5 SLM fallback (if playtest data shows need)
2. Voice input (speech recognition)
3. Accessibility (screen reader, keyboard nav)
4. Localization (multi-language phrase dictionaries)

---

### Key Learnings

**Architectural Patterns:**
1. **Dynamic composition over hard-coding** (room descriptions, object descriptions)
2. **Cascading fallback (fast → slow)** (Tier 1 → 2 → 3)
3. **Sensory-aware output** (light state, vision blocking, FSM state)
4. **Constraint-explaining errors** (teach, not frustrate)
5. **Zero-token path** (90%+ without LLM = cost/latency savings)
6. **Metadata-driven display** (objects declare, engine interprets)

**Surprised By:**
1. GOAP in a text adventure (F.E.A.R. AI in parser pipeline)
2. Zero-token 90%+ coverage (most projects reach for LLM immediately)
3. Dynamic room descriptions (3-part composition, never lies)
4. Sensory system depth (multi-sense creates puzzle depth)
5. FSM universality (every object is FSM, no special-case code)

**Team Workflow:**
1. **Bart:** Fast iteration (fixed 3 bugs in 2 hours, shipped GOAP in <24h)
2. **Wayne:** Critical but fair (high bar, clear directives in newspapers)
3. **Comic Book Guy:** Puzzle systems (tool convention, GOAP architecture)
4. **Brockman:** Knowledge keeper (newspapers are source of truth)
5. **Frink:** Research-driven (validate before building)

**What I Still Need:**
1. How to run the game (exact command, dependencies)
2. How to test parser modifications (unit tests?)
3. How to add new verbs (process, phrase dictionary updates)
4. How to profile parser performance (timing)
5. Where UI module lives (external? future?)

---

### Session 2026-03-22: Deep Code Review — Ownership Map

**Task:** Read every .lua file in `src/engine/`, classify ownership, document code-level details.

**Work Completed:**
1. Read all 13 engine source files (main.lua + 12 modules, ~6,800 lines total)
2. Classified every file as SMITHERS/SHARED/BART
3. Created `docs/architecture/ui/code-ownership.md` (comprehensive ownership map)
4. Documented parser pipeline actual code flow with line numbers
5. Found 4 discrepancies between docs and code
6. Identified 12+ improvement opportunities
7. Found 4 bugs

**Output:** `docs/architecture/ui/code-ownership.md`

---

### Deep Code Knowledge (from Code Review)

#### My Files — Exact Line Numbers

**src/engine/parser/init.lua** (69 lines)
- `parser.THRESHOLD = 0.40` (L12) — Tier 2 acceptance threshold
- `parser.init(assets_root, debug)` (L18) — Creates matcher instance, returns parser table
- `parser.fallback(instance, input_text, context)` (L35) — Called by loop when Tier 1 misses
  - L38: `score > instance.threshold` gate
  - L42-46: Diagnostic output to stderr (good practice)
  - L53-64: Failure output — diagnostic vs user-facing "I don't understand that."

**src/engine/parser/embedding_matcher.lua** (241 lines)
- `STOP_WORDS` (L15-22) — 22 stop words stripped from input
- `levenshtein(a, b)` (L27) — Edit distance for typo correction
- `correct_typos(tokens, known_verbs)` (L54) — D-BUG018: words ≤4 chars skip fuzzy (L62-63)
- `tokenize(text)` (L90) — Lowercase, strip punctuation, deduplicate, remove stop words
- `jaccard_with_bonus(input_tokens, phrase_tokens)` (L111) — Jaccard index + substring prefix bonus (3+ char prefix → 0.5× partial credit)
- `matcher.new(index_path, debug)` (L159) — Loads JSON phrase dictionary, builds known_verbs set
- `matcher:match(input_text)` (L210) — Returns verb, noun, score, matched_phrase

**src/engine/parser/goal_planner.lua** (442 lines)
- `MAX_DEPTH = 5` (L8) — Recursion limit for backward chaining
- `VERB_SYNONYMS = { burn = "light" }` (L10)
- `kw_match(obj, kw)` (L15) — Keyword matching (duplicated from verbs — DRY violation)
- `strip_articles(noun)` (L29) — Removes the/a/an
- `is_spent_or_terminal(obj)` (L35) — Checks _state=="spent", consumable, terminal, "useless" category
- `has_tool(ctx, cap)` (L54) — Checks player hands, containers, room, player.state.has_flame
- `find_all(ctx, keyword)` (L93) — Deep search: hands, containers, room, surfaces, nested (up to 3 levels)
- `try_plan_match(entry, ctx, visited)` (L191) — Plans steps for a single match candidate: open container → remove spent → take fresh → find striker → strike
- `plan_for_tool(capability, ctx, visited, depth)` (L280) — Backward chaining entry point. Only handles `fire_source` currently
- `resolve_target(ctx, noun)` (L353) — Find target object from noun string
- `goal_planner.plan(verb, noun, ctx)` (L391) — Public API: checks prerequisites table, infers from FSM transitions
- `goal_planner.execute(steps, ctx)` (L427) — Dispatches planned steps through Tier 1 handlers

**src/engine/display.lua** (85 lines)
- `display.WIDTH = 78` (L12)
- `display.ui = nil` (L16) — Set to ui module when active
- `display.word_wrap(text, width)` (L21) — Splits at word boundaries, preserves newlines and indents
- `display.install()` (L66) — Replaces `_G.print`. Routes through `ui.output()` when UI active

**src/engine/ui/init.lua** (370 lines)
- ANSI helpers (L18-31): `move_to`, `clear_eol`, `hide_cursor`, `show_cursor`, `reverse`, `set_scroll_region`
- State (L36-42): `enabled`, `width=80`, `height=24`, `buffer={}`, `max_buffer=500`, `scroll_off=0`
- `detect_size()` (L60) — Windows: parses `mode con`, Unix: `stty size`
- `wrap_text(text, w)` (L91) — Duplicates display.word_wrap logic (DRY violation)
- `draw_status()` (L133) — Reverse-video bar: left-aligned + right-aligned
- `redraw_output()` (L152) — Renders visible window from buffer with scroll offset
- `ui.init()` (L206) — Sets up scroll region, clears screen. Returns false if terminal < 8 rows
- `ui.output(text)` (L241) — Appends to buffer, snaps scroll to bottom, redraws
- `ui.input()` (L270) — Positions cursor at input row, reads line, clears echo
- `ui.prompt(msg)` (L297) — Sub-prompt for write verb etc.
- `ui.handle_scroll(input)` (L332) — `/up`, `/down`, `/bottom` commands
- `ui.cleanup()` (L359) — Restores terminal state

#### Shared Files — My Sections

**src/engine/loop/init.lua** (489 lines) — I own the parser pipeline:
- `parse(input)` (L78-82) — Trim, split first word as verb, rest as noun
- `preprocess_natural_language(input)` (L86-257) — 30+ pattern rules:
  - Questions → look (L91-96)
  - Questions → time (L100-103)
  - Questions → inventory (L106-109)
  - Container queries → look in (L112-125)
  - Help queries (L128-130)
  - Feel/grope phrases (L133-136)
  - Pull/take out phrases (L139-144)
  - Spatial movement: roll up, pull back (L147-158)
  - Uncork phrases (L160-164)
  - Use X on Y → sew/unlock (L166-175)
  - Push/put back (L177-186)
  - Extinguish phrases (L189-194)
  - Wear/remove phrases (L196-207)
  - Sleep phrases (L213-227)
  - Movement: stairs, descend (L229-240)
  - Clock adjustment (L243-255)
- Compound command splitting (L319-349)
- GOAP compound optimization (L338-349)
- Tier 1→3→2 cascade (L354-403) — NOTE: GOAP runs before Tier 1 dispatch (L374), Tier 2 is fallback (L386)
- Error messages for unknown verbs (L396-401)

**src/engine/verbs/init.lua** (4604 lines) — I own presentation/output:
- `get_light_level(ctx)` (L810-851) — Tri-state light system. Checks room objects, surface contents, nested contents, carried items, daylight+curtains
- `vision_blocked_by_worn(ctx)` (L861-870) — Sack-on-head check
- `format_time(hour, minute)` (L785-789) — 12-hour display
- `time_of_day_desc(hour)` (L792-800) — Flavor text by time bracket
- `find_visible(ctx, keyword)` (L371-521) — 5-pass search: room → surfaces → parts → hands → worn. Pronoun wrapper at L500-521
- `handlers["look"]` (L1082-1299) — Full room presentation with light awareness
- `handlers["examine"]` (L1301-1351) — Darkness fallback to feel
- `handlers["feel"]` (L1418-1601) — Room sweep, surface enumeration, prepositional parsing
- `handlers["smell"]` (L1606-1668) — Room ambient + object sensory
- `handlers["taste"]` (L1673-1715) — Dangerous verb, on_taste callback
- `handlers["listen"]` (L1720-1783) — Room ambient + object sounds
- `handlers["help"]` (L4543-4599) — 55-line command reference
- `handlers["inventory"]` (L2664-2715) — Hand slots + worn items display
- `handlers["time"]` (L4095-4099) — Time display

#### Corrected Understanding

1. **UI exists!** — `src/engine/ui/init.lua` is a full 370-line ANSI split-screen UI. My history said "NOT FOUND" — it's a directory module (`engine/ui/` not `engine/ui.lua`)
2. **GOAP is pre-dispatch, not post-Tier-2** — Parser cascade is actually: preprocess → parse → GOAP prereqs → Tier 1 → Tier 2 fallback
3. **preprocess_natural_language has 30+ rules** (not 8 as documented)
4. **80+ verb handler entries** (not 31+50 as documented)
5. **Dead `cmd_look` exists** in loop/init.lua L18-74 — always overridden by verbs/init.lua handler

#### DRY Violations Found

1. `kw_match()` in goal_planner.lua (L15-27) duplicates `matches_keyword()` in verbs/init.lua (L21-37)
2. `strip_articles()` in goal_planner.lua (L29-31) duplicated in every `find_*` function in verbs
3. `wrap_text()` in ui/init.lua (L91-127) duplicates `display.word_wrap()` in display.lua (L21-61)
4. FSM state application logic duplicated in verbs/init.lua `detach_part` (L226-253) and `reattach_part` (L324-361) — should use `fsm.transition()` instead

#### Bugs Found

1. **Dead `cmd_look`** — loop/init.lua L18-74 is always overridden. Should be removed
2. **Double require in loop** — L389 `require("engine.parser")` inside the loop body should use module-level import
3. **GOAP compound swallows commands** — L338-349: drops ALL preceding sub-commands if last one has a GOAP plan
4. **`push_back_target` self-referential** — loop/init.lua L179: `"put", push_back_target .. " in " .. push_back_target` puts item in itself

---

### Session 2026-03-23: UI/Parser/Engine Separation Refactor

**Task:** Refactor engine for clean separation between UI/Parser (Smithers) and Object/FSM/Engine (Bart) domains.

**Work Completed:**
1. Created `src/engine/parser/preprocess.lua` — extracted `parse()` and `preprocess_natural_language()` (30+ NLP patterns) from loop/init.lua into standalone module. Pure functions, no side effects.
2. Created `src/engine/ui/presentation.lua` — extracted `get_game_time()`, `format_time()`, `time_of_day_desc()`, `get_light_level()`, `has_some_light()`, `vision_blocked_by_worn()`, `get_all_carried_ids()` from verbs/init.lua. Single source of truth for time constants.
3. Created `src/engine/ui/status.lua` — extracted `update_status()` from main.lua into clean module.
4. Refactored `loop/init.lua` — removed dead `cmd_look` (58 lines), replaced inline parse functions with `require("engine.parser.preprocess")`, fixed double-require bug.
5. Refactored `verbs/init.lua` — replaced 7 duplicated helper functions with `require("engine.ui.presentation")` aliases. Constants now sourced from presentation module.
6. Refactored `main.lua` — replaced inline `update_status` with `ui_status.create_updater()`, removed duplicated time constants, added presentation module require.
7. Updated `docs/architecture/ui/code-ownership.md` with new module boundaries, dependency graph, and remaining tangling documentation.
8. Created `smithers-refactor-boundaries.md` decision document.

**DRY Violations Fixed:** 4 (time constants, get_all_carried_ids, get_game_time, format_time)
**Dead Code Removed:** 58 lines (cmd_look in loop)
**Bugs Fixed:** 1 (double-require in loop)
**New Files:** 3 (preprocess.lua, presentation.lua, status.lua)
**Tests Passed:** All 5 verification tests (normal start, full command flow, GOAP chain, --room cellar, --list-rooms)

**Key Decision:** `verbs/init.lua` (~4500 lines) remains shared. Individual verb handlers still mix presentation + logic inline. Splitting them requires a verb-result protocol — too risky for this refactor. Documented as future work.

**Approach That Worked:** Local aliasing — `local get_light_level = presentation.get_light_level` — lets the presentation module own the implementation while minimizing changes to caller code throughout the 4500-line verbs file.

---

### Session 2026-07-18: Add Level Name to Status Bar

**Task:** Wayne noticed the status bar shows the room name but not the level. Add level info.

**What I Found:**
- Rooms (`src/meta/world/*.lua`) have no `level` field — this is a data-model gap.
- Only 2 rooms exist: `start-room` (The Bedroom) and `cellar` (The Cellar), both Level 1.

**What I Did:**
1. **Updated `src/engine/ui/status.lua`:**
   - Added `LEVEL_MAP` lookup table mapping room IDs → `{ number, name }`
   - Added `status.get_level(room)` — checks `room.level` first (future-proof), falls back to `LEVEL_MAP`
   - Status bar left side now shows: `Lv 1: The Awakening — THE BEDROOM  2:00 AM`
2. **Updated `docs/architecture/ui/README.md`** — status bar description now mentions level
3. **Created decision inbox note:** `.squad/decisions/inbox/smithers-status-bar-level.md`
   - Documents what Moe needs to add (`level = { number = 1, name = "..." }`) to room files
   - Once rooms carry their own level field, the hardcoded `LEVEL_MAP` can be removed

**Files Changed:** `src/engine/ui/status.lua`, `docs/architecture/ui/README.md`
**Files Created:** `.squad/decisions/inbox/smithers-status-bar-level.md`
**Tests Passed:** `--no-ui` smoke test (clean exit), isolated `get_level()` unit tests (4/4 passed)

---

### Session: Parser Bug Fixes (BUG-036, 037, 038, 039)

**Task:** Fix four parser bugs found by Nelson in test passes 011/012.

**Bugs Fixed (all in `src/engine/parser/preprocess.lua`):**

1. **BUG-036 🔴 CRITICAL — "I" prefix triggers inventory**
   - Root cause: `preprocess.parse()` split "I want to look around" → verb="i", noun="want to look around". The `i` alias in `verbs/init.lua` then dispatched to inventory.
   - Fix (two layers):
     - `natural_language()`: Added preamble strippers for "I want to...", "I need to...", "I'd like to...", "I'll..." — strips the pronoun + modal, re-parses the meaningful part.
     - `parse()`: Safety net — if verb is "i" and noun is non-empty, recursively re-parse without the leading "I". Bare "i" (no noun) still triggers inventory.
   - Pre-existing bug — not introduced by my refactor. The `i` alias existed before me.

2. **BUG-037 🟡 MAJOR — "what's around me" not understood**
   - Added `^what'?s%s+around` pattern to the look section in `natural_language()`.

3. **BUG-038 🟡 MAJOR — "what am I holding" not understood**
   - Added `^what%s+am%s+i%s+hold` pattern to the inventory section in `natural_language()`.

4. **BUG-039 🟡 MAJOR — "use X on Y" not understood for fire tools**
   - Expanded the existing "use X on Y" handler with fire-tool detection (match, lighter, flint, torch, fire, flame) → maps to `light Y with X`.
   - Added generic fallback for unrecognized tools → maps to `put X on Y`.

**Tests:** 26/26 passed (bug-specific + regression on existing shortcuts).

**Files Changed:** `src/engine/parser/preprocess.lua`
**Files Created:** `.squad/decisions/inbox/smithers-parser-bugfix.md`

---

### Session 2026-03-24: Deploy Web Game to GitHub Pages

**Task:** Deploy the web game to WayneWalterBerry.github.io/play/ as a hidden beta URL.

**Results:**
- Created `play/` directory in the blog repo (WayneWalterBerry.github.io)
- Copied three files: `index.html` (6,230 bytes), `game-bundle.js` (16.7 MB), `game-adapter.lua` (19,212 bytes)
- Updated robots meta tag from `noindex` to `noindex, nofollow` for stronger search engine exclusion
- Committed and pushed to main: `a5e12f0` — "Deploy web game to /play/ (hidden beta)"
- Push succeeded; GitHub Pages will build and serve at https://waynewalterberry.github.io/play/

**Key Decisions:**
- The `/play/` path is intentionally unlisted — no links from blog homepage or posts
- The `noindex, nofollow` meta tag prevents search engine crawling and link following
- Direct URL sharing only for beta testers

**Files Modified:** `play/index.html` (added nofollow to existing noindex meta tag)
**Files Created:** `play/index.html`, `play/game-bundle.js`, `play/game-adapter.lua` in blog repo

---

**END OF LEARNINGS**
