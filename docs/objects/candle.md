# Candle — Object Design

## Description
A tallow candle on the nightstand. The player's primary light source after the match burns out. Can be lit, extinguished, and relit.

## FSM States

```
unlit → lit → stub → spent
         ↕
      unlit (extinguished, partial burn)
```

- **unlit** — Default. No light. Can be lit with a fire source.
- **lit** — Emits light. Burns down over time (100 ticks full, less if partially consumed). Timer ACTIVE.
- **stub** — Low wax remaining (20 ticks). Flickering light. Warning messages. Timer ACTIVE.
- **spent** — No wax left. Cannot be relit. Dead object.
- **unlit (partial)** — Player extinguished the candle before it burned out. Remaining burn time preserved. Timer PAUSED.

## Timer Behavior

**Pattern:** Object-owned timer, managed by engine timed events system.

- Timer **starts** on FSM transition to `lit`
- Timer **pauses** on FSM transition to `unlit` (extinguished by player)
- Timer **resumes** on FSM transition back to `lit` (relit)
- Timer **expires** → auto-transition to `stub` (then `spent`)
- `burn_remaining` tracks remaining ticks — decrements only while `lit`
- A candle lit for 50 ticks then blown out has 50 ticks remaining when relit

## Extinguish Mechanic

**Verbs:** `blow out candle`, `extinguish candle`, `put out candle`, `snuff candle`

- Transitions from `lit` → `unlit`
- Does NOT consume the candle — it's partially burned
- Room goes dark (unless other light source exists)
- Message: "You blow out the candle. A thin trail of smoke rises from the wick. Darkness closes in."
- `burn_remaining` is preserved at current value

## Relight Mechanic

- Requires fire source (lit match)
- Transitions from `unlit` → `lit`
- `burn_remaining` continues from where it was paused
- Message varies by remaining wax: "The candle flickers back to life." / "The stub sputters back to life, wax pooling around the base."

## Sensory Descriptions by State

| State | Look | Feel | Smell |
|-------|------|------|-------|
| unlit (new) | A tallow candle, unlit, with a fresh wick | Smooth waxy cylinder, cool to the touch | Faint tallow smell |
| unlit (partial) | A half-burned candle, wick blackened | Rough wax drippings, warm from recent burning | Smoke and tallow |
| lit | A candle burns with a steady yellow flame | Warm wax, heat radiates | Burning tallow, slight smoke |
| stub | A candle stub gutters, wax nearly gone | Hot wax pool, tiny nub | Strong tallow smoke |
| spent | A puddle of hardened wax with a blackened wick | Hard flat wax disc, cold | Stale smoke |

## Connection to Candle Holder

The candle lives INSIDE a candle holder (see [candle-holder.md](candle-holder.md)):
- **In holder:** portable, safe to carry while lit, stands upright
- **Out of holder:** falls over, can't carry while lit, burns hand
- The holder is what makes the candle a useful portable light source
- Both defined in `candle-holder.lua` (composite object pattern)

## Connection to Timed Events System

The candle is the **reference implementation** for the timed events architecture:
- Timer metadata lives in `candle.lua` (object-owned, not engine-hardcoded)
- Engine reads timer config from object metadata on room load
- FSM state transitions start/stop the timer
- Same pattern applies to: wall clock (recurring), time bomb (one-shot), dripping water (ambient)

## Design Directives (from Wayne)

1. Player can blow out the candle — it's partially consumed, not spent
2. Timer runs only when lit, pauses when extinguished
3. Relighting resumes from remaining burn time
4. All FSM + timer metadata in candle.lua
5. This ties into the timed events system (clocks, time bombs)

## Material

**Material:** `wax` — references the material registry for physical properties (melting_point, flammability, etc.)

## Mutate Fields (Added 2026-07-20)

Transition-level property mutations applied by `apply_mutations()`:

| Transition | Mutate |
|---|---|
| lit → extinguished | `weight = function(w) return math.max(w * 0.7, 0.1) end`, `keywords = { add = "half-burned" }` |
| lit → spent (auto) | `weight = 0.05`, `size = 0`, `keywords = { add = "nub" }`, `categories = { remove = "light source" }` |

**Design rationale:** Weight decreases proportionally each extinguish cycle (you don't know how long it burned). Spent candle uses absolute values (fully consumed). The "light source" category drops when the candle can never be relit.
