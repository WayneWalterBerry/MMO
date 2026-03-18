# Bart — History

## Project Context

- **Project:** MMO — A text adventure MMO with multiverse architecture
- **Owner:** Wayne "Effe" Berry
- **Stack:** Lua (engine + meta-code), cloud persistence
- **Key Concepts:** Each player gets their own universe instance with self-modifying meta-code. Objects are rewritten (not flagged) when state changes. Code IS the state.

## Learnings

### 2026-03-18 — Onboarding
- Joined the team as Architect
- Key architecture decisions already made:
  - Lua for both engine and meta-code (self-rewriting via loadstring)
  - True code mutation model — objects are rewritten, not flagged
  - Meta-code is runtime-morphed, NOT persisted in VCS
  - Cloud persistence for player universe state
  - Multiverse model: each player gets own universe instance
  - Universe templates: LLM-generated once at build, hand-tuned, procedural variation at runtime
  - Ghost mechanic for inter-universe interaction (fog of war visibility)
  - NLP or rich synonym parser (no per-interaction LLM tokens)
  - LLM writes all code — complexity isn't a constraint
