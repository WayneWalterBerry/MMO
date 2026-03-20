# MMO Engine: Architecture Decisions

**Version:** 1.0  
**Date:** 2026-03-19  
**Author:** Wayne "Effe" Berry (decisions); Brockman (documentation)  
**Audience:** Engineering team, designers, future contributors

---

## Purpose

This document captures the eight architectural decisions made on 2026-03-19 that define the engine's core shape. These decisions should be read as a package — they reinforce each other. Understanding one in isolation risks missing the design intent.

Cross-references to prior decisions use the format **[D-N]** where N matches the decision number in [`.squad/decisions.md`](../../.squad/decisions.md).

---

## Summary Table

| # | Decision | Status | Impact Area |
|---|----------|--------|-------------|
| [D-14](#d-14-mutation-model-true-code-rewrite) | Mutation Model: True Code Rewrite | ✅ Active | Engine core, world model |
| [D-15](#d-15-meta-code-format-deferred) | Meta-Code Format: Deferred (likely Lua tables/closures) | ⏳ Deferred | Engine internals |
| [D-16](#d-16-engine-language-lua) | Engine Language: Lua | ✅ Active | Foundational — all engine code |
| [D-17](#d-17-universe-templates-llm-build-time--hand-tuning--procedural-variation) | Universe Templates: LLM once at build time + hand-tuning + procedural variation | ✅ Active | Content pipeline, cost model |
| [D-18](#d-18-persistence-cloud-storage) | Persistence: Cloud Storage | ✅ Active | Infrastructure, data model |
| [D-19](#d-19-parser-nlp-or-rich-synonyms) | Parser: NLP or Rich Synonyms (not simple verb-noun) | ✅ Active (details TBD) | Player interaction model |
| [D-20](#d-20-ghost-visibility-fog-of-war) | Ghost Visibility: Fog of War | ✅ Active | Multiplayer, networking |
| [D-21](#d-21-universe-merge-no-merge) | Universe Merge: No Merge | ✅ Active | Multiplayer architecture |

---

## D-14: Mutation Model: True Code Rewrite

### Context

Classical IF engines handle state change by flipping flags. A broken mirror sets `mirror.is_broken = true`. The object definition stays intact. This approach is simple but puts a ceiling on what's possible: the world's rules can change, but its structure cannot. When we designed the self-modifying universe concept [D-11, D-12], we needed a mutation model that could support genuine structural change — not just state change.

### Decision

When a player action mutates an object, the engine **rewrites the object's definition entirely**. Breaking a mirror does not set a Boolean; it replaces the mirror object with a fundamentally different entity — `broken_mirror` — with its own properties, verbs, and behaviors. The original definition is gone; the new definition takes its place.

```lua
-- BEFORE: object definition
mirror = {
  name = "mirror",
  description = "A tall, gilded mirror reflecting the room.",
  verbs = {
    break = function(player)
      -- ... rewrite self into broken_mirror
    end
  }
}

-- AFTER break: the definition above is replaced, not patched
broken_mirror = {
  name = "broken_mirror",
  description = "Jagged shards glinting on the floor. Something stirs beyond the frame.",
  verbs = {
    enter = function(player)
      -- unlock new narrative possibility
    end
  }
}
```

### Rationale

Flag-flipping is additive: you layer state on top of the original. Code rewriting is substitutive: the original ceases to exist. This distinction matters because:

- **Narrative honesty** — a broken mirror truly *is* a different thing, not a broken version of the same thing.
- **Emergent possibilities** — the new entity can have entirely new verbs (like `enter`) that didn't exist before the mutation.
- **Simplicity of the world model** — no need to reason about combinations of flags. An object's current definition *is* its current state.

### Implications

- Object definitions must be rewritable at runtime → requires Lua's `loadstring()` or equivalent **[D-16]**.
- The persistence layer must serialize the *mutated* definition, not just a flag diff **[D-18]**.
- A mutation history system may be needed for "Company" analytics **[D-18]**.
- Content pipeline must define "mutation paths" — what an object can become and under what conditions.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-8 §8.2] Code Mutation Over State Flags | **Confirmed** — D-14 formalizes the mechanism described there |
| [D-11] Self-Modifying Universe Code | **Confirmed** — D-14 is the concrete implementation of that directive |
| [D-12] Engine-Driven Code Mutation | **Confirmed** — the engine (not the player) drives the rewrite |
| [D-16] Engine Language: Lua | **Depends on** — Lua's `loadstring()` is the enabling mechanism |

---

## D-15: Meta-Code Format: Deferred

### Context

With the mutation model settled (D-14) and Lua chosen as the engine language (D-16), the question arises: in what format does the engine store and rewrite object definitions? This is the "meta-code" question — the representation of world code as a first-class data structure.

### Decision

**Deferred.** Not yet formally decided. However, since Lua is the engine language and Lua's native structures are tables and closures, the meta-code representation will most likely be **Lua tables and closures**. This keeps engine code and world definitions in the same language with no serialization boundary.

The decision awaits prototyping to confirm the representation works at the required scale.

### Rationale

Deferring avoids locking in a format before we understand the constraints prototyping will reveal. The Lua tables/closures path is the natural fit because:

- Lua tables can hold both data *and* functions simultaneously.
- Closures capture environment, enabling stateful behaviors.
- No translation layer needed — the engine and the world speak the same language.

### Implications

- Prototyping is the gate on this decision.
- The format must support serialization to cloud storage **[D-18]**.
- If Lua tables/closures are confirmed, mutation becomes a matter of replacing a table entry.

### Open Questions

- Can full object definitions (tables + closures) be serialized to JSON/cloud cleanly?
- What is the unit of mutation — the whole table, or individual fields?
- Is there a need for a human-readable intermediate form for hand-tuning **[D-17]**?

---

## D-16: Engine Language: Lua

### Context

Earlier research [D-6] identified Lua as the recommended language for the engine, citing its embeddability, minimal footprint (~200 KB), and proven track record in games (WoW, Roblox, LÖVE, Defold). The mutation model [D-14] and the meta-code concept required a language capable of rewriting and re-interpreting itself at runtime.

### Decision

**Lua is the engine language** — for both the runtime engine and the meta-code that defines the world. There is no boundary between engine and world definition. Both are Lua. The mechanism enabling this is `loadstring()` (or `load()`), which allows Lua to parse and execute a string as code at runtime.

```lua
-- Engine rewrites object definition at runtime
local new_definition = string.format([[
  %s = {
    name = "%s",
    description = "%s",
    ...
  }
]], new_name, new_name, new_description)

load(new_definition)()
```

### Rationale

- **Self-modification** — `loadstring()` is the direct enabler of the mutation model [D-14].
- **Code-data unity** — Lua tables are simultaneously code and data, collapsing the engine/meta-code boundary.
- **Industry proof** — WoW scripting, Roblox, LÖVE, Defold all validate Lua at scale.
- **Footprint** — ~200 KB runtime; ~100–200 KB with LuaJIT.
- **Minimal context-switching** — engine developers and content authors use the same language.

### Implications

- All engine code is Lua; C or C++ bindings only if performance demands it.
- World definitions, mutation logic, and engine runtime all in the same language.
- `loadstring()` security model needs consideration — what strings can be loaded, from where?
- LuaJIT is available as a performance upgrade if benchmarks show need.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-6] Language & Runtime Recommendation | **Confirmed** — D-16 makes D-6's Lua recommendation authoritative |
| [D-14] Mutation Model | **Enables** — `loadstring()` is the implementation mechanism |
| [D-15] Meta-Code Format | **Narrows** — Lua tables/closures become the obvious choice |

---

## D-17: Universe Templates: LLM Once at Build Time + Hand-Tuning + Procedural Variation

### Context

Each player inhabits a unique universe [D-10]. The question was: how are those universes generated? Options ranged from fully hand-crafted content, to per-player LLM generation (expensive), to fully procedural generation (cheap but low quality). We needed an approach that gives players genuinely distinct worlds without per-player AI costs.

### Decision

Universe generation follows a **three-stage pipeline**:

1. **Build time** — LLM generates a canonical universe template once when the game ships. This is a one-time cost.
2. **Hand-tuning** — Human authors review and improve the template to raise quality above what the LLM produces alone.
3. **Player start** — A procedural variation system generates a unique multiverse instance per player using deterministic seeds and parameter ranges.

**Key constraint:** No per-player LLM token cost. The LLM is a build tool, not a runtime dependency.

### Rationale

- **Cost model** — LLM calls are expensive at scale. One build-time call is affordable; one per player is not.
- **Quality floor** — The hand-tuning step ensures the template meets quality standards the LLM alone may not achieve.
- **Player uniqueness** — Procedural variation gives players the sense of a world made for them, without bespoke generation.
- **Reproducibility** — Deterministic seeds mean a universe can be recreated exactly from its seed, enabling debugging and analytics.

### Implications

- Need a **procedural variation system** capable of seeded, parameterized world generation.
- The universe template format must support **variation points** — parameters the procedural system can adjust.
- Template quality becomes a design responsibility, not an LLM dependency.
- The LLM is a content collaborator, not a server cost.
- "The Company" analytics [D-18] observes divergence from the template across players.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-8 §8.4] Player-Per-Universe Model | **Implements** — D-17 defines how those universes are created |
| [D-10] Multiverse MMO Architecture | **Refines** — D-17 answers the generation question D-10 left open |

---

## D-18: Persistence: Cloud Storage

### Context

A text-based MMO where players' universes are self-modifying programs needs to persist state between sessions. The question was whether to persist locally (SQLite, as suggested in [D-5]), in the cloud, or both. The mutation model [D-14] and "The Company" analytics concept pushed toward cloud.

### Decision

**Mutated universe state is persisted in cloud storage.** Players can resume across sessions and devices. Cloud persistence also enables **"The Company"** — an in-game meta-entity and analytics pipeline that observes how player worlds evolve over time.

### Rationale

- **Session continuity** — players resume a living, self-modified world, not a reset.
- **Cross-device access** — cloud storage is the natural persistence model for a non-local game.
- **"The Company"** — cloud storage enables a layer of universe analytics. "The Company" can observe, track, and potentially react to how worlds diverge.
- **Data richness** — mutated world state is a uniquely valuable signal about player behavior and creativity.

### Implications

- Need a **cloud storage provider** (specific provider TBD).
- Lua object definitions (tables + closures) must be **serializable to cloud format**; this is a hard technical constraint on D-15.
- "The Company" needs an analytics pipeline reading from cloud storage.
- Local SQLite [D-5] is effectively superseded for persistent world state; cloud is primary.
- Serialization format must handle both the template baseline and the accumulated mutations.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-5] Modern IF Architecture | **Supersedes** (local SQLite) — cloud storage replaces local-only persistence |
| [D-14] Mutation Model | **Depends on** — mutated definitions must be serialized and stored |
| [D-17] Universe Templates | **Enables analytics** — cloud stores both template and per-player divergence |

---

## D-19: Parser: NLP or Rich Synonyms

### Context

Classic IF parsers use simple verb-noun dispatch: tokenize, strip articles, match verb, find object. This was the recommendation in [D-3]. It works, but it produces a parser that feels mechanical. Our game design calls for natural-feeling interaction. The question was whether to invest in NLP or a different approach.

### Decision

The parser will **not** be simple verb-noun. Two acceptable approaches:

1. **Natural language processing** — full NLP parsing of player input (grammatical analysis, semantic understanding).
2. **Structured commands with rich synonym/alias mapping** — a large, carefully designed synonym table that makes structured commands feel natural.

**LLM-powered parsing** is acceptable *only* if running locally — no per-interaction token cost. A local LLM is a **stretch goal**, not a requirement for ship.

### Rationale

- **Player experience** — "grab the old rusty key from the chest" should work, not just "take key".
- **Cost discipline** — LLM parsing at runtime is prohibitively expensive per-interaction; local LLM sidesteps this.
- **Rich synonyms are underrated** — a well-designed synonym table with good alias coverage produces a player experience close to NLP without the infrastructure cost.
- **Extensibility** — as Lua objects can define custom verbs [D-8 §8.1], the parser must support object-specific verb registration.

### Implications

- The synonym/alias table becomes a significant design artifact — breadth matters.
- If NLP is chosen, a local NLP library (not a cloud API) is required.
- The parser must integrate with Lua's object verb registration system [D-16].
- Fallback to rich synonyms is the safe implementation path; NLP and local LLM are enhancements.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-3] Text Adventure Containment Architecture | **Supersedes** — D-3 recommended simple tokenizer + verb dict; D-19 explicitly rejects "simple verb-noun" |
| [D-8 §8.1] Verb-Based Interaction System | **Extends** — D-19 defines how verbs are parsed; synonym system supports D-8's verb table |
| [D-16] Engine Language: Lua | **Integrates** — parser hooks into Lua object verb tables |

---

## D-20: Ghost Visibility: Fog of War

### Context

The ghost mechanic [D-13] allows players from one universe to observe or visit another universe as a "ghost." The question was how much of the host universe a ghost can see. Full universe visibility would be information-heavy and complex to stream. Area-limited visibility simplifies both the player experience and the network architecture.

### Decision

Ghosts see only the **immediate vicinity** — the current room or area — not the whole universe. This is a **fog-of-war model** applied to inter-universe observation. The host universe's full state is not streamed to the ghost; only the current room's state is shared.

### Rationale

- **Streaming efficiency** — only current room state must be synchronized, not the entire universe.
- **Information management** — ghosts experiencing only their immediate surroundings creates a more focused, atmospheric interaction.
- **Reduced griefing surface** — limited visibility reduces the ghost's ability to scout or map the host's universe.
- **Network simplicity** — room-scoped synchronization is dramatically simpler than universe-scoped.

### Implications

- Network sync protocol is **room-scoped**, not universe-scoped.
- Ghost transitions between rooms trigger room-state sync events.
- Ghost players cannot see locked rooms, distant areas, or the overall universe shape.
- This pairs well with the no-merge model [D-21] — the ghost's universe is paused, not synced bidirectionally.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-13] Ghost Mechanic | **Refines** — D-20 specifies the visibility constraint for ghosts |
| [D-21] Universe Merge: No Merge | **Paired** — fog of war + no-merge define the full interaction model together |

---

## D-21: Universe Merge: No Merge

### Context

Earlier multiverse architecture [D-7] included a roadmap for universe merge mechanics — conflict resolution, CRDTs, OT, or last-write-wins strategies for when two universes interact. This was significant complexity. As the design evolved, the question arose whether merge was actually necessary.

### Decision

When a ghost is **transformed** into a full participant in a host's universe, they **simply join as-is**. Their own universe **pauses** — it does not merge with, blend into, or conflict-resolve against the host universe. The host universe is canonical; the transformed player plays in it. The ghost's home universe is frozen in place and is resumable when they leave.

**No CRDTs. No OT. No last-write-wins. No merge.**

### Rationale

- **Radical simplification** — merge logic is one of the hardest problems in distributed systems. Eliminating it removes an entire class of complexity.
- **Clear ownership** — host universe is unambiguously canonical. No conflicts can arise.
- **Narrative coherence** — two independent universes blending would break the narrative logic of each. Separate universes stay separate.
- **Player mental model** — "you're visiting their world" is simpler than "our worlds combined."
- **Universe pause is reversible** — the ghost's home universe isn't destroyed; it waits.

### Implications

- **Universe Pause** state must be tracked per-universe in cloud storage [D-18].
- Network architecture handles one active universe at a time per player session.
- Ghost-to-participant transformation is a session transition, not a data merge operation.
- Any objects or items the ghost "brings" need explicit transfer mechanics (not automatic merge).
- The ghost's paused universe can be examined or resumed independently.

### Connections to Prior Decisions

| Prior Decision | Relationship |
|----------------|--------------|
| [D-7] Multiverse MMO Architecture | **Supersedes** — D-21 eliminates the merge/conflict resolution roadmap in D-7 |
| [D-13] Ghost Mechanic | **Resolves** — D-21 defines what happens when a ghost goes full participant |
| [D-20] Ghost Visibility: Fog of War | **Paired** — together D-20 and D-21 define the complete inter-universe interaction model |
| [D-18] Persistence: Cloud Storage | **Requires** — universe pause state must be persisted in cloud |

---

## Deferred / Open Items

| Item | Status | Tracking |
|------|--------|---------|
| Meta-Code Format (D-15) | Deferred — likely Lua tables/closures; awaiting prototyping | [D-15](#d-15-meta-code-format-deferred) |
| Cloud Storage Provider | TBD — specific provider not yet selected | [D-18](#d-18-persistence-cloud-storage) |
| Lua state serialization format | TBD — must be proven compatible with cloud storage | [D-15](#d-15-meta-code-format-deferred), [D-18](#d-18-persistence-cloud-storage) |
| Parser: NLP vs. rich synonyms | Active but detailed approach TBD | [D-19](#d-19-parser-nlp-or-rich-synonyms) |
| Local LLM for parsing | Stretch goal — not required for ship | [D-19](#d-19-parser-nlp-or-rich-synonyms) |
| Ghost-to-participant transfer mechanics | Design work needed | [D-21](#d-21-universe-merge-no-merge) |

---

## Decision Dependency Map

The eight decisions are interdependent. Reading order matters:

```
D-16 (Lua)
  └─► D-14 (True Code Rewrite)  ──► D-18 (Cloud Persistence)
  └─► D-15 (Meta-Code Format)   ──► D-18 (Cloud Persistence)
                                      └─► "The Company"

D-17 (Universe Templates)       ──► D-18 (Cloud Persistence)

D-19 (Parser)                   ──► D-16 (Lua verb tables)

D-20 (Fog of War)  ─────┐
D-21 (No Merge)    ─────┴► together define inter-universe interaction model
```

**Foundation:** D-16 (Lua) underpins everything.  
**Core mechanic:** D-14 (True Code Rewrite) is the design's defining feature.  
**Infrastructure:** D-18 (Cloud) enables both persistence and analytics.  
**Multiplayer shape:** D-20 + D-21 define what "multiverse" means at runtime.

---

## Relationship to Prior Decisions

| Prior Decision | Status After 2026-03-19 |
|----------------|------------------------|
| [D-3] Simple tokenizer + verb dict | **Superseded** by D-19 |
| [D-5] Local SQLite persistence | **Superseded** by D-18 (cloud storage) |
| [D-6] Lua recommendation | **Confirmed** and elevated to active by D-16 |
| [D-7] Merge/conflict resolution roadmap | **Superseded** by D-21 |
| [D-8 §8.2] Code mutation over state flags | **Confirmed** and formalized by D-14 |
| [D-11] Self-modifying universe code | **Confirmed** by D-14 + D-16 |
| [D-12] Engine-driven mutation | **Confirmed** by D-14 |
| [D-13] Ghost mechanic | **Refined** by D-20 (visibility) and D-21 (interaction model) |

---

## Cross-References

- **Vocabulary:** [`docs/architecture/vocabulary.md`](../architecture/vocabulary.md) — definitions for all terms used here
- **Game Design Foundations:** [`docs/design/game-design-foundations.md`](game-design-foundations.md) — verbs, objects, player model
- **Full Decision Log:** [`.squad/decisions.md`](../../.squad/decisions.md) — canonical record of all numbered decisions
- **Research — Language Architecture:** `resources/research/architecture/code-data-blended-languages.md`
- **Research — Modern Structures:** `resources/research/architecture/modern-text-adventure-data-structures.md`

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-19 | Initial document — eight architecture decisions from Wayne's 2026-03-19 session |
