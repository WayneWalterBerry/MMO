# Self-Modifying Languages and Runtime-Mutable Code Systems for Text Adventure MMO

**Research conducted by:** Frink, Researcher  
**Date:** Current session  
**Context:** Exploring architectural foundations for a self-modifying MMO engine where player actions literally modify the source code that defines the game world.

---

## Executive Summary

This research examines the feasibility and best practices for building a game world where **code IS the world state**, enabling players to reshape their universe through gameplay. The core architectural pattern combines:

1. **Homoiconic languages** (code-as-data) for flexible runtime mutation
2. **Event sourcing** for deterministic state reconstruction and undo
3. **Sandboxed execution** to prevent malicious or corrupting modifications
4. **Live code reloading** to preserve game state during world updates

**Recommended stack:** Lua/Fennel with capability-based sandboxing, backed by event sourcing and Git-style version control for world state.

---

## 1. Homoiconic Languages & Code-as-Data Self-Modification

### 1.1 What is Homoiconicity?

**Homoiconicity** (from Greek "homo-" same + "icon" symbol) means a language's **code and data have the same representation**. Programs can treat themselves as data, enabling compile-time code generation and runtime self-modification.

**Classic example — Lisp:**
```lisp
; Code and data are indistinguishable
(+ 1 2)        ; Could be code OR data depending on context

; Quasiquoting enables runtime code generation
`(defun factorial [n]
   (if (<= n 1) 1 (* n (factorial (- n 1)))))
; This is data that can be modified, then eval'd as code
```

### 1.2 Lisp/Scheme: The Original Self-Modifying Language

**Core mechanisms:**

1. **`eval()`** — Execute arbitrary S-expressions at runtime
   ```scheme
   (define x 5)
   (eval '(+ x 3))  ; ⇒ 8
   
   ; Player action: "add the number 7 to x"
   (eval (list '+ (list 'quote 'x) 7))  ; ⇒ 12
   ```

2. **Macros** — Code that generates code at compile time
   ```scheme
   (define-syntax when
     (syntax-rules ()
       ((when condition body ...)
        (if condition (begin body ...)))))
   ; Macros are compile-time metaprogramming
   ```

3. **Quasiquoting** — Template-based code generation
   ```scheme
   (define (make-adder n)
     `(lambda (x) (+ x ,n)))
   
   ; Creates new functions at runtime
   (eval (make-adder 10))  ; ⇒ function that adds 10
   ```

4. **`car`/`cdr` + `cons`** — Direct list manipulation (AST manipulation)
   ```scheme
   (define expr '(* 2 (+ 3 4)))
   (cadr expr)         ; ⇒ 2
   (caddr expr)        ; ⇒ (+ 3 4)
   (cons '/ expr)      ; ⇒ (/ 2 (+ 3 4))  ; Rewrite operation!
   ```

**Application to self-modifying MMO:**
```scheme
; World representation as S-expressions
(define *room-library*
  '((room-tavern
      (name "The Tavern")
      (description "A warm, smoky tavern...")
      (items
        ((item-sword (name "Iron Sword") (damage 5))))
      (exits ((north . room-street))))))

; Player action: "take sword"
; Modify world by removing sword from room
(define (player-take-item room item-id)
  `(,@(take-until (lambda (x) (eq? (car x) 'items)) room)
    (items ,@(filter (lambda (i) (not (eq? (cadr (car i)) item-id)))
                     (cdr (assoc 'items room))))
    ,@(drop-until (lambda (x) (eq? (car x) 'items)) room)))
```

**Pros:**
- ✅ Natural code generation (entire ecosystem built on it)
- ✅ Powerful metaprogramming (macros at compile time)
- ✅ S-expressions are trivial to parse/modify
- ✅ Academic foundation (40+ years of lambda calculus theory)

**Cons:**
- ❌ Unfamiliar syntax to many developers
- ❌ Runtime `eval()` is slow (no JIT compilation)
- ❌ Few Lisp implementations with live code reloading
- ❌ Sandboxing Lisp eval is notoriously difficult

### 1.3 Clojure & Functional Approach

**Clojure** (Lisp on Java VM) adds:

1. **Immutable data structures** — Persistent collections prevent accidental state corruption
2. **Rich literal syntax** — Maps, vectors, sets alongside lists
3. **REPL-driven development** — Hot reloading of functions

```clojure
; Immutable world state
(def *room*
  {:name "Tavern"
   :items #{:sword :goblet :torch}
   :exits {:north :street}})

; Pure function for item removal (returns new state, doesn't mutate)
(defn remove-item [room item-id]
  (update room :items disj item-id))

; Result: new map with item removed, original untouched
(remove-item *room* :sword)
; ⇒ {:name "Tavern", :items #{:goblet :torch}, :exits {:north :street}}
```

**Advantage:** Functional approach makes concurrent modification safer (immutable = no race conditions)

**Disadvantage:** Requires players to understand immutability; harder to "just modify things"

### 1.4 Meta-Object Protocols (MOPs) in Smalltalk/CLOS

**Meta-Object Protocol** = the rules for how objects work, made modifiable by user code.

**Smalltalk's MOP:**
```smalltalk
"Everything in Smalltalk is an object, including class definitions"

| myClass |
myClass := Object subclass: #MyRoom
  instanceVariableNames: 'name items exits'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Adventure'.

"Modify class at runtime: add a method"
myClass compile: 'take: itemName
  items remove: itemName.
  ^player inventory add: itemName'.

"Player action modifies the class definition itself!"
```

**CLOS (Common Lisp Object System):**
```lisp
; Define a room class
(defclass room ()
  ((name :accessor room-name)
   (items :accessor room-items)))

; Player action: redefine slot access
(add-method (slot-value-using-class (find-class 'room) 
                                    instance
                                    (find-slot (find-class 'room) 'name))
  (lambda () (format t "~a (cursed)~%" (call-next-method))))
; Now accessing room name always says "(cursed)"
```

**Key insight:** MOPs enable **metaprogramming at runtime** — change not just data, but the rules for how objects behave.

**Application:** Players could redefine what "take" means, how NPCs pathfind, etc.

---

## 2. Reflective Programming & Runtime Code Inspection

**Reflective programming** = code that inspects and modifies other code (or itself) at runtime.

### 2.1 Introspection vs. Reflection

| Term | Meaning | Example |
|------|---------|---------|
| **Introspection** | Inspect code structure (read-only) | "What methods does this object have?" |
| **Reflection** | Inspect AND modify code structure | "Add a method to this object at runtime" |
| **Reification** | Make implicit concepts explicit as objects | "Turn the call stack into an object I can inspect" |

### 2.2 Practical Reflective Capabilities

**Python (for reference):**
```python
class NPC:
    def __init__(self, name):
        self.name = name
    
    def greet(self):
        print(f"Hello, I'm {self.name}")

npc = NPC("Bob")

# Introspection
print(dir(npc))  # List all attributes
print(hasattr(npc, 'greet'))  # Check if method exists

# Reflection - add method at runtime
def new_greet(self):
    print(f"Hi! I'm {self.name}, your guide.")

NPC.greet = new_greet
npc.greet()  # Output: "Hi! I'm Bob, your guide."

# Reification - inspect call stack
import inspect
frame = inspect.currentframe()
print(inspect.getframeinfo(frame))
```

**Application to MMO:**
- Player discovers NPC's methods: `inspect(goblin)` → `["patrol", "attack", "speak"]`
- Player patches NPC: `add_method(goblin, "speak", new_function)`
- Next time NPC acts, uses modified code

---

## 3. Forth & Stack-Based Self-Modification

**Forth** is a unique language where the dictionary (the runtime symbol table) is directly accessible and modifiable.

### 3.1 Forth's Dictionary Model

Every Forth word (function) is stored in the **dictionary**:

```forth
: SQUARE   ( n -- n² )
  DUP * ;

: CUBE     ( n -- n³ )
  SQUARE DUP * ;

5 SQUARE   ( Stack: 25 )
5 CUBE     ( Stack: 125 )
```

**The key: You can redefine words at runtime:**

```forth
: OLD-GREET ." Hello" CR ;
: GREET    ." Hi there" CR ;

GREET           ( Output: "Hi there" )

: GREET ." Howdy partner!" CR ;   ( Redefine GREET )

GREET           ( Output: "Howdy partner!" )
```

### 3.2 Defining Words & Code Generation

**Defining words** = words that create other words:

```forth
: MAKE-COUNTER
  CREATE 0 ,      ( Create a new word with initial value 0 )
  DOES>
    @             ( Fetch current value )
    DUP 1+ SWAP ! ( Increment and store )
;

MAKE-COUNTER MY-COUNTER
MY-COUNTER MY-COUNTER MY-COUNTER   ( ⇒ 1 2 3 )
```

**Application to MMO:**
```forth
: NPC-CLASS ( name health -- )
  CREATE 2 ,
  DOES>
    @+ @           ( Fetch name and health )
;

NPC-CLASS GOBLIN-TYPE
  S" Goblin" ,     ( name)
  15 ,             ( health )

: MAKE-NPC ( class -- npc )
  HERE SWAP 2 @   ( Allocate new NPC with class data )
;
```

**Advantages:**
- ✅ Minimal syntax overhead
- ✅ Dictionary is transparent (can inspect/modify directly)
- ✅ Code generation is natural
- ✅ Stack-based execution is deterministic

**Disadvantages:**
- ❌ Very unfamiliar to modern developers
- ❌ No type safety (all values are on a stack)
- ❌ Hard to debug
- ❌ Limited ecosystem

---

## 4. Lua: Practical Self-Modification for Games

Lua is specifically designed for embedding and has excellent self-modification capabilities.

### 4.1 Runtime Code Execution

**`load()` and `loadstring()`:**

```lua
-- Compile code string into a function (no execution yet)
local code = "return x + y"
local func = load(code)

-- Need to provide environment with x and y
local env = { x = 5, y = 3 }
debug.setfenv(func, env)  -- Lua 5.1

-- Now execute
print(func())  -- ⇒ 8

-- Lua 5.3+ approach: pass env as second parameter
local func = load("return x + y", nil, 't', { x = 5, y = 3 })
print(func())  -- ⇒ 8
```

**Dynamic function creation:**

```lua
local function make_player_action(verb, object)
  local code = string.format([[
    local player = ...
    player.inventory["%s"] = "%s"
    player:perform_action("%s", "%s")
  ]], verb, object, verb, object)
  
  return load(code)
end

-- Player types "take sword"
local action = make_player_action("take", "sword")
action(my_player)  -- Execute the action
```

### 4.2 Metatables for Object Behavior Modification

**Metatables** = Lua's mechanism for customizing object behavior:

```lua
-- Room object with default behavior
local room = {
  name = "Tavern",
  items = { "sword", "goblet" }
}

-- Metatable allows intercepting operations
local mt = {
  __index = function(t, k)
    print("Accessing: " .. k)
    return rawget(t, k)
  end,
  
  __newindex = function(t, k, v)
    print("Setting " .. k .. " = " .. v)
    rawset(t, k, v)
  end
}

setmetatable(room, mt)

print(room.items)  -- Output: "Accessing: items" then {sword, goblet}
room.name = "The Inn"  -- Output: "Setting name = The Inn"
```

**Application to MMO:**
```lua
local world = {}

-- Intercept all world modifications
local world_mt = {
  __newindex = function(t, key, value)
    -- Log the change for undo
    table.insert(change_log, { action = "set", key = key, old = rawget(t, key), new = value })
    rawset(t, key, value)
  end
}

setmetatable(world, world_mt)

-- Any modification is automatically logged!
world.time = 100     -- Logged
world.players = {}   -- Logged
```

### 4.3 The Debug Library: Deep Introspection

```lua
-- Inspect a function
debug.getinfo(my_func)
-- ⇒ {source = "...", nups = 2, currentline = 42, what = "Lua", ...}

-- Get local variables at a stack level
debug.getlocal(stack_level, var_num)

-- Modify upvalues (captured variables)
debug.setupvalue(func, index, new_value)

-- Set a line hook to trace execution
debug.sethook(function(event)
  print("Line executed: " .. debug.getinfo(2).currentline)
end, "l")
```

**Security implications:**
- The debug library is POWERFUL — enables inspecting private state
- In a sandboxed environment, restricting debug library is essential

### 4.4 Sandboxing Lua

**Approach 1: Restricted Environment**

```lua
-- Create a safe environment with only allowed functions
local safe_env = {
  print = print,
  table = { insert = table.insert, remove = table.remove },
  string = { upper = string.upper },
  -- No io.open, os.execute, debug, etc.
}

-- Execute untrusted code in safe environment
local untrusted_code = 'return io.open("/etc/passwd")'
local func = load(untrusted_code)
debug.setfenv(func, safe_env)

pcall(func)  -- Fails: io is nil
```

**Approach 2: Instruction Count Limits**

```lua
-- Hook to count instructions
local max_instructions = 10000
local instruction_count = 0

debug.sethook(function()
  instruction_count = instruction_count + 1
  if instruction_count > max_instructions then
    error("Instruction limit exceeded")
  end
end, "", 1)  -- Count every line

-- Run player code with limit
pcall(load(player_code))
```

**Approach 3: Static Analysis (Pre-execution validation)**

```lua
-- Scan code string for dangerous patterns
function is_safe_code(code_str)
  -- Reject code containing these patterns
  local forbidden = {
    "io.open",
    "os.execute",
    "debug.getinfo",  -- Prevent introspection attacks
    "load",           -- Prevent loading more code
    "loadstring"
  }
  
  for _, pattern in ipairs(forbidden) do
    if code_str:match(pattern) then
      return false
    end
  end
  return true
end

if is_safe_code(player_code) then
  load(player_code)()
else
  error("Code rejected")
end
```

**Best practice for MMO:** Combine all three:
1. Restricted environment (no dangerous APIs)
2. Instruction limit (prevent infinite loops)
3. Static analysis (catch known attack patterns)

### 4.5 Serializing Lua: `string.dump()`

```lua
-- Compile function to bytecode
local func = function(x) return x * 2 end
local bytecode = string.dump(func)

-- Save to file
local file = io.open("function.luac", "wb")
file:write(bytecode)
file:close()

-- Later, load from bytecode
local file = io.open("function.luac", "rb")
local bytecode = file:read("*a")
file:close()

local func = load(bytecode)  -- Restore function
print(func(5))  -- ⇒ 10
```

---

## 5. Fennel: Lisp Macros + Lua Runtime

**Fennel** combines the best of both worlds:
- **Syntax:** Lisp (S-expressions, macros, code-as-data)
- **Runtime:** Lua (fast, minimal, embeddable)

### 5.1 Fennel Macros for Code Generation

```fennel
; Define a macro that generates code
(defmacro define-npc [name health]
  `(let [npc# { :name ,name :health ,health }]
     (table.insert *world* npc#)
     npc#))

; Use the macro
(define-npc "Goblin" 15)

; Expands to:
; (let [npc (table.insert *world* { :name "Goblin" :health 15 })])
```

### 5.2 Fennel Self-Modification Example

```fennel
; World as Fennel code
(def rooms
  { :tavern
    { :name "The Tavern"
      :items [:sword :goblet]
      :exits { :north :street } }})

; Player action: compile new code and execute
(defn player-take-item [room-id item-id]
  (let [room (. rooms room-id)
        new-code (.. "(set (. rooms \"" room-id "\" :items) [")]
        
    ; Generate code that removes the item
    (each [i item (ipairs room.items)]
      (if (not= item item-id)
        (set new-code (.. new-code ":" (tostring item) " "))))
    
    (set new-code (.. new-code "])"))
    
    ; Execute the generated code
    ((eval new-code))))

(player-take-item :tavern :sword)
```

**Advantages:**
- ✅ Lisp syntax for powerful metaprogramming
- ✅ Compiles to Lua (fast execution)
- ✅ Sandboxing via Lua environment
- ✅ Small footprint

---

## 6. Rebol/Red: Code-is-Data Blocks

**Rebol** (and its successor **Red**) treat all code as structured data (blocks):

```rebol
; Everything is a block of values
[1 2 3]          ; A block of numbers
[name "Bob" age 30]  ; A block of mixed types

; Blocks are data until you evaluate them
code: [print "Hello"]
do code   ; Execute the block ⇒ prints "Hello"

; Modify code as data
insert code [name: "Bill"]
do code   ; Now prints different output
```

### 6.1 Dialecting in Rebol

**Dialects** = mini-languages defined within Rebol:

```rebol
; Define a room using a custom dialect
room: [
  name "Tavern"
  description "A warm place"
  items [sword goblet torch]
  exits [north street east market]
]

; Custom interpreter for room dialect
parse room [
  'name set room-name word!
  'description set desc string!
  'items set room-items block!
  'exits set room-exits block!
]

; Result: variables bound to dialect values
print room-name  ; "Tavern"
```

### 6.2 Parse Dialect for Code Transformation

```rebol
; Parse is Rebol's powerful pattern matching + transformation
parse-result: parse [1 2 3 4 5]
  [collect [any [
    number! (emit-next)
  ]]]

; Transform code while parsing
transform-item: func [item] [
  parse item [
    set word word!
    copy rest [any [word! | number! | string!]]
  ]
  reduce [word rest]
]
```

---

## 7. Tcl: Everything is a String

**Tcl** is unusual: "Everything is a string" combined with `uplevel` and `namespace eval` enables runtime code execution.

```tcl
# Basic code execution
set code "expr 2 + 3"
eval $code  ;# ⇒ 5

# Uplevel: Execute code in caller's scope
proc modify-variable {var_name new_value} {
  uplevel 1 [list set $var_name $new_value]
}

set x 10
modify-variable x 20
puts $x  ;# ⇒ 20

# Namespace eval: Execute in specific namespace
namespace eval game {
  set player_count 0
}

namespace eval game {
  incr player_count
  incr player_count
  puts "Players: $player_count"  ;# ⇒ 2
}
```

### 7.1 Dynamic Proc Creation

```tcl
# Create functions at runtime
proc make-adder {n} {
  set code "proc adder {x} {expr \$x + $n}"
  uplevel 1 $code
}

make-adder 10
puts [adder 5]  ;# ⇒ 15

# Player action: dynamically create new command
proc create-npc {name health} {
  set code "proc $name {} { return \"$name (HP: $health)\" }"
  eval $code
}

create-npc goblin 15
puts [goblin]  ;# ⇒ "goblin (HP: 15)"
```

---

## 8. Io Language: Fully Reflective Prototype-Based

**Io** is a minimalist language where everything is reflective: you can inspect and modify any object at runtime.

```io
; Create an object
goblin := Object clone
goblin name := "Goblin"
goblin health := 15

; Introspection: list all slots
goblin slotNames  ;# ⇒ List("name", "health")

; Reflection: add a slot
goblin speak := method("I am a goblin!")

; Reflection: modify method
goblin pathfind := method(target,
  write("Moving to target\n")
)

; Modify object structure
goblin proto := Monster  ; Change parent (inheritance)
```

**Advantages:**
- ✅ Ultra-minimal syntax
- ✅ Everything is reflective (no privileged operations)
- ✅ Pure prototype-based (easier to modify than class-based)

**Disadvantages:**
- ❌ Very niche (small ecosystem)
- ❌ Difficult to sandbox (no built-in security)
- ❌ Not widely used in game dev

---

## 9. Code-as-World-State Pattern: Practical Architecture

### 9.1 From Player Action to Code Mutation

**Example: "take sword" action**

```lua
-- Step 1: Initial world state (Lua source code)
local room_tavern = {
  name = "The Tavern",
  description = "A warm, smoky tavern...",
  items = { "sword", "goblet" },
  exits = { north = "room_street" }
}

-- Step 2: Player types "take sword"
local action = parse_command("take sword")
-- action = { verb = "take", object = "sword" }

-- Step 3: Event sourcing layer records the action
log_event({
  type = "ItemPickedUp",
  player_id = player.id,
  item_id = "sword",
  room_id = "tavern",
  timestamp = game_time
})

-- Step 4: Apply effect (code mutation)
room_tavern.items = remove_item(room_tavern.items, "sword")
player.inventory = add_item(player.inventory, "sword")

-- Step 5: Serialize modified state back to Lua source
local new_world_code = generate_lua_code(world_state)
-- Result:
-- local room_tavern = {
--   name = "The Tavern",
--   ...
--   items = { "goblet" },  -- sword is gone!
-- }

-- Step 6: Save to file (version control)
save_world_file(new_world_code)
git_commit("Player took sword from tavern")
```

### 9.2 Save/Load Semantics

**Approach A: Source Code Serialization**

```lua
-- Entire world is Lua code
function serialize_world_to_code(world_state)
  local code = "return {\n"
  for room_id, room in pairs(world_state.rooms) do
    code = code .. string.format('  %s = {\n', room_id)
    code = code .. string.format('    name = %q,\n', room.name)
    code = code .. string.format('    items = %s,\n', serialize_table(room.items))
    code = code .. "  },\n"
  end
  code = code .. "}\n"
  return code
end

-- Save to file
local file = io.open("world.lua", "w")
file:write(serialize_world_to_code(world))
file:close()

-- Load: simply execute Lua file
local world = dofile("world.lua")
```

**Approach B: Event Log Reconstruction**

```lua
-- Save compact event log
function serialize_events_to_json(event_log)
  return json.encode(event_log)
end

-- Example event log
[
  { type = "PlayerCreated", player_id = "p1", name = "Alice" },
  { type = "ItemPickedUp", player_id = "p1", item = "sword" },
  { type = "PlayerEnteredRoom", player_id = "p1", room = "tavern" },
  { type = "ItemDropped", player_id = "p1", item = "sword", room = "tavern" }
]

-- Restore: replay events from initial state
function rebuild_world_from_events(initial_world, events)
  local world = deepcopy(initial_world)
  for _, event in ipairs(events) do
    apply_event(world, event)
  end
  return world
end
```

**Hybrid approach (recommended):**
- Store snapshots of world state periodically (every 100 events)
- Store events incrementally (between snapshots)
- On load: find nearest snapshot, replay events from there
- This combines performance of snapshots with granularity of events

### 9.3 Diff Strategies for Universe States

**AST Diff (what changed semantically):**
```lua
-- Compare two world states
function diff_worlds(world1, world2)
  local changes = {}
  
  for room_id, room1 in pairs(world1.rooms) do
    local room2 = world2.rooms[room_id]
    if room2 then
      -- Check items
      for item_id, item1 in pairs(room1.items) do
        if not room2.items[item_id] then
          table.insert(changes, {
            type = "ItemRemoved",
            room = room_id,
            item = item_id
          })
        end
      end
      -- Check if room properties changed
      if room1.name ~= room2.name then
        table.insert(changes, {
          type = "RoomRenamed",
          room = room_id,
          old_name = room1.name,
          new_name = room2.name
        })
      end
    end
  end
  
  return changes
end
```

**Version Control with Git:**

```bash
# Each universe modification creates a commit
$ git log --oneline
abc123 Player dropped torch in dungeon
def456 Goblin health decreased to 5
ghi789 Player picked up sword

# Branch for alternate timelines
$ git branch multiverse/player-refuses-quest
$ git checkout multiverse/player-refuses-quest
# World now evolves differently

# Merge timelines (when universes converge)
$ git merge multiverse/player-cooperates
```

### 9.4 Undo/Rewind Mechanics

**Using Event Sourcing:**

```lua
function undo_action()
  if event_index > 0 then
    -- Remove last event
    table.remove(events, event_index)
    event_index = event_index - 1
    
    -- Rebuild world from snapshot + remaining events
    world = deepcopy(world_snapshots[event_index])
    for i = 1, event_index do
      apply_event(world, events[i])
    end
  end
end

function jump_to_time(target_time)
  -- Find nearest snapshot before target time
  local snapshot_idx = find_nearest_snapshot(target_time)
  world = deepcopy(world_snapshots[snapshot_idx])
  
  -- Replay events up to target time
  for i = snapshot_idx + 1, #events do
    if events[i].timestamp <= target_time then
      apply_event(world, events[i])
    else
      break
    end
  end
end
```

**Time Travel Feature (Outer Wilds-style):**

```lua
-- Every action creates branch in timeline
function take_action(action)
  -- Save current state as branch point
  create_branch_point(world, current_time)
  
  -- Apply action normally
  apply_event(world, action)
  
  -- Later: player can rewind and try different action
  -- All parallel timelines preserved
end

function explore_branch(branch_name)
  -- Switch to alternate timeline
  world = load_branch_point(branch_name)
  current_time = branch_times[branch_name]
end
```

---

## 10. Image-Based Persistence: Smalltalk Model

**Smalltalk** (and modern dialect **Pharo**) uses an "image" — a complete snapshot of all running objects.

### 10.1 How Smalltalk Images Work

```smalltalk
"In Smalltalk, there is only ONE running instance"
MyClass := Object subclass: #Room
  instanceVariableNames: 'name items exits'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Adventure'.

"Define an instance"
tavern := Room new.
tavern name: 'The Tavern'.
tavern items: #('sword' 'goblet').

"Modify class definition at runtime"
MyClass addMethod: 
  (CompiledMethod
    selector: #take:
    source: 'take: item | item remove: item from: self items. ^item').

"The entire running state (including all objects, methods, debugger state) 
 is saved as one binary 'image' file"

World save.  "Saves 'world.image' — complete snapshot"

"When restarted, image is loaded and execution resumes exactly where it left off"
World load.  "Resume from save point"
```

### 10.2 Can Each Universe Be a Smalltalk Image?

**Conceptually:** Yes! Each player's universe could be:
1. A Smalltalk image (complete object snapshot)
2. Branched from a common base image
3. Loaded when player logs in
4. Saved when player logs out

```smalltalk
"Player universe management"
class PlayerUniverse
  |image player_id save_file|
  
  PlayerUniverse new: aPlayerId [
    player_id := aPlayerId.
    save_file := 'universes/', player_id, '.image'.
    image := load_image(save_file).
  ].
  
  save [
    image save_to: save_file.
  ].
  
  take_action: action [
    "Execute action in this universe's image"
    image at: 'world' execute_action: action.
    self save.
  ].
end.
```

**Advantages:**
- ✅ Instant persistence (entire state is an object graph)
- ✅ Live modification (classes, methods, state all mutable)
- ✅ Fast startup (image already "loaded")
- ✅ Time travel possible (version control images)

**Disadvantages:**
- ❌ Image corruption risk (bad write = corrupted universe)
- ❌ Large files (image contains all objects, not just definitions)
- ❌ Difficult to diff (binary format, not human-readable)
- ❌ Concurrency hard (one image = one CPU thread typically)
- ❌ Smalltalk ecosystem declining (mostly academic/hobbyist now)

### 10.3 Pharo's Approach

**Pharo** (modern Smalltalk) improves image safety:

```smalltalk
"Pharo source-file system: source is version-controlled"
FileSystem disk workingDirectory / 'MyGame.st' writeStream 
  nextPutAll: (RPackage named: 'MyGamePackage') snapshot asString.

"Image is more like a 'compiled cache' of source + runtime state"
"If image corrupts, re-load source and rebuild from scratch"
```

**Hybrid approach (best of both):**
- Keep source code in Git (like Lua)
- Maintain runtime object graph (like Smalltalk image)
- Periodically serialize object graph to JSON/binary
- On startup, rebuild from source + cached object state

---

## 11. LambdaMOO: In-Database Programming Model

### 11.1 LambdaMOO Architecture

**LambdaMOO** is a classic example of a self-modifying game world:

```c
// LPC (LambdaMOO) object definition

#include "/lib/object"

void create() {
  ::create();
  set_name("sword");
  set_description("A well-forged iron sword.");
  set_property("magic", 0);
  set_property("damage", 5);
}

void init() {
  add_action("swing", "swing");
  add_action("drop", "drop");
}

int swing(string str) {
  tell_object(this_player(), "You swing the sword!");
  force_me(TO, "emote swings a sword!");
  return 1;
}

// Player (wizard level) can modify this object:
// > @desc sword as "A legendary blade..."
// > @add-property sword magic 1
// Object is updated in database immediately
```

### 11.2 Security Model

**Privilege Hierarchy:**
- **Guest:** Cannot write code
- **User:** Can create personal objects
- **Wizard:** Can modify public objects
- **Arch:** Can modify core systems

**Resource Limits:**
- Bytecode instruction count per operation
- Memory per object
- Stack depth limit

**Access Control:**
```c
// Each object has an 'owner'
set_owner(obj, player_id);

// Only owner or wizard can modify
if (query_owner(obj) != this_player() && !wizardp(this_player())) {
  write("Permission denied");
  return 0;
}
```

### 11.3 Lessons for Self-Modifying MMO

- ✅ **Hierarchical permissions** prevent players from breaking everything
- ✅ **In-database code** means changes persist immediately
- ✅ **Resource limits** prevent infinite loops / DoS
- ⚠️ **Limited language** (no JSON, no modern libraries) — update to Lua
- ⚠️ **Type safety** weak — easy to corrupt state with mistakes
- ⚠️ **Debugging hard** — mutations happen globally, hard to trace

---

## 12. Live Coding Inspiration: Sonic Pi, Overtone, SuperCollider

### 12.1 Live Coding Pattern

**Live coder edits code** while it's running. Code changes take effect immediately:

```python
# Sonic Pi-like pattern (pseudocode)
loop do
  play :C4, release: 0.25   # User can change this note
  sleep 0.25
end

# If user changes :C4 to :E4 mid-loop, next iteration plays E4
# Old sound threads continue; only future notes use new code
```

### 12.2 Temporal Separation

```lua
-- Key insight: separate "what was played" from "what will play"

-- Active sounds (playing right now)
active_sounds = {
  { start = 0.0, duration = 1.0, frequency = 440 },
  { start = 0.5, duration = 1.0, frequency = 550 }
}

-- Future code (what plays next)
future_code = "play(440, 0.5); play(660, 0.5)"

-- User edits code
future_code = "play(220, 0.5); play(440, 0.5)"  -- Changed!

-- When current sounds finish, new code takes over
-- Seamless transition, no audio glitches
```

### 12.3 Hot Reloading for NPC Behaviors

```lua
-- Original NPC behavior (Lua code)
function npc_guard:patrol()
  while true do
    self:wander()
    wait(1.0)
  end
end

-- While NPC is running (mid-patrol), code is reloaded
function npc_guard:patrol()
  while true do
    self:intelligent_patrol()  -- Now pathfinds instead of wandering
    wait(2.0)  -- And takes longer per step
  end
end

-- Next iteration of loop uses new code
-- Existing loop iterations continue with old code
-- No crash, no interruption
```

---

## 13. Security, Risks, and Mitigations

### 13.1 Code Injection Prevention

**Risk:** Malicious player writes code that:
- Breaks out of sandbox
- Reads other players' data
- Corrupts world state
- Creates infinite loops

**Mitigation 1: Static Analysis**

```lua
local forbidden_patterns = {
  "io.open",
  "io.write",
  "os.execute",
  "debug.getinfo",
  "debug.getlocal",
  "require",
  "load",
  "loadstring"
}

function validate_player_code(code_string)
  for _, pattern in ipairs(forbidden_patterns) do
    if code_string:match(pattern) then
      return false, "Code contains forbidden function: " .. pattern
    end
  end
  return true
end

if not validate_player_code(player_input) then
  error("Code rejected!")
  return
end
```

**Mitigation 2: Restricted Environment**

```lua
-- Only whitelist safe functions
local safe_environment = {
  -- Math
  math = { abs = math.abs, floor = math.floor, random = math.random },
  
  -- String (safe operations only)
  string = { upper = string.upper, lower = string.lower, len = string.len },
  
  -- Table (limited)
  table = { insert = table.insert, remove = table.remove },
  
  -- Excluded: io, os, debug, require, load, dofile
}

local func = load(player_code)
debug.setfenv(func, safe_environment)
pcall(func)  -- Safe execution
```

**Mitigation 3: Instruction Limits**

```lua
local instruction_limit = 100000
local instruction_count = 0

debug.sethook(function()
  instruction_count = instruction_count + 1
  if instruction_count > instruction_limit then
    error("Instruction limit exceeded")
  end
end, "", 1)

pcall(load(player_code))  -- Limited execution
```

**Mitigation 4: Capability-Based Security**

```lua
-- Player can only modify objects they own
function make_safe_api_for_player(player_id)
  return {
    modify_object = function(obj_id, field, value)
      local obj = world.objects[obj_id]
      if obj.owner ~= player_id then
        error("Permission denied: you don't own " .. obj_id)
      end
      obj[field] = value
    end,
    
    get_object = function(obj_id)
      return world.objects[obj_id]
    end
    
    -- Note: no read_file, write_file, exec, etc.
  }
end

-- Player code only has access to this API
local player_api = make_safe_api_for_player(player.id)
local func = load(player_code)
debug.setfenv(func, player_api)
pcall(func)
```

### 13.2 Preventing Infinite Loops

**Risk:** Player code contains `while true` without exit condition

**Mitigation:**

```lua
-- Timeout: if code takes too long, kill it
function execute_with_timeout(code, timeout_seconds)
  local start_time = os.time()
  local function check_timeout()
    if (os.time() - start_time) > timeout_seconds then
      error("Execution timeout")
    end
  end
  
  debug.sethook(check_timeout, "", 1000)  -- Check every 1000 lines
  return pcall(load(code))
end

execute_with_timeout(player_code, 5)  -- Kill after 5 seconds
```

### 13.3 Memory and Resource Exhaustion

**Risk:** Player code creates massive tables/strings → out of memory

**Mitigation:**

```lua
-- Track memory usage
local memory_limit = 100 * 1024 * 1024  -- 100 MB
local memory_used = 0

-- Intercept allocations (approximate)
local original_table = table
table = setmetatable({}, {
  __index = function(t, k)
    return original_table[k]
  end,
  __newindex = function(t, k, v)
    memory_used = memory_used + estimate_size(v)
    if memory_used > memory_limit then
      error("Memory limit exceeded")
    end
    rawset(original_table, k, v)
  end
})

-- Or use Lua's C API (from C embedder) to track GC
```

### 13.4 Debugging Self-Modifying Worlds

**Challenge:** When code is mutable, how do you debug?

**Solutions:**

1. **Trace log of all mutations:**
```lua
local mutation_log = {}

function log_mutation(object_id, old_code, new_code)
  table.insert(mutation_log, {
    timestamp = os.time(),
    object = object_id,
    old = old_code,
    new = new_code
  })
end

-- When something breaks, inspect mutation_log
-- See exactly when the object changed
```

2. **Snapshot + replay:**
```lua
-- Save world state before executing player code
local snapshot = deepcopy(world)

-- Execute player code
local success, err = pcall(load(player_code))

if not success then
  -- Restore from snapshot
  world = snapshot
  log_error(err)
end
```

3. **Inspector/debugger:**
```lua
-- Dump current state for inspection
function dump_world()
  local out = io.open("world_debug.txt", "w")
  for obj_id, obj in pairs(world.objects) do
    out:write(string.format("[%s] %s\n", obj_id, obj.name))
    for field, value in pairs(obj) do
      out:write(string.format("  %s = %s\n", field, tostring(value)))
    end
  end
  out:close()
end
```

### 13.5 State Corruption Recovery

**Risk:** Code mutation leaves world in broken state

**Mitigation:**

1. **Validation layer:**
```lua
function validate_world()
  -- Check consistency
  for obj_id, obj in pairs(world.objects) do
    if not obj.name or obj.name == "" then
      error("Invalid object: " .. obj_id .. " missing name")
    end
    if obj.container and not world.objects[obj.container] then
      error("Invalid containment: " .. obj_id .. " -> " .. obj.container)
    end
  end
  return true
end

-- After each mutation
if not pcall(validate_world) then
  log_error("World corruption detected!")
  world = load_last_good_snapshot()
end
```

2. **Immutable snapshots:**
```lua
-- Save snapshot every N seconds
function auto_save()
  local snapshot = deepcopy(world)
  table.insert(snapshots, { time = os.time(), state = snapshot })
  
  -- Keep only last 10 snapshots
  if #snapshots > 10 then
    table.remove(snapshots, 1)
  end
end

-- On corruption, fall back
world = snapshots[#snapshots - 1].state
```

---

## 14. LangChain Pattern: Integration with LLM Code Generation

Since your MMO is **entirely code-generated by LLM**, self-modification becomes a feature, not a bug:

```lua
-- World definition generated by LLM
local world_code = llm_generate_world({
  prompt = "Create a fantasy tavern with 3 NPCs and 5 items",
  style = "Lovecraftian horror",
  rules = "containment_hierarchy"
})

-- Execute LLM-generated code
local world = load(world_code)()

-- Player action triggers new LLM generation
local player_action = "take the cursed amulet"
local mutation_code = llm_generate_mutation({
  world = world_code,
  action = player_action,
  context = "The amulet grants dark powers"
})

-- Apply mutation
local new_world_code = execute_mutation(world_code, mutation_code)

-- Serialize back
save_world_source(new_world_code)
```

**Advantage:** LLM can generate world modifications that are:
- Semantically coherent (LLM understands game logic)
- Syntactically correct (tested at runtime)
- Creative (LLM's strength)

---

## 15. Recommendations: Final Architecture

### 15.1 Recommended Stack

```
┌────────────────────────────────────────────────────────┐
│            Self-Modifying MMO Engine                   │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Language:           Lua (+ Fennel for advanced users)│
│  Homoiconicity:      Via Fennel S-expressions         │
│  Runtime:            Lua 5.4 (fast, minimal)          │
│  Embedding:          Lua C API (in game server)       │
│                                                        │
│  World Representation:                                 │
│    - Source:         Lua tables & functions           │
│    - Runtime:        Live object graph                │
│    - Persistence:    Serialize to Lua + commit to Git │
│                                                        │
│  State Management:   Event Sourcing                   │
│    - Events:         Immutable log of player actions  │
│    - Snapshots:      Periodic world state saves       │
│    - Undo:           Replay from snapshot             │
│                                                        │
│  Mutation System:                                      │
│    - Player edits:   LLM-generated code transformations
│    - Sandbox:        3-layer (restrict env + timeouts +
│                               static analysis)        │
│    - Validation:     Post-mutation consistency checks │
│                                                        │
│  Version Control:    Git (one repo per universe)      │
│    - Branching:      Alternate universes/timelines    │
│    - Merging:        Converging universes             │
│    - Rollback:       `git checkout <commit>`          │
│                                                        │
│  Developer Tools:                                      │
│    - REPL:           Lua console for live debugging   │
│    - Inspector:      Dump world state to JSON         │
│    - Time travel:    Jump to any commit in history    │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 15.2 Example: "Take Sword" Flow

```lua
-- STEP 1: Initial world state (Lua source)
-- File: universe-player1/world.lua
local world = {
  rooms = {
    tavern = {
      name = "The Tavern",
      items = { sword = { name = "Iron Sword", damage = 5 }, 
                goblet = { name = "Silver Goblet" } },
      exits = { north = "street" }
    }
  },
  player = {
    inventory = {},
    location = "tavern"
  }
}

-- STEP 2: Parse "take sword"
local action = parse_command("take sword")
-- Returns: { verb = "take", object = "sword" }

-- STEP 3: Event Sourcing - record event
local event = {
  type = "PlayerTookItem",
  player_id = "player1",
  item_id = "sword",
  room_id = "tavern",
  timestamp = game_time
}
table.insert(events, event)

-- STEP 4: Apply mutation
world.rooms.tavern.items.sword = nil
world.player.inventory.sword = { name = "Iron Sword", damage = 5 }

-- STEP 5: Generate new Lua code
local new_world_code = [[
local world = {
  rooms = {
    tavern = {
      name = "The Tavern",
      items = { goblet = { name = "Silver Goblet" } },  -- sword removed!
      exits = { north = "street" }
    }
  },
  player = {
    inventory = { sword = { name = "Iron Sword", damage = 5 } },  -- sword added!
    location = "tavern"
  }
}
return world
]]

-- STEP 6: Save and commit
save_world_file(new_world_code)
git_commit("Player took sword from tavern")
git_push()

-- STEP 7: Reload world from new code
world = load(new_world_code)()
```

### 15.3 Multiverse Management

```lua
-- Each player gets their own Git repo for their universe
function create_player_universe(player_id)
  local repo_path = "universes/" .. player_id
  os.execute("git init " .. repo_path)
  
  -- Initialize with base world
  local base_world = load_base_world()
  save_world_file(repo_path .. "/world.lua", base_world)
  
  os.execute("cd " .. repo_path .. " && git add world.lua && git commit -m 'Initial world'")
end

-- When players converge (multiplayer)
function merge_universes(player1_id, player2_id)
  local repo1 = "universes/" .. player1_id
  local repo2 = "universes/" .. player2_id
  
  -- Git merge (will handle conflicts if needed)
  os.execute("cd " .. repo1 .. " && git remote add player2 ../" .. repo2 ..
             " && git fetch player2 && git merge player2/main")
  
  -- Load merged world
  local merged_world = load(repo1 .. "/world.lua")()
  
  return merged_world
end

-- Branching for "what if" scenarios
function create_alternate_timeline(player_id, branch_name)
  local repo = "universes/" .. player_id
  os.execute("cd " .. repo .. " && git checkout -b " .. branch_name)
end
```

---

## 16. Academic References

1. **"An Approach to the Synthesis of Life"** by Tom Ray (1991)
   - Tierra: Self-replicating code in sandboxed environment
   - Proof that self-modifying code can evolve

2. **"Core War"** Papers (1984 onward)
   - Redcode: Assembly-like language for self-modifying programs
   - Sandbox via circular memory and instruction restrictions

3. **"Smalltalk-80: The Interactive Programming Environment"** by Goldberg & Robson (1983)
   - Meta-object protocols for runtime modification
   - Image-based persistence

4. **"The Scheme Programming Language"** by Dybvig (various editions)
   - Macros and meta-programming theory
   - `eval` and self-modification

5. **"LambdaMOO: The Architecture of an Object-Oriented Database Language"**
   - In-database programming model
   - Role-based access control

6. **Event Sourcing (CQRS Pattern)**
   - Martin Fowler, 2005
   - Immutable event log as source of truth

---

## 17. Implementation Roadmap

### Phase 1: Foundation
- [ ] Implement Lua world representation (tables + functions)
- [ ] Build containment hierarchy (parent pointers)
- [ ] Event sourcing layer (log + replay)
- [ ] Basic snapshot system

### Phase 2: Mutation System
- [ ] Lua `load()` + environment sandboxing
- [ ] Static analysis for forbidden code patterns
- [ ] Instruction count limits
- [ ] Memory budgets

### Phase 3: Persistence
- [ ] Lua-to-source-code serialization
- [ ] Git integration for version control
- [ ] Snapshot + event log combination
- [ ] Undo/rewind system

### Phase 4: Advanced Features
- [ ] Fennel macro system (for advanced players)
- [ ] LLM code generation integration
- [ ] Hot code reloading (live modification)
- [ ] Time travel / branching universes

### Phase 5: Developer Tools
- [ ] Lua REPL console
- [ ] World state inspector
- [ ] Git history visualization
- [ ] Mutation logger/tracer

---

## Conclusion

The **code-as-world** architecture is feasible and has strong precedent:

1. **LambdaMOO** proved in-database code modification works
2. **Smalltalk** showed live object modification at scale
3. **Event Sourcing** enables deterministic replay and undo
4. **Lua** provides the sandboxing and performance needed
5. **Git** offers version control and branching for multiverse

**Key insight:** Combine homoiconicity (Lua/Fennel) with capability-based sandboxing and event sourcing. The result is a world where player actions ARE code mutations, enabling emergent complexity while maintaining safety and debuggability.

The recommended stack (Lua + Event Sourcing + Git) is pragmatic, proven, and achieves the vision of a self-modifying MMO where the universe IS source code.
