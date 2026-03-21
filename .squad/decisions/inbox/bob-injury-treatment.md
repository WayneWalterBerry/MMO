### 2026-07-25: Injury treatment targeting and item lifecycles — Bob
**By:** Sideshow Bob (Puzzle Designer)

**What happened:** Updated the full injury/healing design doc suite per Wayne's directive 2026-03-21T20:05Z. Three major additions:

1. **Injury accumulation is now explicit.** Health-system.md §1.3 has a worked example showing how multiple injuries stack their damage (two stab wounds = double drain per turn). All 5 injury docs updated with accumulation notes and cross-references.

2. **Treatment targeting is documented.** New file `docs/design/injuries/treatment-targeting.md` covers how players apply cures to specific injury instances ("apply bandage to left arm wound"), context resolution when only one injury exists, disambiguation prompts for multiple injuries, and edge cases. All injury docs updated with targeted treatment examples.

3. **Bandage is now reusable; salve/antidote are consumable.** Healing-items.md §12 has full lifecycle FSMs for both patterns. Bandage: clean → applied (attached to injury) → removable (wound healed) → reusable. Salve: sealed → applied → empty (destroyed). This changes the bandage from a one-shot consumable to a persistent, manageable resource.

**Design impact:**
- Bandage triage becomes a real puzzle (which wound gets the one bandage?)
- Bandage reuse loop adds resource management gameplay
- Consumable salves/antidotes carry permanent risk of waste on wrong target
- Reusable bandages are forgiving to experiment with

**Files created:** `docs/design/injuries/treatment-targeting.md`
**Files modified:** `healing-items.md`, `health-system.md`, `bleeding.md`, `minor-cut.md`, `burn.md`, `poisoned-nightshade.md`, `bruised.md`, `injuries/README.md`

**Needs from others:**
- **Bart:** Parser support for "apply X to Y" where Y is an injury. Bandage attachment tracking on injury instances.
- **Flanders:** Bandage FSM (clean/applied/removable/reusable). Consumable terminal states for salve/antidote.
- **Nelson:** Test targeting, disambiguation, bandage reuse loop, consumable destruction.
