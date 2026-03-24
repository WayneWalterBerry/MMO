# Compiler Techniques for Game Data Validation

**Author:** Frink  
**Date:** 2026-03-28  
**Focus:** Industry precedents and compiler-style validation approaches for data-as-code

---

## Executive Summary

Game engines validate data-as-code through multiple approaches, but the most effective use **compiler-style techniques**: lexing, parsing, and semantic analysis. We reviewed community tools and commercial engines to understand what works. Key findings:

1. **Dwarf Fortress RAW validators** use parser-based approaches (Rust, Python) to validate mod syntax and cross-references
2. **Factorio** relies on load-time prototype validation + optional unit testing frameworks
3. **Unity ScriptableObjects** use editor-time `OnValidate` hooks to enforce schema rules
4. **Godot** lacks external schema validators—validation happens during engine load
5. **Community tools** consistently choose: lexer → parser → semantic validation pipeline

**The meta-compiler is architecturally sound. It's the right approach.**

---

## 1. Dwarf Fortress RAW Validators (Community-Driven)

### Background
Dwarf Fortress is community-modded extensively. Modders write `.raw` files that define creatures, plants, materials, and graphics. These files have complex interdependencies:
- Creature files reference materials (e.g., `USE_MATERIAL: BONE`)
- Tissue layers reference materials
- Syndromes reference effects, which reference materials
- Broken or missing references cause silent failures or crashes at game load time

### Validation Tools

**1. DF Raw Language Server (Rust)**
- **Architecture:** Full lexer → parser → AST → error collection
- **Validation Scope:** 
  - Syntax checking (invalid tokens, malformed sections)
  - Cross-section references (creature → tissue → material validation)
  - Semantic errors (invalid property combinations, unknown identifiers)
- **Integration:** VSCode extension; reports errors inline as user edits
- **Compilation Model:** Parses and validates in real-time, no output code generation

**2. dfraw_json_parser (Rust)**
- **Approach:** Lexer + recursive descent parser → JSON output
- **Output:** Both validation errors and structured JSON representation
- **Use Case:** Enables downstream analysis, diffing, or translation
- **Advantage:** Separates parsing from validation; each phase is composable

**3. Overseer's Reference Manual (GUI)**
- **Approach:** Built on dfraw_json_parser; adds a search/browsing interface
- **Validation Display:** Shows problems inline; highlights broken references
- **UX Note:** Makes validation visible to non-technical modders

### Design Pattern
```
RAW text input
    ↓
Lexer (tokenize sections, key-value pairs)
    ↓
Parser (build section tree, resolve nesting)
    ↓
Semantic Analyzer (check references, validate combinations)
    ↓
Error Report (file, line, type, suggestion)
    ↓
(No compilation; file remains .raw for engine to load)
```

### Lessons for MMO
- **Lexer matters:** RAW syntax is line-oriented and structured, easier than Lua but the principle is the same
- **Cross-reference validation is essential:** Materials, entities, effects must resolve
- **Errors should be actionable:** Point to line, explain what's wrong, suggest fixes
- **Real-time feedback (IDE integration) beats batch validation:** Catch issues as soon as code is written

---

## 2. Factorio Prototype Validation (Built-In + Community)

### Background
Factorio is moddable via Lua. Mods define "prototypes"—data objects for items, recipes, entities, technologies. Prototypes are Lua tables that must conform to the engine's schema:
```lua
-- Valid prototype
data:extend({
    {
        type = "item",
        name = "iron-plate",
        icon = "__base__/graphics/icons/iron-plate.png",
        stack_size = 50
    }
})
```

### Validation Strategy

**1. Engine Load-Time Validation**
- **When:** Data stage (before game objects are created)
- **What:** Factorio checks that required fields exist and have correct types
- **Limitation:** Only basic type checking; no deep semantic validation
- **Output:** Load failures with error logs (not structured)

**2. Community Testing (factorio-check)**
- **Approach:** Unit testing framework for Lua mod logic
- **How:** Allows you to assert prototype correctness before load time
- **Trade-off:** Manual test writing; not automatic validation

**3. TypeScript + TypeScript-to-Lua (Advanced)**
- **Approach:** Write mods in TypeScript with typed definitions
- **Compilation:** TypeScript compiler provides **static type checking** at build time
- **Integration:** `typed-factorio` package gives full type definitions for Factorio Lua API
- **Result:** Catch type errors before mod is even loaded

### Design Pattern
```
Lua/TypeScript prototype definitions
    ↓
TypeScript compiler (optional, for static checking)
    ↓
Lua runtime → Engine load
    ↓
Engine: Basic schema validation
    ↓
Optional: Unit tests via factorio-check
    ↓
Runtime errors or success
```

### Lessons for MMO
- **Static checking is better than load-time checking:** Catch errors in CI/CD, not in production
- **Type systems reduce bugs:** TypeScript's approach to Lua is compelling for safety
- **Load-time validation is a fallback, not a solution:** If you wait until the engine loads it, you've already failed
- **Schema-driven validation beats ad-hoc checks:** Define once, validate consistently

---

## 3. Unity ScriptableObject Validation (Editor-Time)

### Background
Unity uses ScriptableObjects as data assets. Designers create .asset files through the editor. The schema is enforced in C# code:

```csharp
[CreateAssetMenu(menuName = "Game/Item")]
public class ItemData : ScriptableObject {
    public string name;
    public int price;  // Should be >= 0
    
    private void OnValidate() {
        if (price < 0) {
            Debug.LogWarning("Price cannot be negative", this);
            price = 0;
        }
    }
}
```

### Validation Approach

**1. OnValidate Hook**
- **When:** Runs in editor whenever asset is modified
- **What:** Custom C# code to check constraints
- **Output:** Editor console warnings/errors
- **Scope:** Per-asset validation only

**2. Custom Editor Scripts**
- **Scope:** Project-wide validation runners
- **How:** EditorWindow that scans all assets and validates them
- **Advantage:** Can perform cross-asset checks (e.g., "no duplicate IDs")

**3. Odin Validator (Third-Party)**
- **Approach:** Declarative validation profiles as ScriptableObjects
- **Features:** Regex checks, custom validators, batch processing
- **Advantage:** Non-programmers can define validation rules
- **Limitation:** External dependency; adds complexity

### Design Pattern
```
Designer edits ScriptableObject asset
    ↓
OnValidate hook runs (C# code in asset class)
    ↓
Constraints checked; errors reported to editor console
    ↓
Cross-asset validation runs on demand (EditorWindow)
    ↓
Build proceeds or fails based on validation state
```

### Lessons for MMO
- **Immediate feedback is crucial:** OnValidate runs when designers change values
- **Declarative schemas are hard to use:** Most validations end up being imperative (code)
- **Cross-asset checks are non-trivial:** Require separate infrastructure
- **The gap between individual and system-wide validation is significant**

---

## 4. Godot Resource Validation (Load-Time Only)

### Background
Godot stores scenes (.tscn) and resources (.tres) in text format. These files are human-readable but must be valid Godot syntax. Example error: missing node ID, invalid resource reference.

### Validation Approach

**1. Engine Load-Time**
- **When:** File is loaded in editor or at runtime
- **What:** Godot's ResourceFormatLoaderText validates syntax and references
- **Output:** Parse errors printed to console with line numbers
- **Limitation:** No external schema validator; validation is hardcoded in C++

**2. Custom Scripts (Community Workaround)**
- **Approach:** Write Python/Rust scripts that parse .tscn/.tres files
- **Limitation:** Must re-implement the spec; Godot doesn't provide schema
- **Result:** Fragmented validation; no standard tool

**3. Headless Batch Loading**
- **Approach:** Run Godot in headless mode with a script that loads all resources
- **Integration:** Can be added to CI/CD pipeline
- **Output:** Reports any resources that fail to load

### Design Pattern
```
Scene/Resource file (.tscn / .tres)
    ↓
Designer edits in editor or CI/CD loads headless
    ↓
Godot engine parses and validates
    ↓
Load succeeds or reports errors
    ↓
(No external validator; this is it)
```

### Lessons for MMO
- **No external schema validator is a weakness:** Godot lacks a tool like Dwarf Fortress's parser
- **Late validation is expensive:** Catching errors only at load time means slower iteration
- **Headless batch checking is workable:** Can integrate into CI/CD, but requires full engine
- **We should do better than Godot:** Build an external validator

---

## 5. General Modding Community Tools

### Pattern Recognition Across Tools

All effective tools follow this pipeline:

1. **Lexer** — Tokenize input (raw → tokens)
2. **Parser** — Build tree structure (tokens → AST)
3. **Semantic Analyzer** — Validate against domain rules (AST + context → errors)
4. **Error Reporting** — Structured output (file, line, column, message, suggestion)

### Validation Strategies

**Schema-Based:**
- Define required/optional fields per entity type
- Check types, ranges, enumerations
- Example: Factorio prototype schema (required fields in each entity type)

**Cross-Reference:**
- Resolve identifiers (material → does material exist in registry?)
- Catch dangling references early
- Example: Dwarf Fortress material references in creatures

**Semantic Rules:**
- Domain-specific constraints (can't have "open" state without "closed" state)
- Mutual exclusions (can't be both portable and furniture)
- Example: Our object FSM rules (transitions must reference declared states)

**Structural:**
- Nesting rules (room can contain objects, objects can't contain rooms)
- Relationship constraints (on_top only in rooms, not in objects)
- Example: Our deep-nesting syntax

---

## 6. Technology Stack Patterns

### Rust (Dwarf Fortress, Community Ecosystem)
- **Parser Combinators:** nom, pest (parser library)
- **Advantages:** Fast, safe, performant, good error handling
- **Use Case:** Production tools, language servers

### Python (Community, Factorio)
- **Parsing Libraries:** lark, pyparsing, PLY
- **Advantages:** Quick to prototype, readable, easy to extend
- **Use Case:** Script tools, CI/CD integration, prototyping

### TypeScript/Node (Web Integration)
- **Libraries:** Babel (general AST), tree-sitter (language bindings)
- **Advantages:** Shared tooling with web build, good IDE support
- **Use Case:** Tools that integrate with web UI

### Go (General Purpose)
- **Strengths:** Fast CLI tools, easy deployment, good standard library
- **Weakness:** Fewer specialized parsing libraries
- **Use Case:** Simple validators, CI/CD tooling

---

## 7. Key Takeaways

### What Works
✅ **Lexer → Parser → Semantic Analysis** — Proven pattern across all major tools  
✅ **Real-time/Load-time feedback** — Catch errors early in development  
✅ **Cross-reference resolution** — Most bugs are broken references  
✅ **Structured error reporting** — File, line, type, suggestion  
✅ **Schema-driven validation** — Define rules once, apply everywhere  

### What Doesn't Work
❌ **Regex-based validation** — Fragile, hard to maintain, no semantic understanding  
❌ **Load-time only** — Too late in development cycle  
❌ **Ad-hoc checks** — Non-reusable, inconsistent  
❌ **No cross-reference checking** — Missing references find bugs at runtime  

### Architectural Decision
**Our meta-compiler should use the proven approach:**
1. Lexer — tokenize Lua table literals
2. Parser — build AST of object/room structure
3. Semantic Analyzer — validate per template schema + cross-references
4. Error Reporter — structured output (file, line, field, expected, actual)

This is what works. This is what the industry does. This is what we should build.

---

## References

- **Dwarf Fortress RAW Language Server:** https://gitlab.com/df-modding-tools/df-raw-language-server
- **dfraw_json_parser:** https://docs.rs/dfraw_json_parser/latest/dfraw_json_parser/
- **Factorio Prototype Docs:** https://lua-api.factorio.com/latest/types.html
- **typed-factorio (TypeScript types):** https://npm.io/package/typed-factorio
- **Unity ScriptableObject Documentation:** https://docs.unity3d.com/6000.3/Documentation/Manual/class-ScriptableObject.html
- **Godot TSCN File Format:** https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html
- **Lark Parser (Python):** https://lark-parser.readthedocs.io/en/latest/
