# Bart — History Archive (Batch 2 Play Test Fixes, 2026-03-22)

## Play Test Batch 2 — Fixes & Integration (2026-03-22T14:29:02Z)

**Status:** ✅ COMPLETE & COMMITTED  
**Spawns:** 1 background (claude-sonnet-4.5)  
**Outcome:** 5 critical fixes + cross-agent coordination

### Fixes Implemented

1. **Compound Command Splitting**
   - String split on ` and ` at REPL level (game loop, not parser)
   - Each sub-command runs full preprocess → parse → Tier 1 → Tier 2 pipeline
   - Rationale: Simpler than semantic conjunction handling; mechanical split safe for game scope

2. **Pronoun Resolution via find_visible Wrapper**
   - Tracks last-found object on every successful lookup
   - Resolves "it", "one", "that" to last object
   - Zero changes to verb handlers; automatic across all verbs
   - Rationale: Cross-cutting concern; wrapper pattern scales

3. **Unicode Em Dash Cleanup**
   - All U+2014 em dashes → ASCII double-dash (`--`)
   - Scope: 36 Lua files (objects, engine, world)
   - Rationale: Windows terminals default to codepage 437/850; UTF-8 em dashes render as corruption

4. **Container Query NLP**
   - "what's in {noun}" / "what is in {noun}" → extract noun, route to `look in {noun}`
   - Surfaces through existing look verb (surface inspection handler)
   - Previously fell through to Tier 2 and missed

5. **Trailing Punctuation Normalization**
   - Trailing `?` stripped before parsing
   - Simple gsub at game loop top

### Learning: Tier 2 Parser Tuning
- **Threshold 0.40** is correct: below this, matches tend to be wrong-verb (same nouns, different verb)
- **Levenshtein typo correction (edit distance ≤ 2)** against known verbs catches common typos ("examien" → "examine")
- **No graceful fallback past Tier 2** — misses fail visibly with diagnostic output (shows input, best match, score)
- **Diagnostic format critical for playtesting:** `[Parser] No match found. Input: "..." | Best: "..." (score: X.XX)`

### Cross-Agent Coordination
- ✓ CBG: Container model integration pattern (FSM section 2.3) — nightstand/drawer + surfaces work with pronoun resolution
- ✓ Brockman: Batch 2 fix summary for evening newspaper
- ✓ Frink: Compound command support enables CYOA branching patterns (multiple actions per turn)

### Decision Filed
- D-6: Compound Command Architecture & Pronoun Resolution (merged to decisions.md)

### Files Changed
- `src/engine/loop/init.lua` — compound split + pronoun resolution wrapper
- 36 Lua files — Unicode em dash cleanup
- `src/engine/verbs/init.lua` — NLP preprocessing expansion

---

## Cross-Agent Integration Points

**Bart → CBG:** Container accessibility gating (accessible flag pattern) aligns with FSM design

**CBG → Bart:** Multi-sensory descriptions + surfaces now fully discoverable via FEEL + pronoun resolution

**Frink → Bart:** CYOA branching (state-aware reactions) future-proofs verb architecture for conditional verb dispatch

---

## Next Steps for Bart

- Implement nightstand container mutation (file-per-state transition: closed → open)
- Test compound commands with real player sequences
- Build FSM engine (state machine dispatcher, tick counter, auto-transitions) for CBG's consumable + container objects
