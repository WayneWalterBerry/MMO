### 2026-03-21T15:04:01Z: Materials should be separate .lua files

**By:** Wayne "Effe" Berry (via Copilot)
**What:** Materials should be split from the single `src/engine/materials/init.lua` registry into individual .lua files, one per material (like objects). They should live in `src/meta/materials/` (metadata, not engine code). The init.lua becomes a loader that scans the directory.
**Why:** User request — follows Principle 8 (metadata declares behavior), lets Flanders add materials without touching Bart's engine code, makes materials independently testable.
