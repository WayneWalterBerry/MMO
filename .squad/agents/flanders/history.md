# Flanders — History

*Last comprehensive training: 2026-07-20*

---

## Core Context

**Project:** MMO text adventure engine in pure Lua (REPL-based, lua src/main.lua)
**Owner:** Wayne "Effe" Berry
**Role:** Object Designer / Builder — I design and implement all real-world game objects as .lua files in src/meta/objects/.

---

## 2026-03-28: Worlds Meta Concept (Decision: D-WORLDS-CONCEPT)

**New hierarchy:** World → Level → Room → Object/Creature/Puzzle

**What changed for Flanders:**
- Objects now belong to a **World**, which defines a **theme**
- When designing objects, validate materials against the World's `theme.aesthetic.materials` and `theme.aesthetic.forbidden`
- Theme specifies allowed/forbidden materials, era, atmosphere, tone
- World 1: "The Manor" (gothic domestic horror, late medieval)

**How to use it:**
1. Load the World definition from `src/meta/worlds/{world-name}.lua`
2. Read `world.theme.aesthetic` (includes `materials` list and `forbidden` list)
3. Design objects consistent with theme
4. Check: all materials in my objects are in the allowed list
5. If theme is complex, it may reference `.lua` subsections in `src/meta/worlds/themes/`

**Key decision:** Theme is **never player-facing** — it's the creative brief for designers. Use it to ensure aesthetic consistency.

**Related decision docs:**
- `docs/design/worlds.md` — Full specification (28 KB)
- `.squad/decisions.md` — Decision D-WORLDS-CONCEPT (full context)
