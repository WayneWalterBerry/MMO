# Bug Tracker

This is the canonical bug database for the MMO project. Every bug found by Nelson (play tester) or reported by players is tracked here.

## Rules

1. **Every bug gets an entry** — even if it's fixed immediately
2. **Fixed bugs need a regression unit test** — no test = not really fixed (it will come back)
3. **Understood column** — do we know the root cause? "yes" means we traced the actual code path, not just applied a workaround
4. **Status values:** `open`, `fixed`, `wont-fix`, `cannot-reproduce`

## Open Bugs

| Bug ID | Summary | Found In | Understood | Assigned To | Regression Test |
|--------|---------|----------|------------|-------------|-----------------|
| BUG-069 | `sleep` → dawn error message is wrong | pass-022 | no | unassigned | ❌ |
| BUG-071 | Rapid `look around` command spam can hang game | pass-023 | no | unassigned | ❌ |
| BUG-072 | Screen flicker during progressive object discovery | pass-023 | no | unassigned | ❌ |
| BUG-104b | `please could you have a look around` — politeness + idiom combo breaks parser | pass-032 | no | unassigned | ❌ |
| BUG-105 | `what do I do?` causes infinite hang — game crash on common player phrase | pass-031 | no | unassigned | ❌ CRITICAL |
| BUG-106 | `what now?` causes infinite hang — game crash on common player phrase | pass-031 | no | unassigned | ❌ CRITICAL |
| BUG-112 | `look under this` hangs after examining object — pronoun + look-under pattern | pass-033 | no | unassigned | ❌ |
| BUG-113 | `pick up` (bare, no noun) after search discovery doesn't auto-fill context | pass-033 | no | unassigned | ❌ |
| BUG-114 | `take the one I found` — discovery context not tracked across commands | pass-033 | no | unassigned | ❌ |
| BUG-115 | `the thing on the nightstand` — vague spatial references not resolved | pass-033 | no | unassigned | ❌ |

## Fixed Bugs

| Bug ID | Summary | Found In | Understood | Fixed By | Regression Test |
|--------|---------|----------|------------|----------|-----------------|
| BUG-070 | Excessive blank lines in output | pass-023 | yes | smithers | ❌ needs test |
| BUG-078 | `find everything` treats "everything" as literal target | pass-025 | yes | smithers | ✅ |
| BUG-079 | Scoped search (`search nightstand`) finds nothing | pass-025 | yes | smithers | ✅ |
| BUG-080 | `search wardrobe` hangs — container recursion | pass-025 | yes | smithers + bart (visited sets) | ✅ |
| BUG-081 | Articles "the"/"a" not stripped from find targets | pass-025 | yes | smithers | ✅ |
| BUG-082 | Drawer not recognized as valid search scope | pass-025 | yes | smithers | ✅ |
| BUG-083 | Politeness stripping breaks "search for" compound | pass-025 | yes | smithers | ✅ |
| BUG-084 | `what can I find?` / `find a match and light it` hang | pass-025 | yes | smithers | ✅ |
| BUG-085 | "thoroughly" not in adverb strip list | pass-025 | yes | smithers | ✅ |
| BUG-086 | `check the nightstand` hangs — embedding matcher | pass-025 | yes | smithers | ✅ |
| BUG-087 | `look at nightstand` hangs — "look at X" not parsed | pass-025 | yes | smithers | ✅ |
| BUG-088 | Doubled article in search narration "You feel the a..." | pass-025 | yes | smithers | ✅ |
| BUG-089 | `feel inside drawer` shows nightstand top surface too | pass-026 | yes | smithers | ✅ |
| BUG-090 | `light candle` hangs — RELEASE BLOCKER — goal planner stuck | pass-026 | yes | smithers | ✅ |
| BUG-091 | `take match` picks up spent match from floor, not fresh | pass-026 | yes | smithers | ⚠️ partial (auto-chain works, manual fails) |
| BUG-092 | Status bar match counter never decrements | pass-026 | yes | smithers | ⚠️ partial (works auto-chain, fails manual) |
| BUG-093 | `rummage around` hangs — missing synonym | pass-027 | yes | smithers | ✅ |
| BUG-094 | `look for a candle` hangs | pass-027 | yes | smithers | ✅ |
| BUG-095 | Wardrobe shows contents while closed | pass-028 | yes | smithers | ✅ |
| BUG-096 | Gating message says "nightstand" when targeting "drawer" | pass-028 | yes | smithers | ✅ |
| BUG-097 | `look inside drawer` (closed, lit) shows description not closed message | pass-028 | yes | smithers | ✅ |
| BUG-104 | `what's this?` hangs | pass-031 | yes | smithers | ✅ |
| BUG-107 | `would you mind examining X` — preamble not stripped | pass-031 | yes | smithers (gerund stripping) | ✅ |
| BUG-108 | `I'd like to know what's in X` — preamble not stripped | pass-031 | yes | smithers | ✅ |
| BUG-109 | `have a look` idiom not working in game | pass-031 | yes | smithers | ✅ |
| BUG-110 | `where is the matchbox?` searches wrong thing | pass-031 | yes | smithers | ✅ |
| BUG-111 | `search for matches` — "matches" doesn't fuzzy-match "matchbox" | pass-031 | yes | smithers (singularize) | ✅ |

## Notation

- **Found In:** Which Nelson test pass first reported the bug
- **Understood:** Do we know the root cause code path? "yes" = traced, "no" = symptoms only
- **Regression Test:** ✅ = unit test exists that would catch this if it regressed. ❌ = no test yet
- Bug IDs with "b" suffix (e.g., BUG-104b) indicate a different bug that Nelson assigned the same number to in a later pass
