# Sideshow Bob — History

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, `lua src/main.lua`)
**Owner:** Wayne Berry
**Role:** Puzzle Master — designs multi-step puzzles using real-world object interactions, conceptualizes new objects needed for puzzles, writes puzzle design docs in `docs/puzzles/`
**Documentation Rule:** Every puzzle MUST be documented in `docs/puzzles/` — one .md per puzzle. Bob owns these docs.

### Key Relationships
- **Flanders** (Object Designer) — I hand off object specs for implementation; he builds the .lua files
- **Frink** (Researcher) — I request puzzle research from other games/books/real life; he wrote the DF comparison and mutation research
- **CBG** (Game Designer) — aligns puzzles with overall game design, pacing, and Wayne's directives
- **Bart** (Architect) — engine capabilities and constraints; wrote containment, room exits, dynamic descriptions docs
- **Nelson** (Tester) — tests puzzles for solvability and edge cases
- **Brockman** (Documentation) — can delegate doc writing to him, but puzzle docs are my responsibility

---

## Latest Activity

**WAVE-1c Puzzle Specifications Completed (2026-08-24):**
- Designed all 7 MrBeast challenge room puzzles for Wyatt's World
- 7 specs written: 48 KB, 1406 lines total, committed to `projects/wyatt-world/puzzles/`
- Specs cover: Beast Studio (hub), Feastables Factory, Money Vault, Beast Burger, Last to Leave, Riddle Arena, Grand Prize Vault
- Difficulty spread: ★ (1) → ★★★★ (2 specs at hardest level)
- Reading-focused puzzles: every puzzle requires careful text analysis or information extraction
- E-rated design: no combat, no harm, no scary elements, failure is silly + encouraging
- Each spec includes: premise, objects required, solution steps, FSM states, hints (3-tier), failure states, educational angle, notes for Flanders (objects) and Nelson (testing)
- Pushed to main: commit 460bd96

**Options Review Ceremony (2026-08-02):**
- Reviewed Options project as Puzzle Designer
- Verdict: ⚠️ CONCERNS (2 blockers: anti-spoiler gaps, puzzle exemption system)
- Identified critical gaps in Rules 2 & 4 (discovery vs progress conflict, object state leakage)
- Proposed 3-tier exemption system (disabled, restricted, delayed)
- Recommended 7-rule anti-spoiler rewrite with Rules 6 & 7 (undiscovered exits, hidden capabilities)
- See `.squad/decisions/inbox/bob-options-review.md` for full review

**B3+B4 Blockers Fixed (2026-08-02):**
- Rewrote section 4.7 (Anti-Spoiler Rules) with 7-rule escalating specificity framework
- Replaced "diminishing novelty" (Rule 5) with 3-tier escalation: Standard → Context Clues → Mercy Mode
- Added Rule 6 (mercy mode philosophy) and Rule 7 (puzzle room overrides)
- Added new section 4.8 (Puzzle Room Exemptions) with 3-tier flag system
- Renumbered original 4.8 → 4.9 (Clearing Pending Options)

---

## Learnings

**Anti-spoiler rewrite (Rule 5 escalation):**
- Old system: sarcastic message after 3 requests ("try DOING something")
- New system: 3-tier escalation based on `ctx.options_request_count`
- Standard (1-2 requests): general sensory, no goal exposure
- Context Clues (3-4 requests): goal-directed hints with narrative framing
- Mercy Mode (5+ requests): direct command format ("Try: unlock padlock with key")
- Counter resets on: room change, goal completion, executing any listed command
- Philosophy: help stuck players progressively, never punish them for asking

**Puzzle exemption system (3 flags):**
- `options_disabled = true`: blocks ALL options, returns refusal message — use for 2-3 climactic moments per level max
- `options_mode = "sensory_only"`: locks escalation at Standard tier, no goal/dynamic scan — best for atmospheric puzzle rooms
- `options_delay = N`: blocks options for first N turns in room — encourages exploration before hinting
- Per-phase exemptions: flags can change via `on_state_change` hook as puzzle progresses
- Design sweet spot: `sensory_only` mode protects "aha!" moments while keeping players supported
