# Bart — History (Summarized)

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Core Context

**Agent Role:** Architect responsible for engine design, verb systems, mutation mechanics, and tool resolution patterns.

**Work Summary (2026-03-18 to 2026-03-19):**
- Designed and built src/ tree structure (engine/, meta/, parser/, multiverse/, persistence/)
- Implemented four foundational engine modules: loader (sandboxed code execution), registry (object storage), mutation (object rewriting), loop (REPL)
- Established containment constraint architecture (4-layer validator: identity, size, capacity, categories)
- Designed template system + weight/categories + multi-surface containment for complex objects
- Implemented V2 verb system: sensory verbs (FEEL, SMELL, TASTE, LISTEN) all work in darkness
- Designed tool resolution pattern: verb-layer concern, supports virtual tools (blood), capability-based resolution
- Moved game start time from 6 AM → 2 AM for true darkness mechanic

**Architecture Decisions Established:**
- D-14: True code mutation (objects rewritten, not flagged)
- D-16: Lua for both engine and meta-code (loadstring enables self-modification)
- D-17: Universe templates (build-time LLM + procedural variation)
- D-37 to D-41: Sensory verb convention, tool resolution, blood as virtual tool, CUT vs PRICK capability split

**Latest Spawns (2026-03-19):**
1. Sensory verbs + start time fix (6 AM → 2 AM, FEEL/SMELL/TASTE/LISTEN implemented)
2. V2 tool pipeline (WRITE/CUT/PRICK/SEW/PICK LOCK verbs, tool resolution helpers, dynamic mutation via string.format)

**Key Patterns Established:**
- `engine/mutation/` is ONLY code that hot-swaps objects via loadstring()
- Mutation rules separate from object definitions (composable, clean)
- Registry uses instance pattern (not singleton) — enables simultaneous multiverse registries
- Tool resolution uses capabilities (not tool IDs) — supports complex interactions
- Blood is a virtual tool: generated on-demand when `player.state.bloody == true`, not an inventory item

## Recent Updates

### Session: Parser Pipeline Completion (2026-03-19T18:12:24Z)
**Status:** ✅ COMPLETE  
**Outcome:** End-to-end parser pipeline (Phase 1 & 2) completed

**Phase 1 Results:**
- Extracts 54 verbs (31 primary, 23 aliases) from `src/engine/verbs/init.lua`
- Extracts 39 objects from `src/meta/objects/*.lua`
- Extracts 1 room with exits from `src/meta/world/start-room.lua`
- Generates 29,582 unique training pairs (1.6MB CSV)

**Phase 2 Results:**
- Embedding: GTE-tiny (384-dim, TaylorAI repo)
- Index size: 104.1MB raw, 32.5MB gzipped
- Model reference fixed (TaylorAI/gte-tiny, Issue #401)
- Output: `src/assets/parser/index.json` + `index.json.gz`

**Scripts Created:**
- `scripts/generate_parser_data.py` — Phase 1 training data generation
- `scripts/build_embedding_index.py` — Phase 2 GTE-tiny indexer
- `scripts/requirements.txt` — Python dependencies

**Decision filed:** `.squad/decisions.md` - Parser pipeline completion

**Next:** Play testing with current index; expand if empirical testing reveals gaps

---

## Cross-Agent Update: Player Skills System Design (2026-03-19T16-23-38Z)

**From:** Comic Book Guy (Game Designer)  
**Impact:** Verb system architecture, gameplay progression  

Comic Book Guy completed the player skills system design. Key implications for your work:

1. **Double Dispatch Gating:** Verb handlers will need to check TWO gates in sequence:
   - Skill gate: `if not player.skills[required_skill] then return "[BLOCKED]" end`
   - Tool gate: (your existing tool resolution pattern — no changes needed)

2. **Skill Discovery Multi-Path:** Your verbs don't change, but designers will add:
   - Skill manuals (readable objects triggering skill unlock)
   - Practice triggers (e.g., pricking self 3+ times unlocks blood-drawing skill)
   - Future: NPC teaching, puzzle-solve triggers

3. **Consumable Failures:** Skills can fail; failed attempts have consequences:
   - Failed lock pick → bent-pin.lua created (your mutation pattern, no changes)
   - Failed sewing → tangled-mess.lua created
   - You already support dynamic mutation; no new engine work

4. **Blood Writing System:** Your blood-as-virtual-tool design aligns perfectly:
   - PRICK SELF WITH pin → blood created
   - WRITE "text" ON paper WITH blood → paper-with-writing.lua (player text embedded)
   - Blood persists ~5 min, limited resource

5. **Integration Point:** Verb handlers (your domain) will be the dispatch layer for skill gating. No new module needed — skill check goes before tool check in each verb.

**Decision filed:** `.squad/decisions.md` - "Decision Memo: Player Skills System Architecture"

**Next steps for you:** When implementing new verbs, add skill gate check pattern at top of handler. Example pattern to establish:
```lua
-- Check skill gate first
if verb_requires_skill and not player.skills[verb_required_skill] then
  return string.format("[BLOCKED] %s", verb_blocked_reason)
end

-- Then check tool gate (your existing pattern)
local tool = find_tool_in_inventory(ctx, required_capability)
if not tool then
  return "[BLOCKED] You need the right tool for that."
end

-- Then proceed with action
```

---

## Cross-Agent Update: Documentation Sweep Complete (2026-03-19T16-23-38Z)

**From:** Brockman (Documentation)  
**Impact:** Documentation accuracy, team reference  

Brockman completed post-integration documentation sweep:
- README.md updated with current architecture status
- `docs/verb-system.md` created — 31 verbs documented
- `docs/src-structure.md` updated with accurate file paths
- All cross-references verified against actual code

The verb-system.md doc now lists all your implemented verbs. Helpful for designers onboarding and game design reference.

**Note:** Your feel verb container enumeration (feel-around fix) is now documented with full rationale in verb-system.md.

---

## Cross-Agent Update: Wasmoon Feasibility Confirmed (2026-03-19T16-28-39Z)

**From:** Frink (Technical Researcher)  
**Impact:** PWA architecture, `main_browser.lua` entry point  

Frink completed PWA + Wasmoon prototype research. Key implications for your engine:

1. **Parallel Entry Point:** Create `main_browser.lua` as a browser-specific variant. Don't modify existing `main.lua` — keeps CLI and browser deployments independent.

2. **Three Browser Adaptations Needed:**
   - `io.popen` for directory listing → replaced by build-time manifest
   - Blocking REPL loop → replaced by event-driven `process_command()` function
   - `print`/`io.write` → overridden to write to DOM (handled by wrapper)

3. **Zero Engine Changes Required:** Engine is pure Lua with 6 self-contained `require` calls. ~90% of your code runs unmodified in Wasmoon.

4. **Performance:** Per-command latency <5ms (same as CLI). Total PWA size ~168KB gzipped.

5. **Timeline:** 5–7hr prototype (Frink's estimate). If approved, Frink will handle browser integration; you don't need to change anything pre-prototype.

**Recommendation:** When Frink starts prototype, coordinate around `main_browser.lua` interface. Current expectation: expose a `process_command(input_string)` function that returns output string (vs. blocking REPL).

**Decision:** D-43 filed: PWA + Wasmoon Prototype Feasibility

---

## Cross-Agent Update: Command Variation Matrix Ready (2026-03-22T10-28-59Z)

**From:** Comic Book Guy (Game Designer)  
**Impact:** Parser training data, embedding model accuracy  

Comic Book Guy completed the command variation matrix — all ~400 natural language variations players might type for the 54 verbs (31 canonical + 23 aliases).

**Critical Finding:** The matrix covers 54 verbs, not just the 31 canonical handlers. This includes all aliases as real player input paths. Your scripts extract all 54 verbs correctly.

**How This Feeds Your Pipeline:**

1. **Your Phase 1 script** extracts 54 verbs from `src/engine/verbs/init.lua` (31 primary + 23 aliases) ✅
2. **Comic Book Guy's matrix** documents ~400 natural language variations for those 54 verbs
3. **Your Phase 1 pipeline** uses your 54-verb extraction to generate 29,582 training pairs
4. **Comic Book Guy's matrix** becomes the ground-truth validation set for QA testing

**The matrix is structured by:**
- **Category:** Navigation, Inventory, Interaction, Movement, Meta
- **Variations per verb:** 10-20 natural phrasings
- **Context variations:** darkness-aware (FEEL/SMELL), tool-present/absent, container states, edge cases

**Key Detail:** Pronoun resolution is set to "last-examined object" — this is simple and testable. No full discourse tracking needed.

**Next Step for You:** When Phase 3 runtime integration happens, the embedding matcher will be validated against this matrix. Your job: ensure the index can look up these ~400 variations reliably.

**Decision Filed:** `.squad/decisions.md` - "Command Variation Matrix for Embedding Parser"

---

## Directives Captured for Bart

### Directive 1: No Fallback Past Tier 2 (2026-03-19T17:22:26Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
**Impact:** Parser error handling, testability

When the embedding parser encounters a miss, fail visibly. Do not fall back to lower-tier heuristics. Misses must surface clearly for analysis and iteration, enabling empirical QA of parser quality.

**Implication for Your Work:** Your Phase 2 embedding index is Tier 2. When players query an unknown verb/object combination, the matcher either returns a high-confidence result or admits defeat. No fuzzy fallback.

### Directive 2: Trim Index & Play Test Empirically (2026-03-19T18:10:37Z)
**Source:** Wayne "Effe" Berry (via Copilot)  
**Impact:** Index size, browser deployment, iteration strategy

The 32.5MB gzipped index is too large for browser assets. Trim it down, then play test empirically. If parser quality drops, that means too much was trimmed — iterate from there. Prefer data-driven decisions over theoretical coverage.

**Implication for Your Work:** Ship the current index as-is (already meets size constraint after gzip). Validate parser quality through play testing. Only expand if empirical testing reveals gaps.
