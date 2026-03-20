# Candle Holder — Object Design

## Description
A brass candle holder on the nightstand. Holds a tallow candle securely, allowing the player to carry a lit candle without burning their hand.

## Location
Bedroom — on the nightstand (the candle is IN the holder at game start)

## Composite Object
The candle holder is a **composite** — it contains the candle as a detachable part.

```
candle-holder (parent)
  └── candle (detachable part)
```

Single file: `candle-holder.lua` defines both objects.

## FSM States

```
holding_candle → empty (candle removed)
empty → holding_candle (candle inserted)
```

## Interactions

| Action | Result |
|--------|--------|
| `take candle holder` | Pick up holder with candle inside (1 hand) |
| `remove candle` / `take candle out` | Detach candle from holder |
| `put candle in holder` | Reattach candle to holder |
| `light candle` (in holder) | Candle lights, holder makes it safe to carry |
| `light candle` (not in holder) | Candle lights but falls over / can't carry |

## Why the Holder Matters

| Scenario | Candle in Holder | Candle Alone |
|----------|-----------------|--------------|
| Carry while lit | ✅ Safe, 1 hand | ❌ Burns hand / falls over |
| Stand on surface | ✅ Upright in holder | ❌ Falls over, goes out |
| Light source | ✅ Portable | ⚠️ Stationary only (if propped) |

## Sensory Descriptions

| State | Look | Feel |
|-------|------|------|
| With candle (unlit) | A brass candle holder with a tallow candle | Cool brass ring, waxy candle protrudes |
| With candle (lit) | A brass candle holder, candle burning with steady flame | Warm brass, heat radiates upward |
| Empty | An empty brass candle holder | Cool brass ring, hollow center |

## Design Directives (from Wayne)

1. Candle should be in a candle holder
2. Candle can be removed from holder (composite/detachable)
3. Holder prevents burning your hand when carrying a lit candle
4. Without holder, candle falls over — can't carry while lit
5. Bedroom starts with candle in candle holder on nightstand
6. Single .lua file defines both holder and candle
