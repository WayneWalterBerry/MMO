# Wayne "Effe" Berry — Senior Engineer Contributions

**Role:** Senior Engineer, Project Owner (40 years experience)  
**Tracking since:** 2026-03-23  
**Last updated:** 2026-03-23

---

## Summary

Wayne brings four decades of interactive fiction and systems design expertise to this AI-assisted game development project. His core value lies in preventing the entire class of architectural mistakes that AI and human teams naturally drift toward when building game engines.

His contributions fall into two categories:
1. **Foundational decisions** that shaped the system architecture (deep nesting, composite objects, immutability of containers)
2. **Quality gates & empirical testing** that catch the failures that unit tests miss (live play-testing, deployment verification, regression enforcement)

Without Wayne's intervention, the team would have shipped a system where spatial relationships are ambiguous, containers allow logical impossibilities (pillows inside solid nightstands), objects can mysteriously disappear during deployment, and bugs exist that no automated test suite catches.

---

## Architectural Decisions

### 1. Deep Nesting for Room .lua Files (Principle 0.5)

**Decision:** Rooms describe themselves through deeply nested Lua tables using four relationship keys: `on_top`, `contents`, `nested`, `underneath`.

**Why it matters:**
- The nesting IS the room's physical description — readable at a glance by a human author
- Eliminates separate room maps or spatial metadata files; topology is encoded in code structure
- Self-documenting: looking at the table structure instantly shows the room layout
- Prevents entire class of spatial bugs where object relationships get out of sync with descriptions

**What would have gone wrong:**
- Flat object lists would require separate metadata files mapping spatial relationships (room_map.json, locations.lua)
- Easy to get inconsistent: object says "on nightstand" but nightstand's JSON says it's not there
- Room descriptions would drift from actual object positions during development
- New team members couldn't visually understand room topology without consulting external docs

**Evidence:** The startup room used flat object lists initially. It required multiple fixes to keep descriptions in sync with object locations.

---

### 2. Composite Objects as First-Class Entities (Principle 4 + D-2)

**Decision:** Objects that contain removable parts (nightstand + drawer, poison bottle + cork, bed + curtains) are defined in a single parent .lua file with factory functions for detachable parts. Each part gets its own GUID.

**Why it matters:**
- Drawer is NOT a "surface" of the nightstand — it's a real object with independent state
- "Put pillow inside nightstand" correctly fails (nightstand has no `contents` key)
- "Put pillow inside drawer" correctly succeeds (drawer inherits `contents` from container template)
- Prevents "I wanted to close the drawer and trap the player" bugs

**What would have gone wrong:**
- Representing drawer as a surface would allow `put X inside nightstand` to work for drawer contents
- Game designer puts pillow "inside" the nightstand surface, intending it to go in the drawer
- Player types "put pillow in nightstand" expecting it to fail, but it succeeds (logical error)
- Detaching drawer leaves pillow magically in nightstand's nowhere
- Spatial relationships become unmappable: is the pillow in the drawer or the nightstand?

**Evidence:** Early discussion suggested drawer as a surface. Wayne rejected this immediately.

---

### 3. "Objects Are Inanimate" (Principle 0)

**Decision:** The object system is exclusively for physical things. Living creatures (rats, guards, NPCs) are NOT objects and never will be.

**Why it matters:**
- Prevents fundamental architectural confusion: objects don't pursue goals, creatures do
- Objects are stateless (state is owned by the player and engine); creatures need persistent agency
- Creatures need pathfinding, dialogue, memory; objects need state machines and verb handlers
- Clear boundary prevents the object system from bloating with NPC subsystems

**What would have gone wrong:**
- Without this boundary, team would try to model a rat as an object with state "in_cage", "escaped", "dead"
- Rat would need AI behavior (seek player, flee threats, navigate maze) — doesn't fit object model
- Object system would need dialogue trees, goal hierarchies, memory systems
- Game would ship with architectural confusion: is a rat an object, an actor, or something else?
- Engine code would become unmaintainable as object handlers started branching on "is this alive?"

**Evidence:** Early discussions about rat behavior. Wayne immediately redirected: "This is a future creature system, not objects."

---

### 4. Nightstand Must NOT Have "Inside" (Principle 0.5, REQ-002)

**Decision:** Solid furniture (nightstand, bed, dresser, wardrobe) has NO `contents` key. Only drawers/containers have `contents`.

**Why it matters:**
- Prevents the most subtle spatial design bug: the player expectation mismatch
- Player types "put book inside nightstand" — engine should fail (nightstand is solid)
- Player types "put book inside drawer" (drawer is inside nightstand) — engine should succeed
- The engine can enforce this rule by checking for `contents` key existence

**What would have gone wrong:**
- If nightstand had empty `contents = {}`, the command "put book inside nightstand" would succeed
- Game designer intended this to fail, but the code allowed it
- Player can now bypass spatial constraints that should be game-critical
- Hidden mechanic becomes: "solid furniture accepts items if the designer remembers to keep contents empty"

**Evidence:** Early object designs often included `contents` on all furniture. Wayne's directive stopped this pattern.

---

### 5. Trap Door Nests UNDERNEATH the Rug (Principle 0.5)

**Decision:** The trap door is hidden in the rug's `underneath` array with `hidden = true`. Moving the rug reveals it.

**Why it matters:**
- Spatial hiding is gameplay-critical for the trap door puzzle
- If trap door was listed at room level, it would appear in search results before the rug was moved
- Player would spot the trap door immediately and bypass the puzzle entirely
- The nesting structure enforces the puzzle prerequisite: move rug → reveal trap door → open trap door

**What would have gone wrong:**
- Flat object list: trap door appears in room.contents alongside rug (visible to all searches)
- `hidden` flag exists but search doesn't check it (bug in traverse.lua, now fixed)
- Player types "look trap door" before moving rug — works, reveals the solution early
- Puzzle is broken at a fundamental architectural level

**Evidence:** Early trap door implementation was visible at room level. Wayne caught this during design review.

---

### 6. No Hardcoded Directory Lists in Build System (D-8, Build Strategy)

**Decision:** `build-meta.ps1` must auto-discover all files in the meta/ directories instead of maintaining a hardcoded list.

**Why it matters:**
- Hardcoded lists create a class of deployment bugs: add a new room, forget to add it to build script, room ships missing
- Auto-discovery is self-verifying: if it's in meta/, it ships
- Eliminates the human step that fails under pressure or in parallel work
- Makes the build process scalable for future room/object count

**What would have gone wrong:**
- Team adds new bedroom object but forgets to add filename to build-meta.ps1
- Local testing works (object file exists locally)
- Live build omits the object file (hardcoded list is out of date)
- Object appears missing on live server; players report "where's the match?"
- Bug takes 2+ hours to diagnose because it only happens on deployed builds

**Evidence:** Injuries were completely missing from web build. Team tested locally; live server had no injuries. Root cause: injuries weren't in the hardcoded list. Wayne's fix eliminated the entire class of bug.

---

### 7. Parser Hangs Are Architecturally Impossible (D-22, Parser Strategy)

**Decision:** Implement `debug.sethook` with a 2-second deadline + `pcall` wrapper. Make hangs structurally impossible, not just unlikely.

**Why it matters:**
- Depth limits (max_depth = 3) were band-aids; didn't address the real problem
- Real issue was cycles in the data structure (if a container's contents includes itself)
- `debug.sethook` catches infinite loops; `pcall` prevents crashes
- Hangs disappear as a class of bug entirely

**What would have gone wrong:**
- Without safety net: new data author accidentally creates cycle, parser hangs on search
- With depth limits only: system still vulnerable to other loop patterns
- Players see "stuck" state, must hard-refresh, lose progress
- Team spends hours debugging "why does search hang on THIS object?"
- Engine is fragile — it can break silently if data authors make common mistakes

**Evidence:** Early hangs on complex nesting. Depth limits helped but didn't address root cause. Wayne's directive: "Make it architecturally impossible." Implemented safety net + visited sets.

---

### 8. Material-Derived Armor System (Principle 8, D-24)

**Decision:** Armor protection is DERIVED from material properties (density, hardness, fragility), not hardcoded. Material values flow through to damage reduction.

**Why it matters:**
- Eliminates separate armor balance table; armor values emerge from physics
- If you change material properties (wool density), armor protection automatically updates
- Prevents "I forgot to update the armor chart when I changed steel properties" bugs
- Follows Dwarf Fortress architectural model (property-bag simulation, not game balance spreadsheet)

**What would have gone wrong:**
- Separate armor table: leather_protection = 0.8, steel_protection = 1.2, etc.
- Designer updates steel density for gameplay reasons
- Forgets to update steel protection value
- Steel armor becomes too weak or too strong; balance is broken
- Bug is silent (no error message); only discovered during play testing

**Evidence:** Early armor design had hardcoded values. Wayne directed material-derived approach instead.

---

## Course Corrections

### 1. Marge Verification Gate (Process)

**What happened:** Team closed issues without Marge (Test Manager) verification.

**Why it matters:**
- Closed issues might not actually be fixed on live servers (like injuries)
- Separation of concerns: engineers verify locally, test manager verifies on live
- Prevents premature closure that creates "ghost" bugs

**Wayne's correction:** "Engineers don't close issues. Marge verifies and closes. Always."

**Result:** Every issue now requires Marge gate. Bugs don't fall through the cracks.

---

### 2. Injuries Missing from Web Build

**What happened:** Injuries worked in local testing. Live servers had none. Team didn't notice for days.

**Why it matters:**
- This is the "deploy trap": local ≠ live
- Entire mechanic system invisible to players because build process omitted files
- Root cause: hardcoded directory list in build-meta.ps1

**Wayne's correction:** Live play-testing on Brave revealed the bug immediately. Directed fix: auto-discover all meta files.

**Result:** Build system is now self-verifying; entire class of deployment bug eliminated.

---

### 3. Build-Meta Hardcoded List Root Cause

**What happened:** Build script had `@("injuries", "objects", "rooms")` hardcoded. New directories were skipped.

**Why it matters:**
- Team added injuries/ directory but didn't add it to build list
- Worked locally (file exists in dev tree)
- Broken on live (build script didn't copy injuries)

**Wayne's question:** "Why do we have a hardcoded list? Why not copy everything out of meta?"

**Result:** Refactored to auto-discovery. Any file in meta/ ships automatically.

---

### 4. Contradictory Search Narration During Live Testing

**What happened:** Player searches container. Engine says "Inside you find nothing" then lists found items.

**Why it matters:**
- Breaks player immersion and trust in the engine
- Suggests bugs in the search system

**Wayne's correction:** Caught during live play-test on 2026-03-23 afternoon.

**Result:** Search narration logic fixed to be consistent.

---

### 5. "Stab Self" Not Working After Fix

**What happened:** 
- Issue #50: "Stab self not working"
- "Fixed" and marked closed
- Wayne's live testing found it still broken
- Unit tests didn't catch it (they test the wrong code path)

**Why it matters:**
- Bug appeared fixed but only locally
- Deployed code still had the bug
- Suggests fixes aren't being deployed or tests are incomplete

**Wayne's directive:** "Every fix MUST include regression test that prevents this from happening again."

**Result:** Regression test added; issue now properly fixed.

---

### 6. Catch Team Skipping Quality Gates

**What happened:** Team tried to close issues without test verification or regression tests.

**Why it matters:**
- Without gates, broken code ships to players
- Team was prioritizing speed over quality

**Wayne's enforcement:** Established process gates:
1. Fix includes regression test
2. Marge verifies on live
3. Marge closes the issue
4. No shortcuts

**Result:** Every bug fix is now verified and tested.

---

## Quality Gates

### 1. Every Fix MUST Include Regression Test

**Directive:** When you fix a bug, you must also write a test that would have caught it. This test prevents the bug from recurring.

**Why it matters:**
- "Stab self" was marked fixed but tests never ran on the deployed code
- Without regression tests, bugs come back silently in future changes
- Prevents cascading failure: bug gets "fixed", comes back, gets fixed again

**Implementation:**
- Bug fix goes to staging with test
- Test fails (proves it catches the bug)
- Code fix is applied
- Test passes
- Test shipped with production code

---

### 2. Marge Verifies and Closes ALL Issues

**Directive:** Engineers never close issues. Marge (Test Manager) verifies the fix works on live, then closes.

**Why it matters:**
- Engineers test locally; local ≠ live
- Marge tests on live builds (Brave, iPhone, Safari, Chrome)
- Catches deployment-only bugs (like injuries missing)

**Implementation:**
- Engineer: fix code, write test, mark issue "awaiting-verification"
- Marge: test on live servers, test on iOS/Safari/Chrome
- Marge: if OK, close issue; if not, reopen with details
- No issue is closed without Marge's sign-off

---

### 3. All Team Members Check Commits Before Pushing

**Directive:** Before pushing to main, ensure:
1. No debugging code left in
2. Diff is what you intended
3. No uncommitted changes that break the build

**Why it matters:**
- Prevents accidental commits of WIP or debugging code
- Catches "oops, I didn't mean to change that file"

**Implementation:**
- `git diff` before push
- Review the actual changes, not just the intention
- Commit message is clear and references issue

---

### 4. Live Play-Testing Catches What Unit Tests Miss

**Directive:** Wayne personally tests on Brave, Firefox, Safari, and iPhone. This is non-negotiable QA.

**Why it matters:**
- Unit tests cover code paths; play-testing covers player experience
- Unit tests on `cmd_stab` might not test "take sword, stab self" sequence
- Live testing catches: confusing messages, sensory inconsistencies, UX failures, deployment bugs
- "Injuries were missing from live" was caught by Wayne testing on Brave, not by any unit test

**Implementation:**
- After major changes, Wayne plays the game end-to-end
- Documents what feels wrong, what's missing, what contradicts
- Files issues with reproduction steps
- Bugs get fixed with regression tests

---

## Domain Expertise

### 1. Infocom / MUD Heritage (40 Years)

**Knowledge:** Classic text adventure design patterns. Knows how Infocom games (Zork, The Witness, Planetfall) and MUDs (LPC object systems, verb handlers) solved spatial, sensory, and interaction problems.

**Applies to MMO:**
- "Find match" testing sequence comes from decades of IF QA experience
- Knows which edge cases matter (take match from matchbox while matchbox in container, etc.)
- Recognizes that "put X inside Y" is a fundamental verb, not a nice-to-have
- Understands that puzzles must have clear spatial prerequisites (move rug, then trap door appears)

---

### 2. Material System Design (DF-Inspired)

**Knowledge:** Dwarf Fortress uses property-bag simulation: every object has density, hardness, fragility, etc. The simulation engine derives behavior from properties, not from hardcoded rules.

**Applies to MMO:**
- Armor protection should be DERIVED from material properties, not hardcoded
- If steel is "harder" than leather, armor made of steel should be better
- Prevents balance spreadsheets; physics drives gameplay
- Scales to hundreds of materials automatically

---

### 3. Composite Object Design

**Knowledge:** Real-world spatial reasoning. A nightstand has a drawer as a physical SLOT, not "inside" it. A four-poster bed has curtains that hang from posts, not contained in the bed.

**Applies to MMO:**
- Prevents "put pillow inside nightstand" bug
- Makes object relationships explicit and game-enforced
- Room authors can't accidentally violate spatial constraints

---

### 4. Surface Relationships (Four-Tier Taxonomy)

**Knowledge:** Distinguishes four distinct spatial relationships:
- **on_top**: rests on a surface (candle on nightstand)
- **inside**: contained in a cavity (matches in matchbox)
- **nested**: occupies a discrete slot (drawer in nightstand slot)
- **underneath**: hidden beneath (key under rug)

**Why it matters:**
- These are NOT synonymous; each has different visibility/access rules
- Only **inside** means "put X inside Y" works
- Only **underneath** means hidden from search until parent is moved
- **nested** and **on_top** are visible and accessible
- Without this taxonomy, spatial relationships are ambiguous

---

## Design Philosophy

### 1. "Data Pattern, Not Code Pattern"

**Philosophy:** Flavor text, event narration, and output should be designer-authored strings, not callbacks.

**Implication:**
- Object defines: `event_output = "The match flares to life!"` (data)
- NOT: `on_strike = function() return "The match flares to life!" end` (code)
- Data lives in room .lua files; templates stay clean
- Room authors add personality; template authors add behavior

---

### 2. "Nesting IS the Room's Physical Description"

**Philosophy:** The structure of the Lua table IS the room topology. Reading the code shows the room layout.

**Implication:**
- No separate room maps or spatial metadata files
- Room author sees at a glance: what's on the nightstand, what's inside the drawer, what's under the rug
- New team members can understand room topology without external docs
- Spatial mistakes are caught immediately (inconsistencies are obvious in code)

---

### 3. "Objects Without Containers Have NO contents Key"

**Philosophy:** The presence/absence of a key is semantic. If an object has no `contents`, it can't contain things. The engine enforces this automatically.

**Implication:**
- Solid furniture: `contents` is omitted entirely
- Containers: `contents = { ... }`
- "Put X inside Y" looks for `contents` key; if absent, command fails
- No need for flags like `is_container = false`; the data structure speaks

---

### 4. "Build Should Auto-Discover, Never Hardcode"

**Philosophy:** Any list (file list, directory list, object list) that must be maintained by humans is a bug waiting to happen.

**Implication:**
- Build script finds all files automatically
- No "don't forget to register the new room" checkpoints
- Scaling is free: add 100 new objects, they all ship automatically
- Deployment bugs are architecturally impossible

---

### 5. "Live Play-Testing Catches What Unit Tests Miss"

**Philosophy:** Automated tests verify code paths. Manual testing verifies player experience. Both are essential.

**Implication:**
- Unit tests: "Does cmd_take work?"
- Play-testing: "Does it feel right? Do the messages make sense? Is the UX clear?"
- Deployment bugs (missing files, wrong config) only show up in live testing
- Wayne's live tests on Brave/iPhone catch real-world issues

---

### 6. "Code IS State; Mutation IS Lifecycle"

**Philosophy:** Objects don't have separate state flags. The code itself is rewritten when state changes.

**Implication:**
- Lit candle → code is replaced with lit_candle.lua
- Open drawer → code is replaced with drawer_open.lua
- No `state = "lit"` flag; state lives in the code that runs
- Consistency is automatic: if the code says "lit", it runs lit behavior

---

### 7. "Spatial Constraints Are Game-Critical"

**Philosophy:** Whether an object can be put "inside" another is a gameplay rule, not a preference.

**Implication:**
- Solid furniture rejects "inside" verb (no `contents` key)
- Containers accept "inside" verb (has `contents`)
- Players can't bypass spatial rules with clever phrasing
- Puzzles that depend on spatial isolation actually work

---

## Living Updates

This document tracks contributions discovered during development. As new architectural decisions, course corrections, or quality enforcements emerge, they will be added here with dates and context.

**March 2026:**
- ✅ Deep nesting (Principle 0.5) — established for room architecture
- ✅ Composite objects (Principle 4) — nightstand + drawer model
- ✅ Objects are inanimate (Principle 0) — confirmed NPC system is separate
- ✅ Nightstand no contents (Principle 0.5) — solid furniture distinction
- ✅ Trap door underneath rug (Principle 0.5) — spatial hiding for puzzles
- ✅ Auto-discovery build (D-8) — eliminated hardcoded lists
- ✅ Parser safety (D-22) — hangs architecturally impossible
- ✅ Material-derived armor (D-24) — physics-based balance
- ✅ Regression test gate (Quality) — every fix must include test
- ✅ Marge verification (Quality) — test manager closes all issues
- ✅ Live play-testing (Quality) — catches deployment bugs

**Next Review:** 2026-04-06
