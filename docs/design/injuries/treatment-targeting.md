# Treatment Targeting — How Players Apply Cures to Specific Injuries

**Author:** Sideshow Bob (Puzzle Designer)  
**Date:** 2026-07-25  
**Status:** DESIGN  
**Depends On:** Health System (health-system.md), Healing Items (healing-items.md), Injury Catalog  
**Audience:** Designers, Bart (engine), Flanders (objects)

---

## 1. Core Principle: Treat the Injury, Not "Health"

Players never "heal" in the abstract. They apply a specific treatment to a specific injury instance on a specific body part. The command `apply bandage` doesn't "restore HP" — it targets a wound. This keeps healing grounded, physical, and interactive.

**The player's mental model:** "I have a stab wound on my left arm and a cut on my right hand. Which one gets the bandage?"

---

## 2. The `injuries` Verb — Naming Targets

The `injuries` verb is the player's diagnostic tool. It lists every active injury with enough detail to target it:

```
> injuries
You examine yourself:
  A deep stab wound on your left arm (bleeding)
  A minor cut on your right hand (healing)
```

Each injury line provides:
- **What it is** — "deep stab wound," "minor cut"
- **Where it is** — "left arm," "right hand"
- **What state it's in** — "(bleeding)," "(healing)"

These details form the **targeting vocabulary**. The player uses them to compose treatment commands.

---

## 3. Targeting Syntax

### 3.1 Full Target (Multiple Injuries)

When the player has more than one injury that a treatment could apply to, they must specify which one:

```
> apply bandage to left arm wound
> bandage left arm
> wrap bandage around left arm stab wound
```

The parser matches against:
- **Body part** — "left arm," "right hand," "ribs"
- **Injury type** — "stab wound," "cut," "burn"
- **Combination** — "left arm stab wound" (most specific, least ambiguous)

### 3.2 Bare Verb (Single Injury)

When only one injury exists that the treatment could help, the bare verb works:

```
> apply bandage
You carefully wrap the bandage around your left arm...
```

This follows the same **context resolution** pattern as objects: if there's only one valid target, the parser doesn't force the player to spell it out. Same as `take key` working when there's only one key in the room.

### 3.3 Ambiguity Resolution

When the bare verb could apply to multiple injuries:

```
> apply bandage
Which wound? You have:
  A deep stab wound on your left arm (bleeding)
  A gash on your right leg (bleeding)
```

The player must disambiguate:

```
> apply bandage to left arm
You carefully wrap the bandage around your left arm...
```

This is the same disambiguation pattern the engine uses for objects ("Which key? The brass key or the iron key?").

---

## 4. Parser Resolution Rules

### 4.1 Resolution Priority

1. **Exact match:** Player names both injury and body part → unambiguous target
2. **Body part match:** Player names only body part → match if only one injury on that part
3. **Injury type match:** Player names only injury type → match if only one of that type
4. **Single candidate:** Only one injury that the treatment item can treat → auto-resolve
5. **Ambiguous:** Multiple valid targets → prompt player to specify

### 4.2 Treatment Compatibility Check

The parser checks whether the treatment item is *compatible* with the targeted injury before applying:

```
> apply bandage to bruised ribs
"You press the bandage against your bruised ribs. It doesn't help —
 there's nothing to bind, no bleeding to stop. Bruises need rest,
 not wrapping."
```

A bandage targets bleeding/cuts. Applying it to a bruise fails with a helpful message. The item's behavior (consumed or not) depends on its type — see healing-items.md §12 for consumable vs. reusable rules.

### 4.3 The `injuries` Verb as Target Reference

The exact phrasing from `injuries` output is always a valid targeting phrase:

```
> injuries
You examine yourself:
  A deep stab wound on your left arm (bleeding)

> apply bandage to deep stab wound on left arm
You carefully wrap the bandage around your left arm...
```

Players can use shorter forms ("left arm," "stab wound," "arm wound") but the full `injuries` text always works. This means the player is never stuck guessing the right words — `injuries` tells them.

---

## 5. Example Interaction Flows

### 5.1 Single Injury — Simple Case

```
> injuries
You examine yourself:
  A deep gash on your forearm (bleeding). Blood flows freely.
  It won't stop on its own — you need something wrapped tight.

> apply bandage
You wrap the cloth strip tightly around your wounded forearm.
The bleeding slows... and stops. The bandage holds.
```

One injury, one valid treatment. Bare verb resolves automatically.

### 5.2 Multiple Injuries — Disambiguation Required

```
> injuries
You examine yourself:
  A deep stab wound on your left arm (bleeding)
  A minor cut on your right hand (healing)

> apply bandage
Which wound? You have a bleeding stab wound on your left arm
and a cut on your right hand.

> apply bandage to left arm wound
You carefully wrap the bandage around your left arm.
The bleeding slows... and stops. The bandage holds.
```

Two wounds that accept bandages. Player must choose.

### 5.3 Multiple Injuries — Different Types

```
> injuries
You examine yourself:
  A deep gash on your arm (bleeding)
  Your fingertips are red and tender (burned)

> apply bandage
You wrap the cloth strip tightly around your wounded arm.
The bleeding slows... and stops.
```

Two injuries, but only one is treatable by bandage. Auto-resolves to the bleeding wound. The burn needs water, not cloth — the parser doesn't even consider it as a bandage target.

### 5.4 Wrong Treatment — Helpful Failure

```
> injuries
You examine yourself:
  Bruised ribs from the fall. Breathing hurts.

> apply bandage to ribs
"You wrap the bandage around your bruised ribs. It doesn't help —
 there's nothing to bind. The bruising is deep in the muscle.
 Only time and rest will heal this."
```

### 5.5 Reusable Treatment — Bandage Recovery

```
> injuries
You examine yourself:
  The wound on your left arm has closed. The bandage is no longer needed.
  A fresh gash on your right leg (bleeding).

> remove bandage from left arm
You carefully unwrap the bandage from your healed arm.
The cloth strip is stained but serviceable.

> apply bandage to right leg
You wrap the bandage tightly around the gash on your leg.
The bleeding slows... and stops.
```

The bandage is a reusable resource — remove from healed wound, apply to new one. See healing-items.md §12 for the full bandage lifecycle.

---

## 6. Edge Cases

### 6.1 No Injuries

```
> apply bandage
"You don't have any wounds that need bandaging."
```

### 6.2 No Treatment Item

```
> bandage arm
"You don't have anything to bandage with. You need cloth —
 something you can tear into strips and wrap tight."
```

### 6.3 Treatment Already Applied

```
> apply bandage to left arm
"Your left arm is already bandaged. The bleeding has stopped."
```

### 6.4 Bandage Already In Use

```
> apply bandage to right leg
"That bandage is already wrapped around your left arm wound.
 You'd need to remove it first — but the arm is still bleeding."
```

A bandage instance can only be on one injury at a time. To reuse it, the player must remove it from the current wound (only safe when that wound has healed).

---

## 7. Design Rationale

Treatment targeting creates three layers of gameplay:

1. **Diagnosis** — Use `injuries` to understand what's wrong and where
2. **Triage** — With multiple injuries and limited supplies, choose which wound gets treated first
3. **Resource management** — Bandages are reusable but scarce; salves are one-shot; every application is a decision

The targeting system transforms healing from "press heal button" into an interactive problem-solving loop: assess, decide, act.

---

## See Also

- [healing-items.md](../player/healing-items.md) — Treatment item types, lifecycles, consumable vs. reusable
- [health-system.md](../player/health-system.md) — Derived health, injury accumulation
- [bleeding.md](./bleeding.md) — Bandage as primary treatment
- [minor-cut.md](./minor-cut.md) — Optional bandage treatment
