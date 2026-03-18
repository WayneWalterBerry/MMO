# Code-Data-Blended Languages for Interactive Fiction: A Research Report

**Researcher:** Frink  
**Date:** 2026-03-19  
**Status:** Complete  
**Audience:** Architecture team, language evaluation  

---

## Executive Summary

Building a text adventure engine where "code and data are blended" means treating the world definition—rooms, objects, NPCs, rules—as live, executable code. The best approaches combine **homoiconicity** (code as data), **domain-specific language design**, and **embedded scripting** to create an environment where game content authors can write behavior and world state in the same expressions.

**Key Finding:** No single perfect candidate exists, but four approaches stand out:
1. **Lua/LuaJIT** — battle-tested in games, excellent embedding, good enough performance (JIT not required for text)
2. **Inform 7** — proven IF DSL, but limited to IF; difficult to extend for custom engines
3. **Lisp dialects** (Fennel, Racket) — maximum homoiconicity and metaprogramming power; steeper learning curve
4. **Custom DSL on GraalVM/Truffle** — highest control, requires significant engineering effort

For a **text adventure**, performance is NOT the bottleneck. Even simple interpreters suffice. The choice should prioritize **ease of content authorship**, **flexibility**, and **embedding simplicity**.

---

## Section 1: Homoiconicity & Code-as-Data

### What Homoiconicity Means

**Homoiconicity** ("same representation") is the property where a language's code and data share identical data structures, enabling programs to manipulate code as if it were data.

In **Lisp**, code is data (nested lists called S-expressions):
```lisp
(+ 2 3)           ; This is both code (an addition) AND data (a list)
(list '+ 2 3)     ; Constructing the same thing as data
(eval '(+ 2 3))   ; Evaluating constructed code
```

This creates powerful metaprogramming: macros transform code before execution, programs generate code, and the boundary between compile-time and runtime blurs.

### Practical Game World Application

In a homoiconic language, world objects and their behaviors can be indistinguishable:

```lisp
; Define a room as data/code:
(define kitchen
  (make-object :name "Kitchen"
               :description "A cozy room."
               :exits {:north dungeon}
               :on-enter (fn [] (say "Welcome!"))))

; Later, modify it like data:
(set! (.on-enter kitchen) (fn [] (say "Hello again!")))
```

The same language handles both **defining game content** (typically thought of as data) and **scripting behavior** (typically code). This unification reduces cognitive friction and enables new forms of game systems (e.g., objects rewriting their own rules at runtime).

### Other Homoiconic Languages

- **Forth:** Stack-based, uses words (code/data interchangeably); famously self-modifying; used in historic games like Starflight.
- **Prolog:** Logic-based; rules and facts are the same representation.
- **Rebol/Red:** High-level, human-readable; homoiconic; designed for scripting.
- **Tcl:** String-based; extremely permissive evaluation.

### Advantages for IF Game Design
- Macros let you define new game constructs (e.g., `define-room`, `on-interact`) as library code, not language features.
- Game content can be generated, mutated, or serialized as simple data structures.
- Reflection and introspection become natural.

### Trade-offs
- Homoiconicity can make code harder to optimize or reason about (tools, IDEs, type checkers struggle).
- Developers unfamiliar with Lisp/Prolog may find it disorienting.
- Flexibility can lead to messy, hard-to-debug code without discipline.

---

## Section 2: Domain-Specific Languages for Interactive Fiction

### What is an IF DSL?

A **domain-specific language** is a language tailored to a narrow problem domain. For IF, a good DSL should express:
- **World Structure:** Rooms, objects, containment, spatial topology.
- **Objects & Properties:** Characteristics, state, relationships.
- **Actions & Reactions:** Verbs, preconditions, postconditions.
- **Dialogue & Narrative:** Text, conditionals, branching.
- **Puzzles & Logic:** Constraints, state machines, conditional outcomes.

### Successful IF DSL Case Studies

#### Inform 7
**Design:** Natural language—source code reads like English.
```inform7
The Kitchen is a room. The fridge is a closed container in the Kitchen.
The player carries a sandwich.
Instead of taking the sandwich, say "You already have it."
```

**Strengths:**
- Extremely accessible to non-programmers and writers.
- Compiles to Z-code (universal IF format).
- Integrated IDE with testing tools (Skein), visualization, and documentation.
- Declarative rule-based system for world logic.

**Weaknesses:**
- **Not embeddable:** Designed as a standalone tool, not a library to embed in other engines.
- **Limited extensibility:** Hard to add custom language features without compiler modifications.
- **Slow development cycle:** Must recompile to test changes; not a live REPL environment.
- **Output format:** Z-code limits portability outside IF interpreters.

**Verdict:** Excellent for classic IF, poor for custom game engines.

#### ZIL (Zork Implementation Language)
**Design:** Lisp-based (MDL dialect), s-expressions; code and data are unified.
```zil
<ROOM LIVING-ROOM
  "Living Room"
  "A comfortably furnished room."
  (IN ROOMS)
  (EXITS N TO KITCHEN) ... >

<ROUTINE TAKE-SWORD-ACTION ()
  <COND (<HELD? ,SWORD> <TELL "You already have it.">)
        (T <TELL "It's too heavy.">) >>
```

**Strengths:**
- Code and data are truly blended (homoiconicity via Lisp).
- Compact, efficient bytecode format (Z-machine).
- Behaviors are attached directly to objects.
- Live redefinition possible during development.

**Weaknesses:**
- Steep learning curve (Lisp-based).
- Limited documentation in the modern era.
- Dead language—no active development or community support.

**Verdict:** Pioneering approach; demonstrated homoiconicity benefits, but infrastructure is dated.

#### TADS (The Adventure Development System)
**Design:** Object-oriented language with classes, properties, and methods.
```tads
book: Thing 'old book' 'book'
  "It's a dusty old book."
  location = library
  dobjFor(Read) {
    action() { "You read: Once upon a time..."; }
  }
;
```

**Strengths:**
- Mature, actively maintained OO language.
- Powerful standard library (adv3).
- Type-safe (in version 3).
- Flexible: supports inheritance, mixins, templates.
- Excellent documentation.

**Weaknesses:**
- Less "blended" than Lisp—code and data are separated by OOP conventions.
- Not embeddable as a library; designed as a standalone development environment.
- Performance adequate but not blazing fast.

**Verdict:** Strong for standalone IF projects; poor for embedding in custom engines.

### DSL Design Patterns for Game Worlds

**1. State-Event Modeling:** Express world elements as state holders + event handlers.
```
room "Dungeon" {
  state: { lit = false, visited = false }
  on-enter: { state.visited = true; }
}
```

**2. Entity-Component Descriptions:** Declaratively list components attached to entities.
```
entity player {
  position: (10, 5)
  inventory: [sword, shield]
  health: 100
}
```

**3. Behavior Trees / Rule Engines:** Define NPC logic via tree structures or production rules.
```
behavior guard {
  if player_nearby: attack()
  else: patrol()
}
```

**4. Relational Definitions:** Express world as relations (triples: subject-predicate-object).
```
sword CONTAINED_IN dungeon
player HAS_SKILL slash
door REQUIRES_KEY key_silver
```

**5. Code Generation & Macros:** Let tools or macros generate efficient code from high-level specs.

---

## Section 3: Embedded Scripting Languages in Games

### Lua: The Dominant Embedded Language

**Why Lua?**

Lua is the default scripting language for games because:

1. **Tiny & Portable:** ~200KB runtime; minimal dependencies; runs on any platform.
2. **Easy C Integration:** Lua C API is clean and low-overhead. Calling C from Lua (or vice versa) is straightforward.
3. **LuaJIT Performance:** Optional JIT compilation provides 5–10x speedup on hot code. Still fast without JIT (interpreted Lua is already efficient).
4. **Prototype-Based Objects:** Tables serve as both arrays and objects; inheritance via delegation (metatables). This makes per-object customization (game world mutations) natural.
5. **Live Reloading:** Lua code can be reloaded at runtime; state can be preserved across reloads.
6. **Industry Track Record:** Used in World of Warcraft (addon scripting), Roblox, LÖVE, Defold, Garry's Mod, and many indie games.

**Embedding Example:**
```c
// C code
lua_State *L = luaL_newstate();
luaL_openlibs(L);
lua_pushcfunction(L, c_move_player);
lua_setglobal(L, "move_player");
luaL_dofile(L, "game_script.lua");
```

```lua
-- Lua script
function describe_room()
  return "A dark hallway."
end
move_player("north")
```

**Data-Code Blending in Lua:**
Tables (Lua's only data structure) can hold both data and functions:
```lua
sword = {
  name = "Iron Sword",
  damage = 10,
  on_attack = function(target)
    print("You slice at " .. target.name)
  end,
  on_examine = function()
    print("A well-crafted sword.")
  end
}
sword.on_attack(goblin)
```

**Limitations:**
- No static type checking; runtime errors only.
- No macros (unlike Lisp).
- No formal DSL—you design conventions in plain Lua.
- Per-object customization can lead to bloated tables if not careful.

---

### Alternatives to Lua

**Wren:** Similar to Lua; designed for game scripting; class-based (not prototype); less mature ecosystem.

**Squirrel:** Similar to Lua; more C++-like syntax; used in some games; smaller community.

**AngelScript:** Full-featured scripting language for games; more complex; heavier runtime.

**MUD Engines: LPC & DGD**

**DGD (Dworkin's Game Driver)** with **LPC** (Lars Pensjö C) is a specialized system for multiplayer text worlds:
- Objects are the fundamental unit; everything (rooms, items, NPCs) is an object.
- Hot-reloadable: code and data can be updated while the world runs.
- Persistence: world state automatically saved/restored.
- Multi-user: built for networked play.
- Code-as-data philosophy: game logic is objects; world state is objects; no separation.

**Verdict:** Overkill for single-player IF but powerful for multiplayer or live-evolving worlds.

---

## Section 4: JIT Compilation for Game Languages

### Do Text Adventures NEED JIT?

**Short answer: No.**

Text adventures are **not** compute-intensive:
- Parsing player input: string matching, lookup.
- Game logic: conditionals, state transitions, arithmetic.
- I/O: printing text.

Even a naive interpreter running simple code is fast enough. Classic interpreters (not JIT) handle modern text adventures without perceptible lag.

**Modern evidence:**
- Twine (browser-based, JavaScript, no JIT): instant response times.
- TexTperience (.NET, minimal JIT): sub-millisecond latency.
- TADS (interpreted VM): responsive gameplay even on old systems.

### Where JIT Helps (But Isn't Necessary)

JIT shines when:
- Complex algorithms run repeatedly (e.g., pathfinding, simulation of many NPCs).
- Tight loops execute many times per turn.
- Cross-platform consistency is less critical than peak performance.

**LuaJIT specifics:**
- Traces "hot" code paths (loops, frequently called functions).
- Compiles traces to native machine code; guard checks ensure correctness.
- Memory footprint: ~100–200 KB base, plus trace cache (configurable).
- Performance: often 5–10x faster than interpreted Lua on compute-heavy tasks; marginal gain on simple scripts.

### GraalVM & Truffle: Building Custom Languages with JIT

**GraalVM** is a polyglot VM that can:
- Run multiple languages (Java, JavaScript, Python, Ruby, R, and custom languages).
- JIT-compile any language built on its **Truffle** framework.
- Enable seamless interop between languages.

**Use Case:** If you design a custom IF DSL using Truffle, you get automatic JIT and cross-language interop.

**Trade-off:** Requires significant engineering effort (200–500 LOC minimum for a minimal language).

**Verdict:** Overkill for pure text adventure IF; valuable if you want to integrate with existing JVM ecosystems or enable polyglot interop.

---

## Section 5: The "World Definition IS the Program" Pattern

### Concept

Blur the distinction between game content (rooms, items, dialogue) and game logic (behavior, rules, conditionals). The game world is defined by executing code; the code IS the world.

### Examples

**Lisp-based approach:**
```lisp
(define-world
  (dungeon
    (contains
      (room :name "Chamber" :description "Dark stone walls.")
      (item :name "sword" :on-take (lambda () (say "You take the sword.")))
      (npc :name "guard" :dialog "Who goes there?"))))
```
Executing this code **creates** the world.

**Lua-based approach:**
```lua
world = {
  rooms = {
    chamber = {
      name = "Chamber",
      description = "Dark stone walls.",
      exits = { north = "hallway" }
    },
    hallway = { ... }
  },
  items = {
    sword = {
      name = "Sword",
      on_take = function() print("Taken.") end
    }
  }
}
```
The table structure IS the world; interpreting it creates the game.

### Object Mutation & Self-Modification

With prototype-based or homoiconic languages, objects can alter themselves:
```lisp
(define-item cursed-ring
  :on-equip (lambda (player)
    (set! (.curse player) true)
    (set! (.curse-level player) (+ (.curse-level player) 1))))
```
An item can modify the player when used; the player can then modify itself.

### Advantages
- **Unified Mental Model:** Designers think of the world as executable code.
- **Runtime Generation:** Worlds can be generated, mutated, or evolved dynamically.
- **Narrative Emergence:** Objects can spawn other objects, creating chains of events.
- **Live Development:** Reloading code updates the world in real-time.

### Disadvantages
- **Debugging Complexity:** If logic and world definition are merged, bugs are harder to isolate.
- **Performance Trade-offs:** Dynamic structures may be slower than static data.
- **Scalability:** Very large worlds may become unwieldy if purely procedurally defined.

---

## Section 6: Object System Comparison

### Prototype-Based vs Class-Based

#### Prototype-Based (JavaScript, Lua, Self)
- **Model:** Objects clone other objects (prototypes); inheritance via delegation.
- **Mutation:** Individual objects can gain/lose properties and methods at runtime.
- **Flexibility:** Excellent for self-modifying worlds where each entity is unique.
- **Performance:** Can be slower if many objects diverge significantly; modern engines mitigate this.
- **Example:** `sword.on_attack = function() ... end` attaches behavior to one sword instance.

#### Class-Based (Java, Python, C++, TADS)
- **Model:** Classes define templates; objects are instances; inheritance via subclassing.
- **Mutation:** Changes typically apply to all instances of a class or require explicit design patterns.
- **Structure:** More organized; suited to systems with consistent entity archetypes.
- **Performance:** Generally more efficient; shared methods and optimized layouts.
- **Example:** Define `class Sword`, then all Sword instances inherit behavior.

### For Interactive Fiction: Verdict

**Prototype-based is better** if:
- Entities frequently gain unique properties (cursed items, corrupted NPCs, infected areas).
- Designers want per-entity customization without class hierarchies.
- The world evolves and mutates organically.

**Class-based is better** if:
- Most entities follow consistent archetypes (rooms are rooms, NPCs are NPCs).
- Type safety and optimization are high priorities.
- The codebase grows very large.

**Hybrid approach (used by many modern game engines):** Class-based structure with composition and runtime property binding—best of both.

---

## Section 7: Best Language Candidates Ranked

### Ranking Criteria
1. **Homoiconicity / Code-as-Data:** Does it blur code and data?
2. **Embeddability:** Can it be embedded in a custom engine?
3. **DSL Capability:** Can you easily define new language constructs?
4. **Performance:** Sufficient for text adventure workloads?
5. **Learning Curve:** How steep for game designers?
6. **Community & Tools:** Documentation, libraries, IDE support?
7. **JIT Support:** Optional but nice-to-have.

---

### A. Lua/LuaJIT ⭐⭐⭐⭐⭐

**Homoiconicity:** 4/5 — Tables blur data/code; no macros but flexible.  
**Embeddability:** 5/5 — Easy C API; designed for embedding.  
**DSL Capability:** 3/5 — Can define conventions; no built-in macro system.  
**Performance:** 5/5 — Fast interpreted; LuaJIT optional for more.  
**Learning Curve:** 2/5 — Very gentle; dynamic, intuitive syntax.  
**Community & Tools:** 4/5 — Strong game industry adoption; good docs.  
**JIT Support:** 5/5 — LuaJIT available; not needed but nice.  

**Recommendation:** **Choose Lua if** you want a proven, lightweight, industry-standard embedded scripting language. Excellent for rapid prototyping and live development. Tables provide a natural data structure for world definitions.

**Example World Definition:**
```lua
game = {
  rooms = {
    dungeon = {
      description = "A dark dungeon.",
      exits = { north = "hallway" },
      on_enter = function()
        print("You feel a chill.")
      end
    }
  }
}
```

**Embedding in C:**
```c
lua_State *L = luaL_newstate();
luaL_dofile(L, "world.lua");
// Call game logic easily from C
```

---

### B. Inform 7 ⭐⭐⭐⭐

**Homoiconicity:** 1/5 — Natural language; not homoiconic.  
**Embeddability:** 1/5 — Not designed to be embedded; standalone tool.  
**DSL Capability:** 5/5 — Excellent; declarative rules system.  
**Performance:** 4/5 — Compiles to efficient Z-code.  
**Learning Curve:** 1/5 — Natural language; accessible to writers.  
**Community & Tools:** 5/5 — Active community; mature IDE; excellent docs.  
**JIT Support:** 0/5 — No JIT; not applicable.  

**Recommendation:** **Choose Inform 7 if** you're building a classic parser-based IF game and want maximum accessibility for writers. Don't choose it if you need to embed it in a custom engine or extend the language significantly.

**Strengths for Content Authors:**
```inform7
The Kitchen is a room with description "A bright, clean room."
A cake is a edible thing in the Kitchen.
After taking the cake, say "Delicious crumbs fall on the floor."
```

---

### C. TADS (The Adventure Development System) ⭐⭐⭐⭐

**Homoiconicity:** 2/5 — OOP; some metaprogramming; not truly homoiconic.  
**Embeddability:** 1/5 — Designed as a standalone development environment.  
**DSL Capability:** 4/5 — Classes, templates, and inheritance; good for defining new abstractions.  
**Performance:** 4/5 — Compiled to efficient bytecode.  
**Learning Curve:** 3/5 — OOP style; moderate for programmers familiar with C/Java.  
**Community & Tools:** 4/5 — Active community; good docs; mature standard library (adv3).  
**JIT Support:** 0/5 — No JIT.  

**Recommendation:** **Choose TADS if** you're building a traditional IF game with complex object hierarchies and want strong type safety and a mature standard library. Similar caveats to Inform 7 regarding embeddability.

---

### D. Lisp Dialects (Fennel, Racket, Clojure, Janet) ⭐⭐⭐⭐

**Homoiconicity:** 5/5 — Pure; code and data are identical S-expressions.  
**Embeddability:** Fennel: 5/5 (compiles to Lua); Racket: 3/5; Clojure: 3/5 (JVM); Janet: 5/5.  
**DSL Capability:** 5/5 — Macros enable arbitrary language extension.  
**Performance:** Fennel: 4/5 (via Lua); Janet: 4/5; Racket/Clojure: 3/5 (VM overhead).  
**Learning Curve:** 4/5 — Lisp syntax is minimal but unfamiliar to many.  
**Community & Tools:** Fennel: 3/5; Racket: 4/5; Clojure: 4/5; Janet: 2/5.  
**JIT Support:** Clojure: 4/5 (via JVM JIT); others: 2–3/5.  

#### Fennel (⭐⭐⭐⭐⭐ for game development)
- Compiles to Lua; runs on any Lua platform (LÖVE, TIC-80, Neovim).
- Small, fast; perfect for game scripting.
- Macros enable DSL creation.
- **Recommendation:** **Choose Fennel if** you want Lisp power with Lua's simplicity and portability. Ideal for games targeting Lua-based engines.

#### Racket
- General-purpose language creation toolkit; powerful metaprogramming.
- Good for research and DSL design.
- Heavier runtime than Fennel or Janet.
- **Recommendation:** **Choose Racket if** you want to design and implement a custom IF language as a Racket macro system.

#### Clojure
- Runs on JVM; access to Java ecosystem.
- Strong immutability; good for data processing.
- Heavier runtime; slower startup.
- **Recommendation:** **Choose Clojure if** you want to integrate with JVM infrastructure and benefit from strong concurrency primitives (for multi-threaded game servers).

#### Janet
- Custom bytecode VM; small, embeddable (~400 KB).
- Fast startup; good for scripting.
- Smaller community than Racket or Clojure.
- **Recommendation:** **Choose Janet if** you want a Lisp-like language that's even lighter than Fennel and designed for embedding.

**Example World in Fennel:**
```fennel
(local game
  {:rooms
   {:dungeon {:name "Dungeon"
              :description "A dark chamber."
              :exits {:north :hallway}}}})
```

---

### E. Forth (Stack-Based) ⭐⭐

**Homoiconicity:** 5/5 — Pure; code and data are interchangeable words.  
**Embeddability:** 3/5 — Can be embedded; smaller ecosystems.  
**DSL Capability:** 5/5 — Define new words (functions) freely; self-modifying.  
**Performance:** 5/5 — Extremely fast; minimal overhead.  
**Learning Curve:** 5/5 — Very steep; stack-based semantics are unfamiliar.  
**Community & Tools:** 2/5 — Niche community; limited modern tooling.  
**JIT Support:** 0/5 — Not applicable; already very fast.  

**Recommendation:** **Choose Forth only if** you're targeting extremely constrained systems (8-bit microcontrollers, ROM-based games) and have a team proficient in stack-based languages. Otherwise, prefer Lua or Fennel.

**Example (Forth):**
```forth
: room ( name -- )
  CREATE , DOES> @ ;

: dungeon room ;
```

---

### F. Python ⭐⭐

**Homoiconicity:** 2/5 — Can do metaprogramming; not designed for it.  
**Embeddability:** 4/5 — Easy C API; can embed in C/C++ applications.  
**DSL Capability:** 3/5 — Decorators and metaclasses enable some DSL patterns.  
**Performance:** 2/5 — Slow; requires PyPy JIT or C extensions for speed.  
**Learning Curve:** 1/5 — Very gentle; intuitive.  
**Community & Tools:** 5/5 — Largest community; tons of libraries.  
**JIT Support:** 3/5 — PyPy JIT available; slower than LuaJIT.  

**Recommendation:** **Choose Python if** your team is already Python-heavy and you accept slower performance. Good for prototyping; not ideal for production text adventures due to startup time and memory overhead.

---

### G. JavaScript/TypeScript ⭐⭐⭐

**Homoiconicity:** 3/5 — Some metaprogramming (eval, Proxy); not core.  
**Embeddability:** 4/5 — V8 embedding possible; Node.js libraries.  
**DSL Capability:** 3/5 — Decorators, proxy objects, template literals enable patterns.  
**Performance:** 4/5 — V8 JIT is excellent; can be JIT-less if needed.  
**Learning Curve:** 2/5 — Familiar to web developers; quirky semantics.  
**Community & Tools:** 5/5 — Massive ecosystem; TypeScript for type safety.  
**JIT Support:** 5/5 — V8 JIT by default; can disable for security.  

**Recommendation:** **Choose JavaScript if** you're targeting web browsers (Twine-style) or have Node.js infrastructure. TypeScript adds type safety. Overkill for pure text adventures; excellent for web-based IF.

**Example World (JavaScript):**
```javascript
const dungeon = {
  name: "Dungeon",
  description: "Dark stone walls.",
  onEnter: () => console.log("You feel cold."),
  exits: { north: "hallway" }
};
```

---

### H. GraalVM / Custom DSL on Truffle ⭐⭐⭐

**Homoiconicity:** 5/5 (if DSL designed with it; custom) — Whatever you design.  
**Embeddability:** 4/5 — Designed for JVM embedding; works well.  
**DSL Capability:** 5/5 — Full control; build any language.  
**Performance:** 5/5 — Automatic JIT via Graal; excellent.  
**Learning Curve:** 5/5 — Very steep; requires compiler/interpreter knowledge.  
**Community & Tools:** 3/5 — Smaller niche; good Oracle documentation.  
**JIT Support:** 5/5 — Automatic via Graal.  

**Recommendation:** **Choose GraalVM if** you want to design a custom IF DSL and need:
- Automatic JIT compilation.
- Polyglot interop with other languages.
- Deep control over language semantics.
- Are willing to invest significant engineering effort (weeks).

**Trade-off:** 200–500 lines of Java to define a minimal language; payoff is excellent tooling and optimization.

---

## Section 8: Recommendation Summary

### Quick Decision Tree

```
Do you want to embed the scripting language in a custom engine?
  ├─ YES
  │   ├─ Want maximum code-as-data / homoiconicity?
  │   │   ├─ YES → Fennel (Lisp via Lua) or Lua directly
  │   │   └─ NO  → Lua (proven, simple)
  │   └─ Need polyglot JVM interop?
  │       ├─ YES → Clojure or GraalVM/Truffle custom DSL
  │       └─ NO  → Lua or Fennel
  └─ NO (want standalone IF tool)
      ├─ Want maximum accessibility for writers?
      │   └─ YES → Inform 7
      └─ Want full control and OOP?
          └─ YES → TADS
```

### Final Recommendation for Your Project

**For a blended code-data text adventure engine, I recommend:**

**Tier 1 (Best choice):** **Lua (or Fennel if you prefer Lisp)**
- Lua: Proven, simple, embeddable; tables naturally blur code/data via metatables and functions-as-values.
- Fennel: Lisp power with Lua's runtime; macros enable DSL design without language modification.
- **Why:** You get maximum control, minimal learning curve for your team, fast iteration, and proven track record in games.

**Tier 2 (Alternative):** **Clojure + custom embedding**
- If your team is already on the JVM and wants strong homoiconicity and metaprogramming.
- Slower startup but excellent for servers and complex worlds.

**Tier 3 (If you have deep expertise):** **GraalVM/Truffle custom DSL**
- Only if you want to design a specialized IF language from scratch and have compiler/interpreter expertise.
- Overkill for most text adventures; powerful if you need it.

**Avoid:**
- **Inform 7**: Not embeddable; standalone tool.
- **Python**: Too slow; startup overhead.
- **Forth**: Too steep a learning curve; niche.

---

## Section 9: Technical Deep-Dive: Implementing Code-Data Blending in Lua

### Tables as World Definition

Lua tables are the perfect data structure for blending code and data:

```lua
-- Define a room as a table (data)
local kitchen = {
  name = "Kitchen",
  description = "A cozy room with a fridge.",
  
  -- Include code (functions) as values
  on_enter = function()
    print("A warm aroma fills your nostrils.")
  end,
  
  -- Contain objects
  contents = {
    fridge = {
      name = "Fridge",
      locked = true,
      on_open = function()
        print("You open the fridge. Inside: milk, eggs.")
      end
    }
  },
  
  -- Define exits (links to other rooms)
  exits = {
    north = hallway_room,
    east = garage_room
  }
}

-- Execute code to trigger behavior
kitchen.on_enter()

-- Mutate at runtime
kitchen.on_enter = function()
  print("The fridge hums ominously...")
end
```

### Metatables for Inheritance & Shared Behavior

Lua metatables allow prototype-based inheritance:

```lua
-- Define a base "object" prototype
local object_mt = {
  __index = function(self, key)
    if key == "examine" then
      return function() print("You examine: " .. self.name) end
    end
  end
}

-- Create instances by cloning and setting metatables
local function make_object(name)
  local obj = { name = name }
  setmetatable(obj, object_mt)
  return obj
end

-- Now all objects share the examine behavior
local sword = make_object("sword")
sword.examine() -- prints: "You examine: sword"
```

### DSL via Syntactic Sugar

Define higher-level constructs as Lua functions:

```lua
local Room = {}

function Room.define(spec)
  return {
    name = spec.name,
    description = spec.description,
    on_enter = spec.on_enter or function() end,
    exits = spec.exits or {}
  }
end

-- Use it:
local dungeon = Room.define {
  name = "Dungeon",
  description = "Dark and cold.",
  on_enter = function() print("Chill...") end,
  exits = { north = kitchen }
}
```

### Live Reloading

Lua allows redefining functions at runtime:

```lua
-- Initial behavior
function handle_command(cmd)
  if cmd == "go north" then
    move_to_room(dungeon)
  end
end

-- Later, redefine without restarting
function handle_command(cmd)
  if cmd == "go north" then
    if player.has_key then
      move_to_room(dungeon)
    else
      print("Locked.")
    end
  end
end
```

---

## Section 10: Glossary of Technical Terms

### A
- **Abstract Syntax Tree (AST):** Tree representation of program structure; each node represents a syntactic construct (e.g., expression, statement).
- **AOT (Ahead-of-Time) Compilation:** Compiling code to machine code before execution (vs. JIT, which compiles during execution).
- **API (Application Programming Interface):** Set of functions/objects exposed by a library for external code to use.
- **Applicative Programming:** Style emphasizing function application and immutability (vs. imperative loops).

### B
- **Backward Chaining:** Inference strategy starting from a goal and working backward to find facts that satisfy it (used in Prolog).
- **Bytecode:** Intermediate representation between source code and machine code; platform-independent; interpreted or JIT-compiled.
- **Behavior Tree:** Hierarchical tree-based formalism for encoding behavior (used in game AI).

### C
- **Church Encoding:** Technique to represent data structures (e.g., booleans, numbers) as pure lambda functions.
- **Closure:** Function bundled with the environment (variables) it captures at creation time.
- **Continuation:** Function representing the "rest of the computation" after a point; enables advanced control flow.
- **Control Flow:** Order in which program statements execute; affected by conditionals, loops, function calls.

### D
- **DSL (Domain-Specific Language):** Programming language tailored to a narrow problem domain (e.g., SQL for databases, shader languages for graphics).
- **Dynamic Typing:** Type checking performed at runtime (vs. static typing at compile-time).
- **Declarative Programming:** Style where you specify *what* should happen, not *how* (vs. imperative).

### E
- **EDSL (Embedded DSL):** DSL built as an extension within a general-purpose language (vs. external DSL with separate parser).
- **Eval:** Function that parses and executes a string as code at runtime.
- **Event Sourcing:** Architecture where all state changes are recorded as immutable events; state rebuilt by replaying events.

### F
- **FFI (Foreign Function Interface):** Mechanism allowing a language to call functions in other languages (typically C).
- **First-Class Function:** Functions treated as values (can be passed as arguments, returned, stored in variables).
- **Forward Chaining:** Inference strategy starting from known facts and applying rules to derive new facts.
- **Fungible:** Interchangeable; in game design, fungible items have no unique identity (vs. non-fungible unique items).

### G
- **Garbage Collection (GC):** Automatic memory management; runtime reclaims unused memory.
- **Guard (in JIT):** Runtime check ensuring a trace's assumptions hold; if not, code exits to interpreter.
- **GraalVM:** Polyglot VM supporting multiple languages with shared JIT compilation.

### H
- **Homoiconicity:** Property where a language's code and data share the same representation (code is data).
- **Hot Code / Hot Path:** Frequently executed code section; JIT prioritizes compilation of hot paths.
- **Horn Clause:** Logical formula of the form "conclusion :- condition1, condition2, ..."; used in Prolog.

### I
- **Immutability:** Property of data that cannot be modified after creation; enables safe concurrency and easier reasoning.
- **Inference Engine:** Component of a rule-based system that applies rules to derive new facts.
- **Interpreter:** Runtime system that directly executes code (often from bytecode) without prior compilation to machine code.
- **Introspection:** Ability of a program to inspect its own structure and behavior at runtime.

### J
- **JIT (Just-In-Time) Compilation:** Compilation strategy where code is compiled to machine code during execution (at the "just in time" it's needed).
- **John (MUD engine):** Legacy LPC MUD driver; predecessor to DGD.

### K
- **Kind (in Inform 7):** Object type or class in Inform 7 (e.g., "A shirt is a kind of clothing.").

### L
- **Lambda (λ):** Anonymous function; used in lambda calculus and functional programming.
- **Lazy Evaluation:** Delaying computation until its result is actually needed.
- **LPC (Lars Pensjö C):** Object-oriented scripting language designed for MUD engines (DGD).
- **Lexical Scope / Lexical Binding:** Variable scope determined by program text structure (vs. dynamic scope).

### M
- **Macro:** Program construct that generates code; often used to extend language syntax.
- **Memoization:** Optimization technique caching function results to avoid recomputation.
- **Metaclass:** Class whose instances are classes (enables metaprogramming).
- **Metaprogramming:** Code that manipulates, generates, or inspects other code.
- **Monad:** In functional programming, abstraction for composing operations with side effects.
- **Monomorphization:** Process of specializing generic code for specific types at compile-time.
- **MUD (Multi-User Dungeon):** Multiplayer text-based game environment; precursor to MMORPGs.

### N
- **Namespace:** Named scope limiting identifier visibility (avoids naming conflicts).
- **NPC (Non-Player Character):** Game character controlled by AI, not by player.

### O
- **Optimization Pass:** Phase in compiler/JIT that improves code efficiency (e.g., dead code elimination, inlining).
- **Opcode:** Individual operation in bytecode (e.g., ADD, LOAD_VAR).
- **Operator Overloading:** Allowing standard operators (+, -, etc.) to work with custom types.

### P
- **Parser:** Component that converts source code text into an AST.
- **PEG (Parsing Expression Grammar):** Grammar formalism for parsing; alternative to context-free grammars.
- **Persistent Data Structure:** Data structure where old versions are preserved after modifications (enables efficient undo/versioning).
- **Production Rule:** Rule in a production system (forward-chaining system); IF-THEN form.
- **Prototype (in prototype-based OOP):** Object serving as a template for other objects; inheritance via delegation.
- **Prolog:** Logic programming language using backward-chaining inference and Horn clauses.

### Q
- **Query:** Question or goal posed to a logic system (e.g., Prolog "?- father(john, X).");

### R
- **REPL (Read-Eval-Print Loop):** Interactive environment where you type expressions, they're evaluated, and results printed.
- **RDF (Resource Description Framework):** Format for representing semantic relationships as triples (subject-predicate-object).
- **Reflection:** Ability to inspect and modify program structure at runtime.
- **Rule Engine:** System executing production rules; used in forward-chaining inference.
- **Runtime Dispatch:** Choosing which function to call based on runtime type information (vs. compile-time dispatch).

### S
- **S-Expression (Symbolic Expression):** In Lisp, nested lists representing code/data; e.g., (+ 2 3).
- **Semantic Web:** Initiative to make web data machine-readable; uses RDF, OWL, etc.
- **Specialization:** Optimization technique creating specialized versions of code for specific types/values.
- **Stack-Based Language:** Language (like Forth) where computation revolves around a data stack.
- **Strict Evaluation:** Eagerly evaluating function arguments before calling function (vs. lazy evaluation).
- **Syntax Macros / Syntax Quotation:** Lisp mechanism (backtick, comma) for generating code structures.
- **Symbolic Execution:** Program analysis technique executing with symbolic values to reason about behavior.

### T
- **TADS:** Mature OOP language and system for interactive fiction.
- **Tail Call:** Function call as the last operation; can be optimized into a jump (tail call optimization).
- **Tokenizer / Lexer:** Component splitting source code into tokens (atomic units like keywords, identifiers).
- **Trace (in JIT):** Linear sequence of operations extracted from code path; candidates for compilation.
- **Tracing JIT:** JIT strategy recording traces of hot code paths and compiling them (used by LuaJIT).
- **Truffle:** Framework for building language interpreters that integrate with GraalVM JIT.

### U
- **Unification:** In logic programming, process of finding substitutions making logical terms identical.
- **Unification Algorithm:** Algorithm determining if two terms can be unified and computing the substitution.

### V
- **Virtual Machine (VM):** Abstract computer; executes bytecode or other intermediate representations.
- **Visitor Pattern:** Design pattern for operations on object tree; decouples operations from structure.

### W
- **World Model:** In game design, the representation and simulation of the game world (rooms, objects, state, rules).
- **Wrapper:** Function or object encapsulating another; often used to add functionality or modify behavior.

### Z
- **Z-code / Z-machine:** Virtual machine and bytecode format for interactive fiction (used by Infocom games, Inform).
- **ZIL (Zork Implementation Language):** Lisp-based language used to develop Zork; demonstrates homoiconicity in IF.

---

## Conclusion

A blended code-data language for text adventures should prioritize:

1. **Accessibility:** Game designers should be able to define worlds and behaviors with minimal boilerplate.
2. **Flexibility:** Objects should be customizable per-instance, not rigidly class-based.
3. **Embeddability:** The language should integrate cleanly into a custom game engine.
4. **Homoiconicity (optional but powerful):** Code and data structures should be unified, enabling metaprogramming and world mutation.

**My recommendation:** **Lua** for simplicity and proven effectiveness, or **Fennel** (Lisp via Lua) if you want maximum code-as-data expressiveness. Both embed trivially, scale well, and enable live development.

---

## References & Sources

- **Homoiconicity & Lisp:** Wikipedia, Urbit blog, Aditya Anand's research
- **Inform 7:** Official docs, Brass Lantern, Digital Humanities Berkeley
- **ZIL:** Microsoft open-source release, historical sources, DeepWiki
- **TADS:** TADS 3 Tour Guide, TADS Bookshelf, community forums
- **Lua & LuaJIT:** Official docs, game engine documentation (LÖVE, Defold), StackOverflow, Tarantool
- **LPC & DGD:** Phantasmal MUDlib, Genesis MUD, Awesome-MUDs
- **Forth:** DeepWiki, ratfactor.com, ForthScript
- **GraalVM/Truffle:** Oracle official docs, DeepWiki, JavaCodeGeeks
- **Rule-Based Systems:** MIT, University of Texas, Brandeis University, GeeksforGeeks
- **Prototype vs Class-Based:** laputan.org, raganwald, StackOverflow
- **Lisp Dialects:** Clojure.org, Racket docs, Fennel docs, Janet docs, Lisp family tree resources
- **DSL Design:** Martin Fowler's DSL guide, JetBrains MPS, peerdh.com, ScienceDirect
- **Performance Benchmarks:** Programming Language Benchmarks site, LuaJIT docs, Luau docs

---

**Report compiled by:** Frink, Researcher  
**Date:** 2026-03-19  
**Version:** 1.0 (Complete)
