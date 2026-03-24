### 2026-03-24T19:56:23Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** Moving materials to src/meta/ means they must be handled by the web loader like objects — downloaded on-demand and cached in the browser. The engine already has code to download/cache meta objects for the web build. Materials in meta must follow the same pattern. See existing object loader code for the pattern.
**Why:** User request — critical implementation constraint for #123 material migration. Without this, materials won't load in the browser.
