# Decision: Injury Object Implementation Patterns

**Author:** Flanders (Object & Injury Systems Engineer)
**Date:** 2026-07-25
**Scope:** Poison bottle upgrade, bear trap creation, crushing wound injury template

---

## D-INJURY001: Structured Effect Tables Over Legacy Strings

**Decision:** All new injury-causing transitions use structured `effect = { type = "inflict_injury", ... }` tables, not legacy `effect = "poison"` strings.

**Rationale:** Bart's effect processing pipeline architecture (`docs/architecture/engine/event-hooks.md` §3.3) proposes a unified `effects.process()` dispatcher. Structured tables carry all metadata (injury_type, source, damage, location, message) so the engine never needs hardcoded mappings. The poison bottle's drink transition was upgraded from `effect = "poison"` to the full table format.

**Impact:** Bart — the effect processing pipeline can now dispatch these directly without needing `normalize_effect()` for new objects. Old objects with string effects still need the legacy map.

---

## D-INJURY002: Crushing Wound as New Injury Type

**Decision:** Created `crushing-wound.lua` as a distinct injury type rather than reusing `bleeding.lua` or `bruised.lua`.

**Rationale:** CBG's bear trap design specifies a hybrid: immediate blunt force (15 damage) + ongoing bleeding from crushed tissue (2/tick). Pure bleeding has no initial crushing component. Pure bruised has no bleeding component. The crushing wound combines both — bandaging stops the bleed but the deep bruise persists and self-heals over time.

**Impact:** The injury registry now has 7 types: minor-cut, bleeding, bruised, burn, poisoned-nightshade, concussion, crushing-wound. Future crushing sources (falling debris, collapsing structures) can reuse this template.

---

## D-INJURY003: Label as Non-Detachable Readable Part

**Decision:** The poison bottle's label is implemented as a `parts.label` entry with `detachable = false` and `readable = true`, rather than embedding readable text in the bottle's state descriptions.

**Rationale:** CBG's design explicitly calls out the label as a separate interactive component. Implementing it as a part enables proper `read label` / `examine label` verb support through the engine's composite object system, rather than requiring the engine to parse label text out of the bottle's description string. This follows Principle 4 (Composite Objects Encapsulate Inner Objects).

**Impact:** Bart — the engine needs to resolve `read label` to the label part's `readable_text` field. Same pattern as other non-detachable parts.

---

## D-INJURY004: Bear Trap Disarm Uses Guard Function

**Decision:** The disarm transition uses a `guard` function checking `context.player.has_skill("lockpicking")` in addition to `requires_tool = "thin_tool"`.

**Rationale:** The `requires_tool` field handles tool checking (the engine already does this). But skill checking needs player context, which isn't available through simple property matching. The `guard` function is the established pattern for conditional transitions that need runtime context (per FSM architecture in history.md).

**Impact:** Bart — the disarm verb handler must pass player context to the guard function. The existing FSM transition executor already supports `guard(obj, context)`.

---

## D-INJURY005: Bear Trap Self-Transitions for Safe Take

**Decision:** The bear trap has self-transitions (`triggered → triggered`, `disarmed → disarmed`) for the `take` verb, rather than omitting the verb and falling through to default take behavior.

**Rationale:** The trap needs custom messages when taken in safe states ("It's heavy, and blood stains the jaws, but it won't bite again"). The `portable` property mutation in the triggered self-transition also enables taking a previously non-portable object. Without the explicit transition, the default take handler might reject the action because `portable = false` in the base object.

**Impact:** None — self-transitions are already supported by the FSM executor.
