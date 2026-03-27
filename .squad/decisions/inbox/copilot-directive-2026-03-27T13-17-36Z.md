### 2026-03-27T13:17:36Z: User directive
**By:** Wayne "Effe" Berry (via Copilot)
**What:** The mutation graph linter must dynamically discover ALL .lua files under src/meta/ and all its subdirectories (objects/, creatures/, injuries/, world/, templates/, levels/, and any future subfolders). It must NOT use a hardcoded list of .lua files — the file set changes over time as content is added.
**Why:** User request — captured for team memory. Future-proofing the linter against content growth.
