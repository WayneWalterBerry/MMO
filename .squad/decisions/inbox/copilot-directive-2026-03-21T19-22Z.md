### 2026-03-21T19:22Z: User directives — Injuries as first-class entities
**By:** Wayne Berry (via Copilot)

**Directive 1 — Injuries are instances like objects:**
Injuries follow the same pattern as objects: there are base injury TYPES (templates) in `src/meta/injuries/`, and the player holds INJURY INSTANCES (modified copies with per-instance state like turns_active, severity). Same template→instance pattern as objects.

**Directive 2 — Injuries have Windows GUIDs:**
Every injury type gets a Windows-style GUID, same as objects. This is consistent with the metadata identity system.

**Directive 3 — Injuries are JIT-loaded:**
Injury metadata files are individually downloadable from the web site, just like object meta files. They go through the same JIT loader pipeline (bootstrapper → engine → individual .lua files on demand).

**Directive 4 — Design subfolder for injuries:**
Create `docs/design/injuries/` as a sibling to the existing object design docs. This is where the design team documents injury types BEFORE implementation — same workflow as object design.

**Directive 5 — Flanders designs injuries too:**
Update Flanders' charter (Object Systems Engineer) to also be responsible for designing injuries. He already understands FSMs, templates, and the instance pattern. Injuries are a natural extension of his domain.

**Directive 6 — Bob thinks about injuries + puzzles:**
Update Bob's charter (Puzzle Designer) to consider injuries as puzzle mechanics. Injuries create time pressure, gate capabilities, and require specific treatments — all puzzle design surfaces.

**Why:** Wayne is establishing injuries as a first-class game entity on par with objects — same identity system (GUIDs), same loading system (JIT), same design workflow (design docs → implementation), same instance pattern (template → mutable instance).
