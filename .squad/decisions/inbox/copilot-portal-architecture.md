### 2026-03-25T12:30:00Z: D-PORTAL-ARCHITECTURE
**By:** Wayne Berry (via Copilot)
**Scope:** Door/exit architecture unification

**Decisions:**
1. **GO on Option B** — Doors become first-class objects (portal template). Exit system unified into object system.
2. **Template name: portal** — Wayne chose portal over passage/exit. Fits the fantasy setting.
3. **Explicit 	raversable per FSM state** — Each state declares traversable = true/false. No computed derivation.
4. **Paired objects for bidirectional doors** — Each room owns its own portal object, linked by idirectional_id. State syncs between pairs.
5. **Migration starts with bedroom-hallway door** — Most complex exit, already has companion object. Proof of concept.

**Rationale:** Bart analysis showed 0/11 principle alignment for exits-as-constructs vs 11/11 for objects. CBG confirmed 40 years of IF precedent (Zork, Inform 7) agree. Removes ~177 net lines of parallel engine code. Migration is incremental and backward-compatible.

**Affects:** Bart (engine), Flanders (portal objects), Moe (room files), Smithers (verb handlers), Nelson (tests)