### 2026-03-19T153051Z: Design directive — Summary vs Detail descriptions
**By:** Wayne "Effe" Berry (via Copilot)
**What:** When doing a room sweep (FEEL AROUND, LOOK), show SHORT summaries only — not the full detailed descriptions. The detailed text (in parens in the play test) is too much for a list. Players should EXAMINE or FEEL {specific object} to get the deep description.

**Two tiers of description:**
- **Summary** (used in room sweep / LOOK / FEEL AROUND): brief, 5-10 words max. Just enough to identify the object.
  - "a small nightstand"
  - "a ceramic chamber pot"
  - "heavy velvet curtains"
- **Detail** (used in EXAMINE {object} / FEEL {object} / LOOK AT {object}): the full rich description.
  - "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front."

**Implementation:**
- Objects need a `summary` or short `name` field for the list view
- `on_feel` / `description` remain the DETAILED versions, shown only on direct examination
- Room sweep (FEEL AROUND) shows: "Your hands find: a small nightstand, heavy velvet curtains, a ceramic chamber pot..."
- FEEL nightstand → shows the full on_feel text
- Same principle for LOOK: room description is brief, EXAMINE gives detail

**Why:** User request — information hierarchy. Don't dump everything at once. Let the player drill down. Progressive disclosure.
