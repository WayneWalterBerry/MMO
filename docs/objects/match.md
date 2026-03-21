# Match — Object Design

## Description
A wooden match from the matchbox. The player's initial fire source. Single-use consumable — once lit and extinguished (by timer or player), it cannot be relit.

## Location
Inside the matchbox (container), which is in the nightstand drawer.

## FSM States

```
unlit → lit → spent
         ↓
       spent (blown out by player — same end state)
```

- **unlit** — Fresh match. Can be struck to light.
- **lit** — Burning. Emits light. Timer ACTIVE (3 ticks). Provides fire source capability.
- **spent** — Burned out OR blown out. Blackened stick. Cannot be relit. No light. No fire.

**Key difference from candle:** There is NO "unlit (partial)" state. Extinguishing a match = spent. Period.

## Timer Behavior

- Timer **starts** on strike/light transition to `lit`
- Timer **counts down** 3 ticks
- Timer **expires** → auto-transition to `spent`
- If player blows out match → **immediate transition to `spent`** (NOT to unlit)
- No pause/resume — once lit, it either burns out or gets blown out. Either way: spent.

## Extinguish Mechanic

**Verbs:** `blow out match`, `extinguish match`, `put out match`

- Transitions from `lit` → `spent` (NOT `unlit`)
- Message: "You blow out the match. The blackened head crumbles. It's useless now."
- This is DIFFERENT from candle extinguish (which goes to unlit/partial)

## Why Matches Are Different From Candles

| Behavior | Match | Candle |
|----------|-------|--------|
| Relight after extinguish | ❌ No — spent forever | ✅ Yes — partial burn |
| Burn duration | 3 ticks (short) | 100 ticks (long) |
| Extinguish result | `spent` | `unlit` (partial) |
| Consumable type | One-shot | Pausable/resumable |
| Conservation matters | Yes — limited supply in matchbox | Less — long burn time |

## Sensory Descriptions

| State | Look | Feel | Smell |
|-------|------|------|-------|
| unlit | A wooden match with a bulbous sulfur head | Thin wooden stick, rough head | Faint sulfur |
| lit | A match burns with a bright yellow flame | Hot! The wood is charring | Sulfur and burning wood |
| spent | A blackened match stick, head crumbled | Thin charred stick, fragile | Stale smoke |

## Design Directives (from Wayne)

1. Match has a timer — burns down when lit (3 ticks)
2. If blown out or extinguished, match goes to SPENT (not unlit)
3. A blown-out match CANNOT be relit — the head is consumed
4. Different from candle: candle can be relit, match cannot
5. This makes match conservation important — limited supply in matchbox

## Material

**Material:** `wood` — references the material registry (matchstick body is wood; head is sulfur compound).

## Mutate Fields (Added 2026-07-20)

Transition-level property mutations applied by `apply_mutations()`:

| Transition | Mutate |
|---|---|
| unlit → lit | `keywords = { add = "burning" }` |
| lit → spent (manual) | `weight = 0.005`, `keywords = { add = "blackened" }`, `categories = { add = "useless" }` |
| lit → spent (auto) | `weight = 0.005`, `keywords = { add = "blackened" }`, `categories = { add = "useless" }` |

**Design rationale:** A spent match is a different thing — barely any weight, "blackened" keyword for parser resolution ("DROP BLACKENED MATCH"), "useless" category for engine hinting.
