# Decisions from Pass 025+026 Bug Fixes

**Author:** Smithers (UI Engineer)
**Date:** 2026-07-25
**Context:** Fixing 13 P0/P1 bugs from Nelson's test passes 025 and 026

---

### D-BUG087: preprocess.strip_articles() is a public API
**Status:** Implemented
**Affects:** preprocess.lua, verbs/init.lua, search modules

Added `preprocess.strip_articles(noun)` as a public function. Strips leading "the", "a", "an" from noun phrases. Used by verb handlers (search, find) and search traversal matching. All search/find paths must strip articles before matching against object keywords.

---

### D-BUG085: Adverb stripping is bidirectional
**Status:** Implemented
**Affects:** preprocess.lua

Leading adverbs ("thoroughly search") are now stripped in addition to trailing adverbs ("search carefully"). Added: thoroughly, carefully, closely, quickly, slowly, gently, quietly, frantically, desperately. New adverbs should be added to BOTH leading and trailing lists.

---

### D-BUG078: "everything"/"anything"/"all" are sweep keywords
**Status:** Implemented
**Affects:** preprocess.lua, verbs/init.lua

These words trigger undirected room sweep in both preprocess (find/search paths) and verb handlers. They should never be treated as literal object names.

---

### D-BUG088: Narrator templates must not prepend articles
**Status:** Implemented
**Affects:** search/narrator.lua

Step narrative templates use `{object}` directly WITHOUT "the" prefix. The `format_object_name()` function handles article selection. Any new templates must follow this pattern to avoid doubled articles like "the a large bed".

---

### D-BUG082: Parts can be search scopes via parent fallback
**Status:** Implemented
**Affects:** verbs/init.lua, search/traverse.lua

When a search scope resolves to a part (e.g., "drawer" → nightstand's drawer part), the search uses the parent object as scope. This is handled in two places:
1. Verb handler: captures `(obj, loc_type, parent)` from `find_visible` and redirects when `loc_type == "part"`
2. traverse.build_queue: checks room object parts when scope isn't in proximity list

---

### D-BUG090: Goal planner has hard safety limits
**Status:** Implemented
**Affects:** goal_planner.lua

- MAX_PLAN_STEPS = 20: Plans with more steps are rejected with a user-friendly message
- Visited set capped at 50 entries: Prevents runaway backward-chaining
- MAX_DEPTH = 5 (unchanged): Recursion depth limit for plan_for_tool

---

### D-BUG079: Scoped undirected search enumerates contents
**Status:** Implemented
**Affects:** search/traverse.lua

When target is nil (undirected) and scope is set, traverse.step now enumerates surface and container contents with "Inside you find: X, Y, Z." messages. Previously it only checked for target matches, which meant scoped sweeps silently found nothing.

---

### D-CONTAINER-QUESTIONS: Container question patterns return "examine"
**Status:** Implemented
**Affects:** preprocess.lua

"What's inside X?" and "What's in X?" patterns now return `("examine", noun)` instead of `("look", "in " .. noun)`. This routes through the examine handler which has proper dark-mode fallback to feel, rather than the look handler which requires light.
