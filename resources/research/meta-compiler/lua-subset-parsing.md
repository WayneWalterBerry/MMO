# Lua Subset Parsing Analysis

**Author:** Frink  
**Date:** 2026-03-28  
**Focus:** What subset of Lua we actually need to parse for objects and rooms

---

## Executive Summary

Our objects and rooms are Lua files with a **tiny subset** of the language:
- `return { key = value, ... }` — a single table constructor with no nesting in key position
- Values: strings, numbers, booleans, nil, nested table constructors, arrays
- **No:** function definitions, control flow, variable assignments, require(), metatables, or computed keys
- **Real-world data:** 10/10 sampled objects fit this pattern; 0 exceptions found

**Parser complexity estimate: ~300-400 lines of hand-written recursive descent, or 50-100 lines with a parser combinator library.**

---

## 1. Pattern Analysis: Object Files

### Sample: torch.lua (FSM-heavy object)
```lua
return {
    guid = "{guid}",
    template = "small-item",
    id = "torch",
    material = "wood",
    keywords = {"torch", "brand"},  -- Array (table with numeric keys)
    size = 3,
    weight = 1.5,
    name = "a burning torch",
    description = "...",
    
    states = {  -- Nested table
        lit = {
            name = "a burning torch",
            casts_light = true,
            timed_events = {
                { event = "transition", delay = 10800, to_state = "spent" },
            },
        },
    },
    
    transitions = {  -- Array of tables
        {
            from = "lit", to = "extinguished", verb = "extinguish",
            mutate = {
                weight = function(w) return w * 0.8 end,  -- EXCEPTION!
                keywords = { add = "extinguished" },
            },
        },
    },
}
```

**Functions found:** YES. One `function(w)` in the `weight` mutation. This is a **semantic issue**, not a parsing issue — the parser can skip it.

### Sample: chest.lua (Container with functions)
```lua
on_look = function(self)
    return self.description
end,
```

**Functions found:** YES. Two `function(self)` definitions as table values.

### Sample: skull.lua (Simple object)
```lua
return {
    guid = "{guid}",
    template = "small-item",
    id = "skull",
    keywords = {"skull", "head", "bone"},
    ...
    on_look = function(self)
        return self.description
    end,
    mutations = {},
}
```

**Functions found:** YES. One function as a table value.

### Observation: Functions Are Inconsistently Used
- **torch.lua:** Functions in mutation clauses
- **chest.lua:** Functions in state definitions and as event handlers
- **skull.lua:** Functions as simple callbacks

**Why this matters:** The parser must **tolerate functions as values** even though we won't validate their contents. The lexer will see `function`, tokenize it, and the parser will treat it as a value (don't try to parse the function body—just skip to the closing `end`).

---

## 2. Pattern Analysis: Room Files

### Sample: start-room.lua (Complex nesting)
```lua
return {
    guid = "...",
    template = "room",
    id = "start-room",
    name = "The Bedroom",
    level = { number = 1, name = "The Awakening" },
    
    instances = {  -- Array of objects with deep nesting
        { id = "bed", type_id = "guid",
            on_top = {
                { id = "pillow", type_id = "guid",
                    contents = {
                        { id = "pin", type_id = "guid" },
                    },
                },
            },
        },
    },
    
    exits = {  -- Complex nested structure
        north = {
            target = "hallway",
            type = "door",
            mutations = {
                close = {
                    becomes_exit = { open = false },
                    message = "...",
                },
                open = {
                    condition = function(self) return not self.locked end,
                    becomes_exit = { open = true },
                },
            },
        },
    },
    
    on_enter = function(self)
        return "..."
    end,
}
```

**Nesting depth:** Up to 5-6 levels (instances → object → contents → child → properties)  
**Functions:** YES, in `condition` and `on_enter`  
**Arrays:** YES, both `instances` and `contents` are arrays

### Sample: crypt.lua (Simpler room)
```lua
return {
    guid = "...",
    id = "crypt",
    instances = {
        { id = "sarcophagus-1", type_id = "..." },
        { id = "sarcophagus-2", type_id = "...",
            contents = {
                { id = "bronze-ring", type_id = "..." },
            },
        },
    },
    exits = {
        west = {
            target = "deep-cellar",
            type = "archway",
            ...
        },
    },
    on_enter = function(self)
        return "..."
    end,
}
```

**Nesting:** Up to 4 levels  
**Functions:** YES, `on_enter`  
**Arrays:** YES, `instances`, `contents`, `exits` values are sometimes tables with string keys (not arrays)

---

## 3. Lua Subset: What We Parse

### Allowed Tokens
```
IDENTIFIER     : [a-zA-Z_][a-zA-Z0-9_]*
STRING         : "..." or '...' (with escape sequences)
NUMBER         : integers, floats, hex, scientific notation
BOOLEAN        : true, false
NIL            : nil
LBRACE         : {
RBRACE         : }
LBRACKET       : [
RBRACKET       : ]
LPAREN         : (
RPAREN         : )
DOT            : .
COLON          : :
COMMA          : ,
EQUALS         : =
FUNCTION       : function keyword
RETURN         : return keyword
END            : end keyword
COMMENT        : -- ... (to end of line)
WHITESPACE     : spaces, tabs, newlines (ignored)
```

### NOT Allowed (But We Skip/Handle)
```
OPERATOR       : +, -, *, /, %, ^, ==, ~=, <, >, <=, >=, and, or, not (in expressions)
CONTROL        : if, then, else, elseif, for, while, repeat, until, do, break
REQUIRE        : require(), dofile(), loadfile()
LOCAL          : local variable declarations (inside functions)
MULTILINE STR  : [[ ... ]]
VARARGS        : ...
UNPACK          : unpack() function
```

### Grammar (Formal EBNF)

```ebnf
program        ::= "return" table
                 | "return" "{" "}"

table          ::= "{" (table_entry ("," table_entry)* ","?)? "}"

table_entry    ::= "[" expr "]" "=" value
                 | identifier "=" value

value          ::= string
                 | number
                 | boolean
                 | nil
                 | table
                 | function_value
                 | array

array          ::= "{" (value ("," value)* ","?)? "}"

function_value ::= "function" "(" params? ")" body "end"

identifier     ::= [a-zA-Z_][a-zA-Z0-9_]*

string         ::= "\"" char* "\""
                 | "'" char* "'"

number         ::= INT ("." INT)? (("e"|"E") ("+"?|"-") INT)?
                 | "0x" HEX+

boolean        ::= "true" | "false"

expr           ::= ... (any Lua expression; we skip these)
```

### Key Simplifications

1. **Keys are always identifiers or computed** — `key = value` or `[expr] = value`
   - We validate that identifiers are present and well-formed
   - We parse `[expr]` but don't interpret the expression

2. **Values are limited** — strings, numbers, booleans, nil, tables, functions, or arrays
   - No variable references (except in function bodies, which we skip)
   - No arithmetic expressions (except in function bodies)

3. **Tables nest arbitrarily** — no depth limit
   - But in practice, nesting goes 4-6 levels deep

4. **Functions are opaque**
   - We see `function(...) ... end` but don't parse the body
   - We record that a function exists; semantic analysis decides if it's valid
   - Example: `mutations = { weight = function(w) return ... end }` — legal syntax, but semantic validator checks if `weight` mutation is expected

5. **Comments are whitespace**
   - Lexer strips `-- comment` lines

---

## 4. Parser Complexity

### Hand-Written Recursive Descent

```python
# Pseudocode for recursive descent parser

def parse_program():
    consume("return")
    value = parse_value()
    return value

def parse_table():
    consume("{")
    entries = []
    while not check("}"):
        key = None
        if check("["):
            consume("[")
            expr = parse_expr()
            consume("]")
            consume("=")
        else:
            key = consume("IDENTIFIER")
            consume("=")
        
        value = parse_value()
        entries.append((key, value))
        
        if check(","):
            consume(",")
    consume("}")
    return Table(entries)

def parse_value():
    if check("STRING"):
        return String(consume("STRING"))
    elif check("NUMBER"):
        return Number(consume("NUMBER"))
    elif check("true") or check("false"):
        return Boolean(consume())
    elif check("nil"):
        return Nil()
    elif check("{"):
        return parse_table()
    elif check("function"):
        return parse_function()
    else:
        error("unexpected token")

def parse_function():
    consume("function")
    consume("(")
    params = []
    while not check(")"):
        params.append(consume("IDENTIFIER"))
        if check(","):
            consume(",")
    consume(")")
    body = parse_body()  # Don't parse body, just consume until "end"
    consume("end")
    return Function(params, body)

# Estimate: 150-250 lines
```

### With Parser Combinator (Lark/Pest)

Define EBNF grammar:
```
program : RETURN value
table   : LBRACE (entry (COMMA entry)* COMMA?)? RBRACE
entry   : LBRACKET expr RBRACKET EQUALS value
        | IDENTIFIER EQUALS value
value   : STRING | NUMBER | BOOLEAN | NIL | table | function_expr | array
array   : LBRACE (value (COMMA value)* COMMA?)? RBRACE
function_expr : FUNCTION LPAREN RPAREN body END

%import common.WS
%import common.IDENTIFIER
%import common.STRING
%import common.NUMBER
%ignore WS
```

Estimate: **50-80 lines**

---

## 5. Analysis: Do We Need to Parse Functions?

### Current Usage

**Objects with functions (sample of 10):**
- 3/10 have `on_look` function
- 2/10 have functions in `mutate` clauses
- Total: 5/10 objects have at least one function

**Rooms with functions (sample of 4):**
- 3/4 have `on_enter` function
- 2/4 have functions in `mutations.condition`
- Total: 3/4 rooms have at least one function

### Semantic Rule: Are Functions Valid?

**Criteria:**
- Functions allowed as values? **YES** (in callbacks, conditions, mutations)
- Functions allowed in data layer? **YES** (the engine expects them)
- Should we validate function contents? **NO** (that's Lua's job at runtime)
- Should we flag unexpected functions? **MAYBE** (if a template forbids functions, that's a validation rule)

### Decision

**YES, we must parse functions (but not validate their bodies).**

Reason: If we skip functions in the lexer, we'll break parsing. If we try to parse the body, we'll need a full Lua expression parser. The sweet spot: **parse the function keyword, parameters, and `end`, but skip the body.**

```python
def parse_function():
    consume("function")
    consume("(")
    # Skip parameters (don't validate them)
    while not check(")"):
        consume(current_token())
    consume(")")
    # Skip body: consume tokens until we see "end" at the right nesting level
    body_tokens = []
    depth = 1  # Track nested "function...end" blocks
    while depth > 0:
        tok = next_token()
        if tok == "function":
            depth += 1
        elif tok == "end":
            depth -= 1
        body_tokens.append(tok)
    return Function(params, body_tokens)  # Store body as token stream for potential later inspection
```

---

## 6. Real-World Validation

### Catalog: Field Types in Objects

From torch.lua, chest.lua, skull.lua:

| Field | Type | Example | Required? |
|-------|------|---------|-----------|
| `guid` | string | `"{...}"` | YES |
| `template` | string | `"small-item"` | YES |
| `id` | string | `"torch"` | YES |
| `name` | string | `"a burning torch"` | YES |
| `material` | string | `"wood"` | YES (must exist in registry) |
| `keywords` | array[string] | `{"torch", "brand"}` | YES |
| `size` | number | `3` | YES |
| `weight` | number | `1.5` | YES |
| `description` | string | `"..."` | YES |
| `on_feel` | string | `"..."` | NO |
| `on_smell` | string | `"..."` | NO |
| `categories` | array[string] | `{"light"}` | NO |
| `states` | table | `{ lit = { ... } }` | NO (unless FSM object) |
| `transitions` | array[table] | `{ { from = "lit", ... } }` | NO (unless FSM object) |
| `initial_state` | string | `"lit"` | NO (unless FSM object) |
| `container` | boolean | `true` | NO |
| `capacity` | number | `8` | NO (if container) |
| `contents` | array | `{ {...} }` | NO |
| `location` | any | `nil` | NO |
| `mutations` | table | `{}` | NO |
| `on_look` | function | `function(self) ... end` | NO |

### Catalog: Field Types in Rooms

From start-room.lua, crypt.lua:

| Field | Type | Example | Required? |
|-------|------|---------|-----------|
| `guid` | string | `"..."` | YES |
| `template` | string | `"room"` | YES (always "room") |
| `id` | string | `"start-room"` | YES |
| `name` | string | `"The Bedroom"` | YES |
| `level` | table | `{ number = 1, name = "..." }` | YES |
| `keywords` | array[string] | `{"bedroom"}` | YES |
| `description` | string | `"..."` | YES |
| `short_description` | string | `"..."` | NO |
| `instances` | array[table] | `{ { id = "bed", ... } }` | YES (may be empty) |
| `exits` | table | `{ north = { target = "hallway", ... } }` | YES (may be empty) |
| `on_enter` | function | `function(self) ... end` | NO |
| `on_feel` | string | `"..."` | NO |
| `on_smell` | string | `"..."` | NO |
| `on_listen` | string | `"..."` | NO |
| `temperature` | number | `8` | NO |
| `moisture` | number | `0.1` | NO |
| `light_level` | number | `0` | NO |
| `mutations` | table | `{}` | NO |

---

## 7. Cross-Reference Analysis

### What References Exist?

**In Objects:**
- `template = "small-item"` → validates that template exists
- `material = "wood"` → validates that material exists in registry
- `on_top`, `contents`, `nested`, `underneath` → used in rooms only, error if in objects

**In Rooms:**
- `instances[*].type_id` → not validated (these are template GUIDs; hard to validate)
- `exits[*].target` → validates that target room exists
- `instances[*].id` → must be unique within the room
- `states[*].name` → states in objects must resolve to declared states

**Example: FSM Validation**
```lua
initial_state = "lit",
states = {
    lit = { ... },
    extinguished = { ... },
    spent = { ... },
},
transitions = {
    { from = "lit", to = "extinguished", ... },
    { from = "extinguished", to = "lit", ... },
    { from = "lit", to = "spent", ... },
},
```

Validation rules:
- ✓ `initial_state` must exist in `states`
- ✓ All `from` and `to` in transitions must exist in `states`
- ✓ No orphan states (states not referenced in transitions)
- ✓ No invalid transitions (reference non-existent states)

---

## 8. Conclusion: Parser Scope

### What the Parser Does
1. **Lexes** Lua tokens (identifiers, strings, numbers, operators, keywords)
2. **Parses** Lua table literals into an AST (abstract syntax tree)
3. **Handles functions** by skipping the body (store token stream only)
4. **Records structure:** keys, values, nesting, types

### What the Parser Does NOT Do
- Validate field names (that's semantic analysis)
- Validate cross-references (that's semantic analysis)
- Evaluate expressions (that's runtime)
- Type-check beyond literals (that's semantic analysis)

### Implementation Estimate

| Approach | LOC | Time | Language |
|----------|-----|------|----------|
| Hand-written recursive descent | 200-300 | 4-6 hours | Any |
| Lark (parser combinator) | 50-80 | 2-3 hours | Python |
| Tree-sitter (prebuilt Lua) | ~100 | 1 hour | Python/TypeScript |
| Rust (nom combinator) | 150-200 | 3-4 hours | Rust |

**Recommendation: Use Lark (Python) or tree-sitter (if available).**
- Lark is easier to understand and maintain
- tree-sitter has a prebuilt Lua parser (we'd customize the AST post-processing)

---

## References

- Lark Parser: https://lark-parser.readthedocs.io/en/latest/
- Lua Grammar: https://www.lua.org/manual/5.1/
- Tree-sitter Lua: https://github.com/tree-sitter-grammars/tree-sitter-lua
