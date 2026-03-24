---
name: "lua-reserved-words"
description: "Lua reserved words cannot be used as bare table keys — must bracket-quote them"
domain: "lua-authoring"
confidence: "high"
source: "earned — broke start-room.lua with bare `break` key"
---

## Context
When writing Lua table constructors (object definitions, mutation tables, etc.), some common English words are Lua reserved keywords. Using them as bare table keys causes compile errors.

## Patterns
- Always bracket-quote reserved words when used as table keys: `["break"] = { ... }`
- Lua 5.x reserved words: `and`, `break`, `do`, `else`, `elseif`, `end`, `false`, `for`, `function`, `goto` (5.2+), `if`, `in`, `local`, `nil`, `not`, `or`, `repeat`, `return`, `then`, `true`, `until`, `while`
- Common traps in game content: `break`, `end`, `return`, `not`, `and`, `or`, `do`, `repeat`
- The sandboxed loader catches this at load time — error message: "unexpected symbol near 'break'"

## Examples
```lua
-- WRONG: compile error
mutations = {
    break = { becomes = "vanity-broken" },
}

-- RIGHT: bracket-quoted
mutations = {
    ["break"] = { becomes = "vanity-broken" },
}

-- Safe: non-reserved words don't need quoting
mutations = {
    open = { becomes = "vanity-open" },
    tear = { spawns = {"cloth"} },
}
```

## Anti-Patterns
- Writing `break = {` in table constructors (most common trap)
- Writing `end = true` or `return = "value"` as table fields
- Assuming all English words are safe as Lua identifiers
