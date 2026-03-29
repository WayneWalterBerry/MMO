# Save Game Project Board

**Owner:** 🏗️ Bart (Architecture Lead)  
**Last Updated:** 2026-08-04  
**Overall Status:** 📋 RESEARCH COMPLETE — Architecture proposal ready for Wayne review

**Documentation:** See `projects/save-game/architecture.md` (full analysis + recommendation)

---

## Project Summary

Implement save/load game state for the web version. Static site (GitHub Pages), code mutation (D-14), Fengari Lua runtime. Five approaches evaluated; **Hybrid Snapshot + Export Code** recommended.

---

## Phase Plan

| Phase | Description | Owner | Status |
|-------|-------------|-------|--------|
| **P0** | Architecture research + proposal | Bart | ✅ Done |
| **P0b** | Wayne review + approval | Wayne | 🔴 TODO |
| **P1** | Save serializer (`save/init.lua`, `save/serialize.lua`) | Bart | 🔴 TODO |
| **P2** | Mutation tracking (`obj._mutation_from` field) | Bart | 🔴 TODO |
| **P3** | Load/restore engine (`save.restore()`) | Bart | 🔴 TODO |
| **P4** | Save/load verbs + auto-save triggers | Bart + Smithers | 🔴 TODO |
| **P5** | Web UI integration (localStorage, export/import) | Gil | 🔴 TODO |
| **P6** | Tests (save/load round-trip, migration, edge cases) | Nelson | 🔴 TODO |
| **P7** | Version migration framework | Bart | 🔴 TODO |

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Save approach | Hybrid Snapshot (data fields + source reload) | Respects D-14; functions reload from source; small saves (~5-20 KB) |
| Backup approach | Export Code (base64 string) | Zero infrastructure; player-portable; fallback for cleared localStorage |
| Storage | localStorage (primary), IndexedDB (future) | 5 MB limit is 100x our needs; synchronous API is simpler |
| Save slots | 3 manual + 1 auto-save | Standard game pattern; auto-save on room transitions |
| Cloud save | Deferred to future phase | Requires backend; out of scope for static site V1 |

---

## Size Budget

| Metric | Value |
|--------|-------|
| Level 1 full save | ~15 KB |
| localStorage budget | 5 MB |
| Save slots × max size | 4 × 40 KB = 160 KB (3% of budget) |
| Export code (base64) | ~20 KB string |

---

## Dependencies

| Dependency | Owner | Status |
|------------|-------|--------|
| JSON encoder (pure Lua) | Bart | Partial — `engine/parser/json.lua` has decode, needs encode |
| Mutation target tracking | Bart | New — add `_mutation_from` to mutation.mutate() |
| Web localStorage bridge | Gil | New — JS bridge functions in game-adapter |
| Save/load UI buttons | Gil | New — HTML/CSS for save slot UI |

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Game updates break saved state | Medium | Version migration framework (P7) |
| localStorage cleared by browser | Low | Export code backup; periodic prompt |
| Mutation targets missing on server | Low | Build-time validation |
| Serialization edge cases (cycles, nils) | Medium | ID-reference serialization; test coverage |
