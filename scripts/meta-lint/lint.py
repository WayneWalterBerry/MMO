#!/usr/bin/env python3
"""
meta-check: static validator for MMO meta .lua files.

Phase 1 improvements:
  - Rule registry with metadata (severity, fixable, fix_safety)
  - Per-rule configuration via .meta-check.json
  - Smart XF-03 keyword collision filtering
  - MD-19 melting/ignition point conflict detection
  - XR-05b generic material inheritance warning

Phase 3 improvements:
  - Squad routing: violations tagged with owning squad member
  - Incremental caching: SHA-256 file hashing, skip unchanged files
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

try:
    from lark import Lark, Tree, Token
except ImportError:
    print("ERROR: lark not installed. Run: pip install lark")
    sys.exit(1)

# Rule registry & config — import via importlib (directory has hyphen)
import importlib.util as _ilu

_script_dir = Path(__file__).resolve().parent

def _load_sibling(name: str):
    spec = _ilu.spec_from_file_location(name, _script_dir / f"{name}.py")
    mod = _ilu.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

rule_registry = _load_sibling("rule_registry")
config_mod = _load_sibling("config")
squad_routing_mod = _load_sibling("squad_routing")
cache_mod = _load_sibling("cache")


# =============================================================================
# Phase 1: Lua Tokenizer (from lua_grammar.py)
# =============================================================================

LUA_KEYWORDS = frozenset({
    "function", "end", "if", "then", "else", "elseif",
    "for", "while", "do", "repeat", "until",
    "local", "return", "true", "false", "nil",
    "and", "or", "not", "in", "break",
})

BLOCK_OPENERS = frozenset({"function", "if", "for", "while"})


def tokenize(source: str) -> List[Tuple[str, str, int]]:
    tokens = []
    i = 0
    n = len(source)

    while i < n:
        m = re.match(r"\s+", source[i:])
        if m:
            tokens.append(("WS", m.group(), i))
            i += m.end()
            continue

        m = re.match(r"--\[(=*)\[.*?\]\1\]", source[i:], re.DOTALL)
        if m:
            tokens.append(("COMMENT", m.group(), i))
            i += m.end()
            continue

        if i + 1 < n and source[i:i + 2] == "--":
            end_pos = source.find("\n", i)
            if end_pos == -1:
                end_pos = n
            tokens.append(("COMMENT", source[i:end_pos], i))
            i = end_pos
            continue

        m = re.match(r"\[(=*)\[.*?\]\1\]", source[i:], re.DOTALL)
        if m:
            tokens.append(("STRING", m.group(), i))
            i += m.end()
            continue

        if source[i] in ('"', "'"):
            quote = source[i]
            j = i + 1
            while j < n:
                if source[j] == "\\" and j + 1 < n:
                    j += 2
                elif source[j] == quote:
                    j += 1
                    break
                else:
                    j += 1
            else:
                j = n
            tokens.append(("STRING", source[i:j], i))
            i = j
            continue

        m = re.match(r"0[xX][0-9a-fA-F]+", source[i:])
        if m:
            tokens.append(("NUMBER", m.group(), i))
            i += m.end()
            continue

        m = re.match(r"\d+\.?\d*([eE][+-]?\d+)?", source[i:])
        if m:
            tokens.append(("NUMBER", m.group(), i))
            i += m.end()
            continue

        m = re.match(r"[a-zA-Z_][a-zA-Z0-9_]*", source[i:])
        if m:
            word = m.group()
            tok_type = "KEYWORD" if word in LUA_KEYWORDS else "IDENT"
            tokens.append((tok_type, word, i))
            i += m.end()
            continue

        if i + 2 < n and source[i:i + 3] == "...":
            tokens.append(("PUNCT", "...", i))
            i += 3
            continue
        if i + 1 < n and source[i:i + 2] in ("==", "~=", "<=", ">=", "..", "::"):
            tokens.append(("PUNCT", source[i:i + 2], i))
            i += 2
            continue

        tokens.append(("PUNCT", source[i], i))
        i += 1

    return tokens


def strip_preamble(source: str) -> str:
    tokens = tokenize(source)
    depth = 0
    last_return_pos = None

    for tok_type, tok_val, tok_pos in tokens:
        if tok_type != "KEYWORD":
            continue
        if tok_val in BLOCK_OPENERS or tok_val == "repeat":
            depth += 1
        elif tok_val == "end" or tok_val == "until":
            depth = max(0, depth - 1)
        elif tok_val == "return" and depth == 0:
            last_return_pos = tok_pos

    if last_return_pos is not None:
        return source[last_return_pos:]
    return source


def find_matching_end(tokens, start_idx):
    depth = 0
    for i in range(start_idx, len(tokens)):
        tok_type, tok_val, _ = tokens[i]
        if tok_type != "KEYWORD":
            continue
        if tok_val in BLOCK_OPENERS or tok_val == "repeat":
            depth += 1
        elif tok_val == "end":
            depth -= 1
            if depth == 0:
                return i
        elif tok_val == "until":
            depth -= 1
            if depth == 0:
                return i
    return None


def neutralize_functions(source: str) -> str:
    tokens = tokenize(source)
    result = []
    skip_until_idx = -1
    i = 0

    def next_non_ws(idx):
        j = idx
        while j < len(tokens) and tokens[j][0] in ("WS", "COMMENT"):
            j += 1
        return j

    while i < len(tokens):
        tok_type, tok_val, _ = tokens[i]
        if i <= skip_until_idx:
            i += 1
            continue

        if tok_type in ("WS", "COMMENT"):
            i += 1
            continue

        if tok_type == "KEYWORD" and tok_val == "function":
            end_idx = find_matching_end(tokens, i)
            if end_idx is not None:
                result.append("__FUNC__")
                skip_until_idx = end_idx
                i += 1
                continue

        if tok_type == "STRING":
            j = next_non_ws(i + 1)
            while j < len(tokens) and tokens[j][0] == "PUNCT" and tokens[j][1] == "..":
                k = next_non_ws(j + 1)
                if k < len(tokens) and tokens[k][0] == "STRING":
                    j = next_non_ws(k + 1)
                else:
                    break
            result.append(tok_val)
            i = j
            continue

        result.append(tok_val)
        i += 1

    return " ".join(result)


def preprocess(source: str) -> str:
    return neutralize_functions(strip_preamble(source))


# =============================================================================
# Phase 3: Lark Grammar (from lua_grammar.py)
# =============================================================================

LUA_TABLE_GRAMMAR = r"""
    start: "return" table

    table: "{" "}"
         | "{" field_list "}"

    field_list: field ("," field)* ","?

    field: NAME "=" value          -> named_field
         | "[" value "]" "=" value -> bracket_field
         | value                   -> positional_field

    ?value: DQ_STRING              -> string_val
          | SQ_STRING              -> string_val
          | LONG_STRING            -> string_val
          | NUMBER                 -> number_val
          | "-" NUMBER             -> neg_number_val
          | "true"                 -> true_val
          | "false"                -> false_val
          | "nil"                  -> nil_val
          | table
          | "__FUNC__"             -> func_placeholder
          | NAME                   -> ident_ref

    NAME: /[a-zA-Z_][a-zA-Z0-9_]*/
    DQ_STRING: /"([^"\\]|\\.)*"/
    SQ_STRING: /'([^'\\]|\\.)*'/
    LONG_STRING: /\[(=*)\[[\s\S]*?\]\1\]/
    NUMBER: /\d+\.?\d*([eE][+-]?\d+)?/
          | /0[xX][0-9a-fA-F]+/

    %ignore /\s+/
    %ignore /--[^\n]*/
"""

parser = Lark(LUA_TABLE_GRAMMAR, parser="earley", ambiguity="resolve")


@dataclass
class LuaValue:
    kind: str
    value: object


@dataclass
class LuaTable:
    fields: Dict[str, LuaValue]
    array: List[LuaValue]


def _unquote_string(raw: str) -> str:
    if raw.startswith("["):
        m = re.match(r"\[(=*)\[(.*)\]\1\]", raw, re.DOTALL)
        return m.group(2) if m else raw
    if raw.startswith(("'", '"')):
        try:
            return ast_literal_eval(raw)
        except Exception:
            return raw[1:-1]
    return raw


def ast_literal_eval(value: str) -> str:
    import ast
    return ast.literal_eval(value)


def _parse_number(raw: str) -> float:
    if raw.lower().startswith("0x"):
        return int(raw, 16)
    if "." in raw or "e" in raw.lower():
        return float(raw)
    return int(raw)


def _tree_to_value(node) -> LuaValue:
    if isinstance(node, Token):
        return LuaValue("token", str(node))
    if not isinstance(node, Tree):
        return LuaValue("unknown", node)

    if node.data == "string_val":
        return LuaValue("string", _unquote_string(str(node.children[0])))
    if node.data == "number_val":
        return LuaValue("number", _parse_number(str(node.children[0])))
    if node.data == "neg_number_val":
        return LuaValue("number", -_parse_number(str(node.children[0])))
    if node.data == "true_val":
        return LuaValue("boolean", True)
    if node.data == "false_val":
        return LuaValue("boolean", False)
    if node.data == "nil_val":
        return LuaValue("nil", None)
    if node.data == "func_placeholder":
        return LuaValue("function", "__FUNC__")
    if node.data == "ident_ref":
        return LuaValue("ident", str(node.children[0]))
    if node.data == "table":
        return LuaValue("table", _parse_table(node))

    return LuaValue("unknown", node.data)


def _parse_table(node: Tree) -> LuaTable:
    fields: Dict[str, LuaValue] = {}
    array: List[LuaValue] = []

    for child in node.children:
        if not isinstance(child, Tree) or child.data != "field_list":
            continue
        for field in child.children:
            if not isinstance(field, Tree):
                continue
            if field.data == "named_field":
                name_token = field.children[0]
                name = str(name_token)
                value = _tree_to_value(field.children[1])
                fields[name] = value
            elif field.data == "bracket_field":
                key_value = _tree_to_value(field.children[0])
                value = _tree_to_value(field.children[1])
                key = str(key_value.value) if key_value.kind in ("string", "number", "ident") else str(key_value.value)
                fields[key] = value
            elif field.data == "positional_field":
                array.append(_tree_to_value(field.children[0]))

    return LuaTable(fields=fields, array=array)


# =============================================================================
# Utilities
# =============================================================================

GUID_RE_BRACED = re.compile(r"^\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}$")
GUID_RE_BARE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

# Category keywords that legitimately appear across multiple objects.
# These are broad classifiers, not unique identifiers.
CATEGORY_KEYWORDS = frozenset({
    "garment", "clothing", "weapon", "armor", "container", "tool",
    "furniture", "light source", "food", "drink", "key", "potion",
    "consumable", "fixture", "decoration", "wearable",
})

KNOWN_INJURY_CATEGORIES = {"physical", "environmental", "toxin", "unconsciousness"}
KNOWN_DAMAGE_TYPES = {"over_time", "one_time"}
KNOWN_RESTRICT_ACTIONS = {"climb", "run", "jump", "fight", "grip", "focus"}
KNOWN_INJURY_FIELDS = {
    "guid", "id", "name", "category", "description", "damage_type",
    "initial_state", "on_inflict", "states", "transitions",
    "healing_interactions", "causes_unconsciousness", "unconscious_duration",
}
KNOWN_MATERIAL_FIELDS = {
    "guid", "name", "density", "melting_point", "ignition_point", "hardness",
    "flexibility", "absorbency", "opacity", "flammability", "conductivity",
    "fragility", "value", "rust_susceptibility",
}
FERROUS_MATERIALS = {"iron", "steel"}
METAL_MATERIALS = {"iron", "steel", "brass", "silver", "copper", "gold", "tin", "lead", "bronze"}


def _build_line_index(source: str) -> List[int]:
    starts = [0]
    for match in re.finditer(r"\n", source):
        starts.append(match.end())
    return starts


def _pos_to_line_col(pos: int, line_starts: List[int]) -> Tuple[int, int]:
    line = 1
    for i, start in enumerate(line_starts):
        if start > pos:
            break
        line = i + 1
    col = pos - line_starts[line - 1] + 1
    return line, col


def _top_level_field_positions(source: str) -> Dict[str, Tuple[int, int]]:
    tokens = tokenize(source)
    line_starts = _build_line_index(source)

    depth = 0
    found_return = False
    last_return_pos = None
    for tok_type, tok_val, tok_pos in tokens:
        if tok_type != "KEYWORD":
            continue
        if tok_val in BLOCK_OPENERS or tok_val == "repeat":
            depth += 1
        elif tok_val == "end" or tok_val == "until":
            depth = max(0, depth - 1)
        elif tok_val == "return" and depth == 0:
            last_return_pos = tok_pos

    if last_return_pos is None:
        return {}

    positions: Dict[str, Tuple[int, int]] = {}
    i = 0
    while i < len(tokens):
        tok_type, tok_val, tok_pos = tokens[i]
        if tok_pos < last_return_pos:
            i += 1
            continue
        if tok_type == "PUNCT" and tok_val == "{":
            found_return = True
            depth = 1
            i += 1
            break
        i += 1

    if not found_return:
        return positions

    def next_non_ws(idx):
        j = idx + 1
        while j < len(tokens) and tokens[j][0] in ("WS", "COMMENT"):
            j += 1
        return j

    while i < len(tokens) and depth > 0:
        tok_type, tok_val, tok_pos = tokens[i]
        if tok_type == "PUNCT" and tok_val == "{":
            depth += 1
        elif tok_type == "PUNCT" and tok_val == "}":
            depth -= 1
        elif depth == 1 and tok_type == "IDENT":
            j = next_non_ws(i)
            if j < len(tokens) and tokens[j][1] == "=":
                if tok_val not in positions:
                    positions[tok_val] = _pos_to_line_col(tok_pos, line_starts)
        i += 1

    return positions


def _value_kind(value: Optional[LuaValue]) -> Optional[str]:
    return value.kind if isinstance(value, LuaValue) else None


def _as_string(value: Optional[LuaValue]) -> Optional[str]:
    return value.value if isinstance(value, LuaValue) and value.kind == "string" else None


def _as_table(value: Optional[LuaValue]) -> Optional[LuaTable]:
    return value.value if isinstance(value, LuaValue) and value.kind == "table" else None


# =============================================================================
# Validation
# =============================================================================

SEVERITY_ORDER = {"error": 3, "warning": 2, "info": 1}


@dataclass
class Violation:
    file: str
    line: int
    severity: str
    rule_id: str
    message: str
    fixable: bool = False
    fix_safety: str = "unsafe"
    owner: str = "unassigned"


@dataclass
class ParsedFile:
    path: Path
    fields: Dict[str, LuaValue]
    positions: Dict[str, Tuple[int, int]]
    template: Optional[str]
    kind: str
    guid: Optional[str]
    keywords: List[str]
    material: Optional[str]


def _detect_kind(path: Path) -> str:
    lower = str(path).lower()
    if os.sep + "src" + os.sep + "meta" + os.sep + "objects" + os.sep in lower:
        return "object"
    if os.sep + "src" + os.sep + "meta" + os.sep + "creatures" + os.sep in lower:
        return "creature"
    if os.sep + "src" + os.sep + "meta" + os.sep + "world" + os.sep in lower:
        return "room"
    if os.sep + "src" + os.sep + "meta" + os.sep + "rooms" + os.sep in lower:
        return "room"
    if os.sep + "src" + os.sep + "meta" + os.sep + "levels" + os.sep in lower:
        return "level"
    if os.sep + "src" + os.sep + "meta" + os.sep + "templates" + os.sep in lower:
        return "template"
    if os.sep + "src" + os.sep + "meta" + os.sep + "injuries" + os.sep in lower:
        return "injury"
    if os.sep + "src" + os.sep + "meta" + os.sep + "materials" + os.sep in lower:
        return "material"
    return "unknown"


def _parse_file(path: Path, violations: List[Violation]) -> Optional[ParsedFile]:
    source = path.read_text(encoding="utf-8")
    positions = _top_level_field_positions(source)
    preprocessed = preprocess(source)

    try:
        tree = parser.parse(preprocessed)
    except Exception as exc:
        violations.append(Violation(
            file=str(path),
            line=1,
            severity="error",
            rule_id="PARSE-01",
            message=f"Parse error: {exc}",
        ))
        return None

    top_table = None
    for child in tree.children:
        if isinstance(child, Tree) and child.data == "table":
            top_table = _parse_table(child)
            break

    if top_table is None:
        violations.append(Violation(
            file=str(path),
            line=1,
            severity="error",
            rule_id="S-01",
            message="File must return a table",
        ))
        return None

    fields = top_table.fields
    template = _as_string(fields.get("template"))
    guid = _as_string(fields.get("guid"))
    material = _as_string(fields.get("material"))

    keywords: List[str] = []
    keywords_value = fields.get("keywords")
    keywords_table = _as_table(keywords_value)
    if keywords_table is not None:
        for entry in keywords_table.array:
            if entry.kind == "string":
                keywords.append(entry.value)

    return ParsedFile(
        path=path,
        fields=fields,
        positions=positions,
        template=template,
        kind=_detect_kind(path),
        guid=guid,
        keywords=keywords,
        material=material,
    )


# Config reference — set by main() before validation runs
_active_config: config_mod.CheckConfig = config_mod.CheckConfig()
_squad_router: squad_routing_mod.SquadRouter = squad_routing_mod.SquadRouter()


def _add_violation(violations: List[Violation], path: Path, line: int, severity: str, rule_id: str, message: str) -> None:
    if not _active_config.is_rule_enabled(rule_id):
        return
    rc = _active_config.rules.get(rule_id)
    if rc is not None and rc.severity is not None:
        severity = rc.severity
    meta = rule_registry.get_rule(rule_id)
    fixable = meta.fixable if meta else False
    fix_safety = meta.fix_safety if meta else "unsafe"
    owner = _squad_router.owner_for(rule_id)
    violations.append(Violation(
        file=str(path), line=line, severity=severity, rule_id=rule_id,
        message=message, fixable=fixable, fix_safety=fix_safety, owner=owner,
    ))


def _line_for(parsed: ParsedFile, field: str, fallback: int = 1) -> int:
    pos = parsed.positions.get(field)
    return pos[0] if pos else fallback


# =============================================================================
# V2 Validators: Template, Injury, Material, Level
# =============================================================================


def _validate_template(parsed: ParsedFile, violations: List[Violation]) -> None:
    path = parsed.path
    fields = parsed.fields
    file_id = path.stem

    # TD-02: guid exists and valid (bare format for templates)
    if parsed.guid is None:
        _add_violation(violations, path, 1, "error", "TD-02", "Template missing guid")
    elif not GUID_RE_BARE.match(parsed.guid):
        _add_violation(violations, path, _line_for(parsed, "guid"), "error", "TD-02",
                       f"Template guid must be bare format (no braces), got '{parsed.guid}'")

    # TD-03: id exists
    obj_id = _as_string(fields.get("id"))
    if obj_id is None:
        _add_violation(violations, path, 1, "error", "TD-03", "Template missing id")
    else:
        # TD-04: id matches filename
        if obj_id != file_id:
            _add_violation(violations, path, _line_for(parsed, "id"), "error", "TD-04",
                           f"Template id '{obj_id}' must match filename '{file_id}'")

    # TD-05: name exists
    if _as_string(fields.get("name")) is None:
        _add_violation(violations, path, 1, "error", "TD-05", "Template missing name")

    # TD-06: keywords is a table
    kw = fields.get("keywords")
    if kw is None:
        _add_violation(violations, path, 1, "error", "TD-06", "Template missing keywords table")
    elif _as_table(kw) is None:
        _add_violation(violations, path, _line_for(parsed, "keywords"), "error", "TD-06",
                       "keywords must be a table")

    # TD-07: description exists
    if _as_string(fields.get("description")) is None:
        _add_violation(violations, path, 1, "error", "TD-07", "Template missing description")

    # TD-08: mutations is a table (WARNING)
    mut = fields.get("mutations")
    if mut is None:
        _add_violation(violations, path, 1, "warning", "TD-08",
                       "Template should declare mutations (even if empty)")
    elif _as_table(mut) is None:
        _add_violation(violations, path, _line_for(parsed, "mutations"), "warning", "TD-08",
                       "mutations should be a table")

    # TD-09: No template field on templates
    if fields.get("template") is not None:
        _add_violation(violations, path, _line_for(parsed, "template"), "error", "TD-09",
                       "Templates must NOT have a template field")

    is_physical = file_id in ("container", "furniture", "small-item", "sheet")
    is_room = file_id == "room"

    # Physical template checks (TD-11 through TD-20)
    if is_physical:
        # TD-11: size > 0
        size_v = fields.get("size")
        if size_v is None or _value_kind(size_v) != "number":
            _add_violation(violations, path, _line_for(parsed, "size") or 1, "error", "TD-11",
                           "Physical template must declare size as a positive number")
        elif size_v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, "size"), "error", "TD-11",
                           "size must be > 0")

        # TD-12: weight > 0
        weight_v = fields.get("weight")
        if weight_v is None or _value_kind(weight_v) != "number":
            _add_violation(violations, path, _line_for(parsed, "weight") or 1, "error", "TD-12",
                           "Physical template must declare weight as a positive number")
        elif weight_v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, "weight"), "error", "TD-12",
                           "weight must be > 0")

        # TD-13: portable is boolean
        portable_v = fields.get("portable")
        if portable_v is None or _value_kind(portable_v) != "boolean":
            _add_violation(violations, path, _line_for(parsed, "portable") or 1, "error", "TD-13",
                           "Physical template must declare portable as boolean")

        # TD-14: material is a string
        mat_v = fields.get("material")
        if mat_v is None or _value_kind(mat_v) != "string":
            _add_violation(violations, path, _line_for(parsed, "material") or 1, "error", "TD-14",
                           "Physical template must declare material as a string")

        # TD-15: container is boolean
        cont_v = fields.get("container")
        if cont_v is None or _value_kind(cont_v) != "boolean":
            _add_violation(violations, path, _line_for(parsed, "container") or 1, "error", "TD-15",
                           "Physical template must declare container as boolean")

        # TD-16: capacity >= 0
        cap_v = fields.get("capacity")
        if cap_v is None or _value_kind(cap_v) != "number":
            _add_violation(violations, path, _line_for(parsed, "capacity") or 1, "error", "TD-16",
                           "Physical template must declare capacity as a non-negative number")
        elif cap_v.value < 0:
            _add_violation(violations, path, _line_for(parsed, "capacity"), "error", "TD-16",
                           "capacity must be >= 0")

        # TD-17: contents is a table
        contents_v = fields.get("contents")
        if contents_v is None:
            _add_violation(violations, path, 1, "error", "TD-17",
                           "Physical template must declare contents")
        elif _as_table(contents_v) is None:
            _add_violation(violations, path, _line_for(parsed, "contents"), "error", "TD-17",
                           "contents must be a table")
        else:
            # TD-18: contents should be empty
            ct = _as_table(contents_v)
            if len(ct.fields) > 0 or len(ct.array) > 0:
                _add_violation(violations, path, _line_for(parsed, "contents"), "warning", "TD-18",
                               "Template contents should be empty")

        # TD-19: location declared (INFO)
        if fields.get("location") is None:
            _add_violation(violations, path, 1, "info", "TD-19",
                           "Physical template should declare location = nil for structural clarity")

        # TD-20: categories is a table of strings (WARNING)
        cat_v = fields.get("categories")
        if cat_v is not None:
            cat_t = _as_table(cat_v)
            if cat_t is None:
                _add_violation(violations, path, _line_for(parsed, "categories"), "warning",
                               "TD-20", "categories must be a table of strings")
            else:
                for entry in cat_t.array:
                    if entry.kind != "string":
                        _add_violation(violations, path, _line_for(parsed, "categories"),
                                       "warning", "TD-20", "categories entries must be strings")
                        break

    # Container-specific (TD-21 through TD-23)
    if file_id == "container":
        cont_v = fields.get("container")
        if cont_v is not None and _value_kind(cont_v) == "boolean" and cont_v.value is not True:
            _add_violation(violations, path, _line_for(parsed, "container"), "error", "TD-21",
                           "Container template must have container = true")

        cap_v = fields.get("capacity")
        if cap_v is not None and _value_kind(cap_v) == "number" and cap_v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, "capacity"), "error", "TD-22",
                           "Container template must have capacity > 0")

        wc_v = fields.get("weight_capacity")
        if wc_v is None:
            _add_violation(violations, path, 1, "warning", "TD-23",
                           "Container template should declare weight_capacity > 0")
        elif _value_kind(wc_v) == "number" and wc_v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, "weight_capacity"), "warning",
                           "TD-23", "weight_capacity should be > 0")

    # Room template specifics (TD-24 through TD-26)
    if is_room:
        # TD-24: No physical properties
        phys_fields = ["size", "weight", "portable", "material", "capacity", "container"]
        for pf in phys_fields:
            pv = fields.get(pf)
            if pv is not None and pv.kind != "nil":
                _add_violation(violations, path, _line_for(parsed, pf), "error", "TD-24",
                               f"Room template must NOT declare '{pf}'")

        # TD-25: contents is a table
        contents_v = fields.get("contents")
        if contents_v is None:
            _add_violation(violations, path, 1, "error", "TD-25",
                           "Room template must declare contents")
        elif _as_table(contents_v) is None:
            _add_violation(violations, path, _line_for(parsed, "contents"), "error", "TD-25",
                           "contents must be a table")

        # TD-26: exits is a table
        exits_v = fields.get("exits")
        if exits_v is None:
            _add_violation(violations, path, 1, "error", "TD-26",
                           "Room template must declare exits")
        elif _as_table(exits_v) is None:
            _add_violation(violations, path, _line_for(parsed, "exits"), "error", "TD-26",
                           "exits must be a table")

    # Sheet-specific (TD-27)
    if file_id == "sheet":
        mat_v = fields.get("material")
        if mat_v is not None and _value_kind(mat_v) == "string":
            fabric_materials = {"fabric", "wool", "cotton", "linen", "velvet", "burlap", "hemp"}
            if mat_v.value not in fabric_materials:
                _add_violation(violations, path, _line_for(parsed, "material"), "warning", "TD-27",
                               f"Sheet template material '{mat_v.value}' should be fabric-class")


def _validate_injury(parsed: ParsedFile, violations: List[Violation]) -> None:
    path = parsed.path
    fields = parsed.fields
    file_id = path.stem

    # INJ-02: guid exists and valid (braced format)
    if parsed.guid is None:
        _add_violation(violations, path, 1, "error", "INJ-02", "Injury missing guid")
    elif not GUID_RE_BRACED.match(parsed.guid):
        _add_violation(violations, path, _line_for(parsed, "guid"), "error", "INJ-02",
                       f"Injury guid must be braced format, got '{parsed.guid}'")

    # INJ-03: id exists
    obj_id = _as_string(fields.get("id"))
    if obj_id is None:
        _add_violation(violations, path, 1, "error", "INJ-03", "Injury missing id")
    else:
        # INJ-04: id matches filename
        if obj_id != file_id:
            _add_violation(violations, path, _line_for(parsed, "id"), "error", "INJ-04",
                           f"Injury id '{obj_id}' must match filename '{file_id}'")

    # INJ-05: name
    if _as_string(fields.get("name")) is None:
        _add_violation(violations, path, 1, "error", "INJ-05", "Injury missing name")

    # INJ-06, INJ-07: category
    cat = _as_string(fields.get("category"))
    if cat is None:
        _add_violation(violations, path, 1, "error", "INJ-06", "Injury missing category")
    elif cat not in KNOWN_INJURY_CATEGORIES:
        _add_violation(violations, path, _line_for(parsed, "category"), "warning", "INJ-07",
                       f"Unknown injury category '{cat}'")

    # INJ-08: description
    if _as_string(fields.get("description")) is None:
        _add_violation(violations, path, 1, "error", "INJ-08", "Injury missing description")

    # INJ-10: No template field (INFO)
    if fields.get("template") is not None:
        _add_violation(violations, path, _line_for(parsed, "template"), "info", "INJ-10",
                       "Injuries should not have a template field")

    # INJ-11, INJ-12: damage_type
    dt = _as_string(fields.get("damage_type"))
    if dt is None:
        _add_violation(violations, path, 1, "error", "INJ-11", "Injury missing damage_type")
    elif dt not in KNOWN_DAMAGE_TYPES:
        _add_violation(violations, path, _line_for(parsed, "damage_type"), "error", "INJ-12",
                       f"Unknown damage_type '{dt}'")

    # INJ-13: initial_state
    initial_state = _as_string(fields.get("initial_state"))
    if initial_state is None:
        _add_violation(violations, path, 1, "error", "INJ-13", "Injury missing initial_state")

    # INJ-20: states exists and is table
    states_v = fields.get("states")
    states_t = _as_table(states_v)
    state_keys: set = set()
    terminal_states: set = set()

    if states_v is None:
        _add_violation(violations, path, 1, "error", "INJ-20", "Injury missing states")
    elif states_t is None:
        _add_violation(violations, path, _line_for(parsed, "states"), "error", "INJ-20",
                       "states must be a table")
    else:
        state_keys = set(states_t.fields.keys())

        # INJ-14: initial_state references defined state
        if initial_state is not None and initial_state not in state_keys:
            _add_violation(violations, path, _line_for(parsed, "initial_state"), "error", "INJ-14",
                           f"initial_state '{initial_state}' not in states")

        # INJ-21: At least 2 states
        if len(state_keys) < 2:
            _add_violation(violations, path, _line_for(parsed, "states"), "error", "INJ-21",
                           "Injury must have at least 2 states")

        has_terminal = False
        has_positive_terminal = False

        for state_name, state_val in states_t.fields.items():
            st = _as_table(state_val)
            if st is None:
                continue
            sf = st.fields

            # Determine if terminal
            term_v = sf.get("terminal")
            is_terminal = (term_v is not None and _value_kind(term_v) == "boolean"
                           and term_v.value is True)
            if is_terminal:
                terminal_states.add(state_name)
                has_terminal = True
                sn = _as_string(sf.get("name"))
                if sn and ("healed" in sn.lower() or "recovered" in sn.lower()
                           or "neutralized" in sn.lower()):
                    has_positive_terminal = True

            # INJ-26: States named healed/fatal should declare terminal = true
            if not is_terminal and state_name in ("healed", "fatal"):
                _add_violation(violations, path, _line_for(parsed, "states"), "error",
                               "INJ-26",
                               f"State '{state_name}' should declare terminal = true")

            # INJ-22: state has name
            if _as_string(sf.get("name")) is None:
                _add_violation(violations, path, _line_for(parsed, "states"), "error", "INJ-22",
                               f"State '{state_name}' missing name")

            # INJ-23: state has description
            if _as_string(sf.get("description")) is None:
                _add_violation(violations, path, _line_for(parsed, "states"), "error", "INJ-23",
                               f"State '{state_name}' missing description")

            if not is_terminal:
                # INJ-24: non-terminal on_feel
                if sf.get("on_feel") is None:
                    _add_violation(violations, path, _line_for(parsed, "states"), "error",
                                   "INJ-24",
                                   f"Non-terminal state '{state_name}' missing on_feel")

                # INJ-25: non-terminal damage_per_tick
                if sf.get("damage_per_tick") is None:
                    _add_violation(violations, path, _line_for(parsed, "states"), "error",
                                   "INJ-25",
                                   f"Non-terminal state '{state_name}' missing damage_per_tick")

                # INJ-32: on_look recommended (INFO)
                if sf.get("on_look") is None:
                    _add_violation(violations, path, _line_for(parsed, "states"), "info",
                                   "INJ-32",
                                   f"Non-terminal state '{state_name}' should have on_look")

                # INJ-33: on_smell for bleeding/infected states (INFO)
                sn = _as_string(sf.get("name"))
                if sn and ("bleeding" in sn.lower() or "infected" in sn.lower()):
                    if sf.get("on_smell") is None:
                        _add_violation(violations, path, _line_for(parsed, "states"), "info",
                                       "INJ-33",
                                       f"State '{state_name}' (bleeding/infected) should have "
                                       "on_smell")

                # INJ-34 through INJ-40: timed_events
                te_v = sf.get("timed_events")
                if te_v is not None:
                    te_t = _as_table(te_v)
                    if te_t is None:
                        _add_violation(violations, path, _line_for(parsed, "states"), "error",
                                       "INJ-34",
                                       f"State '{state_name}' timed_events must be a table")
                    else:
                        transition_count = 0
                        for te in te_t.array:
                            if te.kind != "table":
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-34",
                                               f"State '{state_name}' timed_events entries "
                                               "must be tables")
                                break
                            te_f = te.value.fields

                            ev_str = _as_string(te_f.get("event"))
                            if ev_str is None:
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-35",
                                               f"State '{state_name}' timed event missing "
                                               "'event' field")
                            elif ev_str == "transition":
                                transition_count += 1

                            delay_v = te_f.get("delay")
                            if delay_v is None or _value_kind(delay_v) != "number":
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-36",
                                               f"State '{state_name}' timed event missing "
                                               "positive delay")
                            elif delay_v.value <= 0:
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-36",
                                               f"State '{state_name}' timed event delay "
                                               "must be positive")
                            else:
                                if delay_v.value < 360 or delay_v.value > 10800:
                                    _add_violation(violations, path,
                                                   _line_for(parsed, "states"),
                                                   "warning", "INJ-39",
                                                   f"State '{state_name}' timed event delay "
                                                   f"{delay_v.value} outside range (360-10800)")

                            ts = _as_string(te_f.get("to_state"))
                            if ts is None:
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-37",
                                               f"State '{state_name}' timed event missing "
                                               "to_state")
                            elif ts not in state_keys:
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-38",
                                               f"State '{state_name}' timed event to_state "
                                               f"'{ts}' not in states")

                        if transition_count > 1:
                            _add_violation(violations, path, _line_for(parsed, "states"),
                                           "warning", "INJ-40",
                                           f"State '{state_name}' has {transition_count} "
                                           "transition timed events")

                # INJ-41 through INJ-43: restricts
                res_v = sf.get("restricts")
                if res_v is not None:
                    res_t = _as_table(res_v)
                    if res_t is None:
                        _add_violation(violations, path, _line_for(parsed, "states"), "error",
                                       "INJ-41",
                                       f"State '{state_name}' restricts must be a table")
                    else:
                        for rk, rv in res_t.fields.items():
                            if _value_kind(rv) != "boolean" or rv.value is not True:
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "error", "INJ-42",
                                               f"State '{state_name}' restricts.{rk} "
                                               "must be true")
                            if rk not in KNOWN_RESTRICT_ACTIONS:
                                _add_violation(violations, path, _line_for(parsed, "states"),
                                               "warning", "INJ-43",
                                               f"State '{state_name}' unknown restrict "
                                               f"action '{rk}'")

            else:
                # Terminal state checks
                # INJ-29: no damage_per_tick > 0
                dpt_v = sf.get("damage_per_tick")
                if (dpt_v is not None and _value_kind(dpt_v) == "number"
                        and dpt_v.value > 0):
                    _add_violation(violations, path, _line_for(parsed, "states"), "warning",
                                   "INJ-29",
                                   f"Terminal state '{state_name}' should not have "
                                   "damage_per_tick > 0")

                # INJ-30: no timed_events
                if sf.get("timed_events") is not None:
                    _add_violation(violations, path, _line_for(parsed, "states"), "warning",
                                   "INJ-30",
                                   f"Terminal state '{state_name}' should not have timed_events")

                # INJ-31: no restricts
                if sf.get("restricts") is not None:
                    _add_violation(violations, path, _line_for(parsed, "states"), "warning",
                                   "INJ-31",
                                   f"Terminal state '{state_name}' should not have restricts")

        # INJ-27: at least one terminal
        if not has_terminal:
            _add_violation(violations, path, _line_for(parsed, "states"), "error", "INJ-27",
                           "Injury must have at least one terminal state")

        # INJ-28: positive terminal
        if has_terminal and not has_positive_terminal:
            _add_violation(violations, path, _line_for(parsed, "states"), "warning", "INJ-28",
                           "All terminal states are fatal; consider adding a healed terminal")

    # INJ-15 through INJ-19: on_inflict
    oi_v = fields.get("on_inflict")
    if oi_v is None:
        _add_violation(violations, path, 1, "error", "INJ-15", "Injury missing on_inflict")
    else:
        oi_t = _as_table(oi_v)
        if oi_t is None:
            _add_violation(violations, path, _line_for(parsed, "on_inflict"), "error", "INJ-15",
                           "on_inflict must be a table")
        else:
            id_v = oi_t.fields.get("initial_damage")
            if id_v is None or _value_kind(id_v) != "number":
                _add_violation(violations, path, _line_for(parsed, "on_inflict"), "error",
                               "INJ-16",
                               "on_inflict.initial_damage must be a non-negative number")
            elif id_v.value < 0:
                _add_violation(violations, path, _line_for(parsed, "on_inflict"), "error",
                               "INJ-16", "on_inflict.initial_damage must be >= 0")

            dpt_v = oi_t.fields.get("damage_per_tick")
            if dpt_v is None or _value_kind(dpt_v) != "number":
                _add_violation(violations, path, _line_for(parsed, "on_inflict"), "error",
                               "INJ-17",
                               "on_inflict.damage_per_tick must be a non-negative number")
            elif dpt_v.value < 0:
                _add_violation(violations, path, _line_for(parsed, "on_inflict"), "error",
                               "INJ-17", "on_inflict.damage_per_tick must be >= 0")
            else:
                if dt == "over_time" and dpt_v.value == 0:
                    _add_violation(violations, path, _line_for(parsed, "on_inflict"), "warning",
                                   "INJ-19",
                                   "damage_type is 'over_time' but "
                                   "on_inflict.damage_per_tick is 0")
                if dt == "one_time" and dpt_v.value > 0:
                    _add_violation(violations, path, _line_for(parsed, "on_inflict"), "warning",
                                   "INJ-19",
                                   "damage_type is 'one_time' but "
                                   "on_inflict.damage_per_tick > 0")

            if _as_string(oi_t.fields.get("message")) is None:
                _add_violation(violations, path, _line_for(parsed, "on_inflict"), "error",
                               "INJ-18", "on_inflict.message must be a non-empty string")

    # INJ-44 through INJ-57: transitions
    trans_v = fields.get("transitions")
    if trans_v is not None:
        trans_t = _as_table(trans_v)
        if trans_t is None:
            _add_violation(violations, path, _line_for(parsed, "transitions"), "error", "INJ-44",
                           "transitions must be a table")
        else:
            from_verb_pairs: dict = {}
            for t_entry in trans_t.array:
                if t_entry.kind != "table":
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-44", "transitions entries must be tables")
                    break
                t_fields = t_entry.value.fields

                from_s = _as_string(t_fields.get("from"))
                to_s = _as_string(t_fields.get("to"))
                trigger = _as_string(t_fields.get("trigger"))
                verb = _as_string(t_fields.get("verb"))

                # INJ-45: from
                if from_s is None:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-45", "Transition missing 'from'")
                elif state_keys and from_s not in state_keys:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-47",
                                   f"Transition from '{from_s}' not in states")
                elif from_s in terminal_states:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-53",
                                   f"Transition from terminal state '{from_s}'")

                # INJ-46: to
                if to_s is None:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-46", "Transition missing 'to'")
                elif state_keys and to_s not in state_keys:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-48",
                                   f"Transition to '{to_s}' not in states")

                # INJ-49: non-auto must have verb
                if trigger != "auto" and verb is None:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-49",
                                   f"Non-auto transition from '{from_s}' missing verb")

                # INJ-50: trigger must be "auto" if present
                trigger_v = t_fields.get("trigger")
                if (trigger_v is not None and _as_string(trigger_v) is not None
                        and _as_string(trigger_v) != "auto"):
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-50",
                                   f"Transition trigger must be 'auto', "
                                   f"got '{_as_string(trigger_v)}'")

                # INJ-51: auto should have condition (WARNING)
                if trigger == "auto":
                    if _as_string(t_fields.get("condition")) is None:
                        _add_violation(violations, path, _line_for(parsed, "transitions"),
                                       "warning", "INJ-51",
                                       f"Auto transition from '{from_s}' should have condition")

                # INJ-52: message
                if _as_string(t_fields.get("message")) is None:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-52",
                                   f"Transition from '{from_s}' to '{to_s}' missing message")

                # INJ-54: duplicate from+verb pairs
                if trigger != "auto" and from_s and verb:
                    ric = _as_string(t_fields.get("requires_item_cures"))
                    pair_key = (from_s, verb)
                    if pair_key in from_verb_pairs:
                        if ric == from_verb_pairs[pair_key]:
                            _add_violation(violations, path,
                                           _line_for(parsed, "transitions"),
                                           "warning", "INJ-54",
                                           f"Duplicate transition from '{from_s}' "
                                           f"with verb '{verb}'")
                    else:
                        from_verb_pairs[pair_key] = ric

                # INJ-55: requires_item_cures is string if present
                ric_v = t_fields.get("requires_item_cures")
                if ric_v is not None and _value_kind(ric_v) != "string":
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error",
                                   "INJ-55", "requires_item_cures must be a string")

                # INJ-56: mutate is table if present
                mut_v = t_fields.get("mutate")
                if mut_v is not None:
                    mut_t = _as_table(mut_v)
                    if mut_t is None:
                        _add_violation(violations, path, _line_for(parsed, "transitions"),
                                       "error", "INJ-56", "mutate must be a table")
                    else:
                        # INJ-57: mutate.damage_per_tick >= 0
                        mut_dpt = mut_t.fields.get("damage_per_tick")
                        if (mut_dpt is not None and _value_kind(mut_dpt) == "number"
                                and mut_dpt.value < 0):
                            _add_violation(violations, path,
                                           _line_for(parsed, "transitions"),
                                           "warning", "INJ-57",
                                           "mutate.damage_per_tick should be >= 0")

    # INJ-58 through INJ-65: healing_interactions
    hi_v = fields.get("healing_interactions")
    if hi_v is None:
        _add_violation(violations, path, 1, "error", "INJ-58",
                       "Injury missing healing_interactions")
    else:
        hi_t = _as_table(hi_v)
        if hi_t is None:
            _add_violation(violations, path, _line_for(parsed, "healing_interactions"), "error",
                           "INJ-59", "healing_interactions must be a table")
        else:
            for item_id, hi_entry in hi_t.fields.items():
                hi_et = _as_table(hi_entry)
                if hi_et is None:
                    continue

                tt = _as_string(hi_et.fields.get("transitions_to"))
                if tt is None:
                    _add_violation(violations, path,
                                   _line_for(parsed, "healing_interactions"),
                                   "error", "INJ-60",
                                   f"healing_interactions['{item_id}'] missing transitions_to")
                elif state_keys and tt not in state_keys:
                    _add_violation(violations, path,
                                   _line_for(parsed, "healing_interactions"),
                                   "error", "INJ-61",
                                   f"healing_interactions['{item_id}'].transitions_to "
                                   f"'{tt}' not in states")

                fs_v = hi_et.fields.get("from_states")
                if fs_v is None:
                    _add_violation(violations, path,
                                   _line_for(parsed, "healing_interactions"),
                                   "error", "INJ-62",
                                   f"healing_interactions['{item_id}'] missing from_states")
                else:
                    fs_t = _as_table(fs_v)
                    if fs_t is None:
                        _add_violation(violations, path,
                                       _line_for(parsed, "healing_interactions"),
                                       "error", "INJ-62",
                                       f"healing_interactions['{item_id}'].from_states "
                                       "must be a table")
                    else:
                        for fs_entry in fs_t.array:
                            fs_name = _as_string(fs_entry)
                            if fs_name is None:
                                continue
                            if state_keys and fs_name not in state_keys:
                                _add_violation(violations, path,
                                               _line_for(parsed, "healing_interactions"),
                                               "error", "INJ-63",
                                               f"healing_interactions['{item_id}'] "
                                               f"from_state '{fs_name}' not in states")
                            elif fs_name in terminal_states:
                                _add_violation(violations, path,
                                               _line_for(parsed, "healing_interactions"),
                                               "warning", "INJ-64",
                                               f"healing_interactions['{item_id}'] "
                                               f"from_state '{fs_name}' is terminal")

    # INJ-66: causes_unconsciousness is boolean if present
    cu_v = fields.get("causes_unconsciousness")
    if cu_v is not None and _value_kind(cu_v) != "boolean":
        _add_violation(violations, path, _line_for(parsed, "causes_unconsciousness"), "error",
                       "INJ-66", "causes_unconsciousness must be boolean")

    # INJ-67/68: unconscious_duration
    ud_v = fields.get("unconscious_duration")
    if ud_v is not None:
        ud_t = _as_table(ud_v)
        if ud_t is None:
            _add_violation(violations, path, _line_for(parsed, "unconscious_duration"), "error",
                           "INJ-67", "unconscious_duration must be a table")
        else:
            for k, v in ud_t.fields.items():
                if _value_kind(v) != "number" or v.value <= 0:
                    _add_violation(violations, path,
                                   _line_for(parsed, "unconscious_duration"),
                                   "error", "INJ-67",
                                   f"unconscious_duration.{k} must be a positive number")

        if cu_v is None or _value_kind(cu_v) != "boolean" or cu_v.value is not True:
            _add_violation(violations, path, _line_for(parsed, "unconscious_duration"), "error",
                           "INJ-68",
                           "unconscious_duration requires causes_unconsciousness = true")

    # INJ-69: unknown top-level fields (INFO)
    for field_name in fields:
        if field_name not in KNOWN_INJURY_FIELDS:
            _add_violation(violations, path, _line_for(parsed, field_name), "info", "INJ-69",
                           f"Unknown top-level field '{field_name}'")


def _validate_material(parsed: ParsedFile, violations: List[Violation]) -> None:
    path = parsed.path
    fields = parsed.fields
    file_id = path.stem

    # MD-02: name exists as string
    mat_name = _as_string(fields.get("name"))
    if mat_name is None:
        _add_violation(violations, path, 1, "error", "MD-02", "Material missing name")
    else:
        # MD-03: name matches filename
        if mat_name != file_id:
            _add_violation(violations, path, _line_for(parsed, "name"), "error", "MD-03",
                           f"Material name '{mat_name}' must match filename '{file_id}'")

    # MD-04: Material must have a guid field (braced format)
    mat_guid = _as_string(fields.get("guid"))
    if mat_guid is None:
        _add_violation(violations, path, 1, "error", "MD-04",
                       "Material missing guid field")
    elif not GUID_RE_BRACED.match(mat_guid):
        _add_violation(violations, path, _line_for(parsed, "guid"), "error", "MD-04",
                       f"Material guid must be braced format, got '{mat_guid}'")

    # MD-05: No id field (INFO)
    if fields.get("id") is not None:
        _add_violation(violations, path, _line_for(parsed, "id"), "info", "MD-05",
                       "Materials should not have an id field")

    def _check_range(field_name, rule_id, lo, hi, severity="error"):
        v = fields.get(field_name)
        if v is None or _value_kind(v) != "number":
            _add_violation(violations, path, _line_for(parsed, field_name) or 1, severity,
                           rule_id, f"{field_name} must be a number")
            return None
        if v.value < lo or v.value > hi:
            _add_violation(violations, path, _line_for(parsed, field_name), severity, rule_id,
                           f"{field_name} = {v.value} outside range [{lo}, {hi}]")
            return None
        return v.value

    def _check_positive(field_name, rule_id, severity="error"):
        v = fields.get(field_name)
        if v is None or _value_kind(v) != "number":
            _add_violation(violations, path, _line_for(parsed, field_name) or 1, severity,
                           rule_id, f"{field_name} must be a positive number")
            return None
        if v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, field_name), severity, rule_id,
                           f"{field_name} must be > 0")
            return None
        return v.value

    # MD-06: density > 0
    _check_positive("density", "MD-06")

    # MD-07: hardness 0-10
    _check_range("hardness", "MD-07", 0, 10)

    # MD-08 through MD-13: 0.0-1.0 range properties
    _check_range("flexibility", "MD-08", 0.0, 1.0)
    _check_range("absorbency", "MD-09", 0.0, 1.0)
    _check_range("opacity", "MD-10", 0.0, 1.0)
    flammability = _check_range("flammability", "MD-11", 0.0, 1.0)
    _check_range("conductivity", "MD-12", 0.0, 1.0)
    _check_range("fragility", "MD-13", 0.0, 1.0)

    # MD-14: value > 0
    _check_positive("value", "MD-14")

    # MD-15: melting_point is positive number or nil
    mp_v = fields.get("melting_point")
    if mp_v is not None and mp_v.kind != "nil":
        if _value_kind(mp_v) != "number" or mp_v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, "melting_point"), "error", "MD-15",
                           "melting_point must be a positive number or nil")

    # MD-16: ignition_point is positive number or nil
    ip_v = fields.get("ignition_point")
    if ip_v is not None and ip_v.kind != "nil":
        if _value_kind(ip_v) != "number" or ip_v.value <= 0:
            _add_violation(violations, path, _line_for(parsed, "ignition_point"), "error",
                           "MD-16", "ignition_point must be a positive number or nil")

    has_ip = ip_v is not None and ip_v.kind != "nil"
    has_mp = mp_v is not None and mp_v.kind != "nil"

    # MD-17: flammability > 0 requires ignition_point (WARNING)
    if flammability is not None and flammability > 0 and not has_ip:
        _add_violation(violations, path, _line_for(parsed, "flammability"), "warning", "MD-17",
                       "Flammable material should declare ignition_point")

    # MD-18: flammability == 0 implies ignition_point nil (WARNING)
    if flammability is not None and flammability == 0 and has_ip:
        _add_violation(violations, path, _line_for(parsed, "ignition_point"), "warning", "MD-18",
                       "Non-flammable material should not have ignition_point")

    # MD-19: Melting/ignition point conflict detection (upgraded from INFO)
    if has_mp and has_ip:
        mp_val = mp_v.value if _value_kind(mp_v) == "number" else None
        ip_val = ip_v.value if _value_kind(ip_v) == "number" else None
        if mp_val is not None and ip_val is not None and mp_val <= ip_val:
            _add_violation(violations, path, _line_for(parsed, "melting_point"), "warning", "MD-19",
                           f"melting_point ({mp_val}) <= ignition_point ({ip_val}): "
                           f"material melts before or at ignition temperature")
        elif mp_val is not None and ip_val is not None:
            _add_violation(violations, path, _line_for(parsed, "melting_point"), "info", "MD-19",
                           f"Material declares both melting_point ({mp_val}) and ignition_point ({ip_val})")

    # MD-20: flexibility >= 0.7 and fragility > 0.3 (WARNING)
    flex_v = fields.get("flexibility")
    frag_v = fields.get("fragility")
    if (flex_v is not None and _value_kind(flex_v) == "number"
            and frag_v is not None and _value_kind(frag_v) == "number"):
        if flex_v.value >= 0.7 and frag_v.value > 0.3:
            _add_violation(violations, path, _line_for(parsed, "fragility"), "warning", "MD-20",
                           f"High flexibility ({flex_v.value}) with high fragility "
                           f"({frag_v.value}) is unusual")

    # MD-21: conductivity > 0 on non-metal (INFO)
    cond_v = fields.get("conductivity")
    if (cond_v is not None and _value_kind(cond_v) == "number" and cond_v.value > 0
            and mat_name and mat_name not in METAL_MATERIALS and mat_name != "stone"):
        _add_violation(violations, path, _line_for(parsed, "conductivity"), "info", "MD-21",
                       f"Non-metal material '{mat_name}' has conductivity > 0")

    # MD-22: rust_susceptibility 0.0-1.0 if present
    rs_v = fields.get("rust_susceptibility")
    if rs_v is not None:
        if _value_kind(rs_v) != "number":
            _add_violation(violations, path, _line_for(parsed, "rust_susceptibility"), "error",
                           "MD-22", "rust_susceptibility must be a number")
        elif rs_v.value < 0 or rs_v.value > 1.0:
            _add_violation(violations, path, _line_for(parsed, "rust_susceptibility"), "error",
                           "MD-22",
                           f"rust_susceptibility = {rs_v.value} outside range [0.0, 1.0]")

    # MD-23: rust_susceptibility only on ferrous materials (WARNING)
    if rs_v is not None and mat_name and mat_name not in FERROUS_MATERIALS:
        _add_violation(violations, path, _line_for(parsed, "rust_susceptibility"), "warning",
                       "MD-23", f"rust_susceptibility on non-ferrous material '{mat_name}'")

    # MD-24: unknown fields (INFO)
    for field_name in fields:
        if field_name not in KNOWN_MATERIAL_FIELDS:
            _add_violation(violations, path, _line_for(parsed, field_name), "info", "MD-24",
                           f"Unknown material field '{field_name}'")


def _validate_level(parsed: ParsedFile, room_ids: set, object_ids: set,
                    violations: List[Violation]) -> None:
    path = parsed.path
    fields = parsed.fields

    # LV-01: guid exists and valid (bare format)
    if parsed.guid is None:
        _add_violation(violations, path, 1, "error", "LV-01", "Level missing guid")
    elif not GUID_RE_BARE.match(parsed.guid):
        _add_violation(violations, path, _line_for(parsed, "guid"), "error", "LV-01",
                       f"Level guid must be bare format, got '{parsed.guid}'")

    # LV-02: template is "level"
    tmpl = _as_string(fields.get("template"))
    if tmpl != "level":
        _add_violation(violations, path, _line_for(parsed, "template") or 1, "error", "LV-02",
                       "Level must have template = 'level'")

    # LV-03: number is positive integer
    num_v = fields.get("number")
    level_number = None
    if num_v is None or _value_kind(num_v) != "number":
        _add_violation(violations, path, 1, "error", "LV-03",
                       "Level missing positive integer 'number'")
    elif num_v.value <= 0 or num_v.value != int(num_v.value):
        _add_violation(violations, path, _line_for(parsed, "number"), "error", "LV-03",
                       "Level number must be a positive integer")
    else:
        level_number = int(num_v.value)

    # LV-04: name exists
    if _as_string(fields.get("name")) is None:
        _add_violation(violations, path, 1, "error", "LV-04", "Level missing name")

    # LV-05: rooms is a non-empty table of strings
    rooms_v = fields.get("rooms")
    rooms_t = _as_table(rooms_v)
    room_list: list = []
    if rooms_v is None:
        _add_violation(violations, path, 1, "error", "LV-05", "Level missing rooms")
    elif rooms_t is None:
        _add_violation(violations, path, _line_for(parsed, "rooms"), "error", "LV-05",
                       "rooms must be a table")
    else:
        for entry in rooms_t.array:
            s = _as_string(entry)
            if s:
                room_list.append(s)
            elif entry.kind != "string":
                _add_violation(violations, path, _line_for(parsed, "rooms"), "error", "LV-05",
                               "rooms entries must be strings")
                break
        if len(room_list) == 0:
            _add_violation(violations, path, _line_for(parsed, "rooms"), "error", "LV-05",
                           "rooms must not be empty")

    room_set = set(room_list)

    # LV-06 / LV-39: start_room in rooms list
    sr = _as_string(fields.get("start_room"))
    if sr is None:
        _add_violation(violations, path, 1, "error", "LV-06", "Level missing start_room")
    elif room_list and sr not in room_set:
        _add_violation(violations, path, _line_for(parsed, "start_room"), "error", "LV-06",
                       f"start_room '{sr}' not in rooms list")

    # LV-07: start_room references a valid room file (cross-file)
    if sr and room_ids and sr not in room_ids:
        _add_violation(violations, path, _line_for(parsed, "start_room"), "error", "LV-07",
                       f"start_room '{sr}' not found in room files")

    # LV-08: completion defined (WARNING)
    if fields.get("completion") is None:
        _add_violation(violations, path, 1, "warning", "LV-08",
                       "Level should define completion criteria")

    # LV-09: intro defined (WARNING)
    if fields.get("intro") is None:
        _add_violation(violations, path, 1, "warning", "LV-09", "Level should define intro")

    # LV-10: boundaries.entry defined (WARNING)
    bounds_v = fields.get("boundaries")
    bounds_t = None
    if bounds_v is not None:
        bounds_t = _as_table(bounds_v)
        if bounds_t is not None:
            if bounds_t.fields.get("entry") is None:
                _add_violation(violations, path, _line_for(parsed, "boundaries"), "warning",
                               "LV-10", "Level boundaries should define entry")
        else:
            _add_violation(violations, path, _line_for(parsed, "boundaries"), "warning", "LV-10",
                           "boundaries should be a table")
    else:
        _add_violation(violations, path, 1, "warning", "LV-10",
                       "Level should define boundaries")

    # ── V2 Extended Checks ──

    # LV-36: description is a non-empty string (ERROR)
    if _as_string(fields.get("description")) is None:
        _add_violation(violations, path, 1, "error", "LV-36",
                       "Level must have a description")

    # LV-37: rooms entries are unique (ERROR)
    if room_list:
        seen: set = set()
        for r in room_list:
            if r in seen:
                _add_violation(violations, path, _line_for(parsed, "rooms"), "error", "LV-37",
                               f"Duplicate room '{r}' in rooms list")
            seen.add(r)

    # LV-38: rooms entries reference valid room files (ERROR, cross-file)
    if room_ids:
        for r in room_list:
            if r not in room_ids:
                _add_violation(violations, path, _line_for(parsed, "rooms"), "error", "LV-38",
                               f"Room '{r}' not found in room files")

    # LV-11 through LV-16: intro structure
    intro_v = fields.get("intro")
    if intro_v is not None:
        intro_t = _as_table(intro_v)
        # LV-11: intro is a table (ERROR)
        if intro_t is None:
            _add_violation(violations, path, _line_for(parsed, "intro"), "error", "LV-11",
                           "intro must be a table")
        else:
            # LV-12: intro.title is non-empty string (ERROR)
            if _as_string(intro_t.fields.get("title")) is None:
                _add_violation(violations, path, _line_for(parsed, "intro"), "error", "LV-12",
                               "intro.title must be a non-empty string")

            # LV-13: intro.narrative is a table of strings (ERROR)
            narr_v = intro_t.fields.get("narrative")
            if narr_v is not None:
                narr_t = _as_table(narr_v)
                if narr_t is None:
                    _add_violation(violations, path, _line_for(parsed, "intro"), "error",
                                   "LV-13", "intro.narrative must be a table of strings")
                else:
                    for ne in narr_t.array:
                        if ne.kind != "string":
                            _add_violation(violations, path, _line_for(parsed, "intro"),
                                           "error", "LV-13",
                                           "intro.narrative entries must be strings")
                            break
                    # LV-14: intro.narrative is non-empty (WARNING)
                    if len(narr_t.array) == 0:
                        _add_violation(violations, path, _line_for(parsed, "intro"),
                                       "warning", "LV-14",
                                       "intro.narrative should not be empty")

            # LV-15: intro.help is a non-empty string (WARNING)
            if _as_string(intro_t.fields.get("help")) is None:
                _add_violation(violations, path, _line_for(parsed, "intro"), "warning", "LV-15",
                               "intro should have help text")

            # LV-16: intro.subtitle is string (INFO)
            sub_v = intro_t.fields.get("subtitle")
            if sub_v is not None and _value_kind(sub_v) != "string":
                _add_violation(violations, path, _line_for(parsed, "intro"), "info", "LV-16",
                               "intro.subtitle should be a string")

    # LV-17 through LV-22: completion structure
    comp_v = fields.get("completion")
    if comp_v is not None:
        comp_t = _as_table(comp_v)
        # LV-17: completion is a table of tables (ERROR)
        if comp_t is None:
            _add_violation(violations, path, _line_for(parsed, "completion"), "error", "LV-17",
                           "completion must be a table of tables")
        else:
            for c_entry in comp_t.array:
                if c_entry.kind != "table":
                    _add_violation(violations, path, _line_for(parsed, "completion"), "error",
                                   "LV-17", "completion entries must be tables")
                    break
                c_f = c_entry.value.fields

                # LV-18: Each completion has type (ERROR)
                c_type = _as_string(c_f.get("type"))
                if c_type is None:
                    _add_violation(violations, path, _line_for(parsed, "completion"), "error",
                                   "LV-18", "completion entry missing type")

                # LV-19: type="reach_room" requires room (ERROR)
                cr = _as_string(c_f.get("room"))
                if c_type == "reach_room" and cr is None:
                    _add_violation(violations, path, _line_for(parsed, "completion"), "error",
                                   "LV-19",
                                   "completion type 'reach_room' requires room field")

                # LV-20: completion room in rooms list (ERROR)
                if cr is not None and room_list and cr not in room_set:
                    _add_violation(violations, path, _line_for(parsed, "completion"), "error",
                                   "LV-20",
                                   f"completion room '{cr}' not in level rooms")

                # LV-21: completion message (WARNING)
                if _as_string(c_f.get("message")) is None:
                    _add_violation(violations, path, _line_for(parsed, "completion"), "warning",
                                   "LV-21", "completion entry should have a message")

                # LV-22: completion from references valid room (WARNING)
                c_from = _as_string(c_f.get("from"))
                if c_from is not None and room_list and c_from not in room_set:
                    _add_violation(violations, path, _line_for(parsed, "completion"), "warning",
                                   "LV-22",
                                   f"completion from '{c_from}' not in level rooms")

    # LV-23 through LV-33: boundaries structure
    if bounds_t is not None:
        # LV-23: boundaries is a table (already validated above; this confirms)

        # LV-24/LV-25/LV-26: boundaries.entry
        entry_v = bounds_t.fields.get("entry")
        if entry_v is not None:
            entry_t = _as_table(entry_v)
            if entry_t is None:
                _add_violation(violations, path, _line_for(parsed, "boundaries"), "error",
                               "LV-24", "boundaries.entry must be a table of strings")
            else:
                entry_rooms = []
                for e in entry_t.array:
                    s = _as_string(e)
                    if s:
                        entry_rooms.append(s)
                    elif e.kind != "string":
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "error", "LV-24",
                                       "boundaries.entry entries must be strings")
                        break
                if len(entry_rooms) == 0:
                    _add_violation(violations, path, _line_for(parsed, "boundaries"), "error",
                                   "LV-24", "boundaries.entry must not be empty")

                # LV-25: entry rooms in rooms list (ERROR)
                for er in entry_rooms:
                    if room_list and er not in room_set:
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "error", "LV-25",
                                       f"boundaries.entry room '{er}' not in level rooms")

                # LV-26: entry includes start_room (WARNING)
                if sr and entry_rooms and sr not in entry_rooms:
                    _add_violation(violations, path, _line_for(parsed, "boundaries"), "warning",
                                   "LV-26",
                                   f"start_room '{sr}' not in boundaries.entry")

        # LV-27 through LV-33: boundaries.exit
        exit_v = bounds_t.fields.get("exit")
        if exit_v is not None:
            exit_t = _as_table(exit_v)
            # LV-27: boundaries.exit is a table of tables (WARNING)
            if exit_t is None:
                _add_violation(violations, path, _line_for(parsed, "boundaries"), "warning",
                               "LV-27", "boundaries.exit should be a table of tables")
            else:
                for e_entry in exit_t.array:
                    if e_entry.kind != "table":
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "warning", "LV-27",
                                       "boundaries.exit entries should be tables")
                        break
                    e_f = e_entry.value.fields

                    # LV-28: Each exit has room (ERROR)
                    er = _as_string(e_f.get("room"))
                    if er is None:
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "error", "LV-28", "boundary exit missing room")
                    else:
                        # LV-31: Exit room in rooms list (ERROR)
                        if room_list and er not in room_set:
                            _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                           "error", "LV-31",
                                           f"boundary exit room '{er}' not in level rooms")

                    # LV-29: Each exit has exit_direction (ERROR)
                    if _as_string(e_f.get("exit_direction")) is None:
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "error", "LV-29",
                                       "boundary exit missing exit_direction")

                    # LV-30: Each exit has target_level (ERROR)
                    tl_v = e_f.get("target_level")
                    if tl_v is None or _value_kind(tl_v) != "number":
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "error", "LV-30",
                                       "boundary exit missing positive target_level")
                    elif tl_v.value <= 0 or tl_v.value != int(tl_v.value):
                        _add_violation(violations, path, _line_for(parsed, "boundaries"),
                                       "error", "LV-30",
                                       "boundary exit target_level must be a positive integer")
                    else:
                        # LV-33: target_level > current number (WARNING)
                        if level_number is not None and tl_v.value <= level_number:
                            _add_violation(violations, path,
                                           _line_for(parsed, "boundaries"),
                                           "warning", "LV-33",
                                           f"boundary exit target_level {int(tl_v.value)} "
                                           f"<= current level {level_number}")

    elif bounds_v is not None and _as_table(bounds_v) is None:
        # LV-23: boundaries must be a table
        _add_violation(violations, path, _line_for(parsed, "boundaries"), "warning", "LV-23",
                       "boundaries should be a table")

    # LV-34/LV-35: restricted_objects
    ro_v = fields.get("restricted_objects")
    if ro_v is not None:
        ro_t = _as_table(ro_v)
        if ro_t is None:
            _add_violation(violations, path, _line_for(parsed, "restricted_objects"), "error",
                           "LV-34", "restricted_objects must be a table of strings")
        else:
            for ro_entry in ro_t.array:
                ro_str = _as_string(ro_entry)
                if ro_entry.kind != "string":
                    _add_violation(violations, path,
                                   _line_for(parsed, "restricted_objects"), "error",
                                   "LV-34", "restricted_objects entries must be strings")
                    break
                # LV-35: reference existing objects (WARNING)
                if ro_str and object_ids and ro_str not in object_ids:
                    _add_violation(violations, path,
                                   _line_for(parsed, "restricted_objects"), "warning",
                                   "LV-35",
                                   f"restricted object '{ro_str}' not found in object files")


def _validate_file(parsed: ParsedFile, materials: Dict[str, object], violations: List[Violation]) -> None:
    path = parsed.path
    fields = parsed.fields

    if parsed.kind == "template":
        _validate_template(parsed, violations)
        return
    if parsed.kind == "injury":
        _validate_injury(parsed, violations)
        return
    if parsed.kind == "material":
        _validate_material(parsed, violations)
        return
    if parsed.kind == "level":
        return
    if parsed.kind == "unknown":
        return

    if parsed.guid is None:
        _add_violation(violations, path, 1, "error", "S-02", "Missing guid field")
    elif not (GUID_RE_BRACED.match(parsed.guid) or GUID_RE_BARE.match(parsed.guid)):
        _add_violation(violations, path, _line_for(parsed, "guid"), "error", "G-01", "Invalid guid format")

    template = parsed.template
    if template is None:
        _add_violation(violations, path, 1, "error", "S-07", "Missing template field")
    else:
        allowed = {"small-item", "container", "furniture", "room", "sheet", "level", "portal", "creature"}
        if template not in allowed:
            _add_violation(violations, path, _line_for(parsed, "template"), "error", "S-07", f"Unknown template '{template}'")

    if _as_string(fields.get("id")) is None:
        _add_violation(violations, path, 1, "error", "S-04", "Missing id field")
    if _as_string(fields.get("name")) is None:
        _add_violation(violations, path, 1, "error", "S-06", "Missing name field")

    if parsed.kind in ("object", "creature"):
        keywords_value = fields.get("keywords")
        keywords_table = _as_table(keywords_value)
        if keywords_table is None:
            _add_violation(violations, path, 1, "error", "S-09", "Missing keywords table")
        else:
            if len(keywords_table.array) == 0:
                _add_violation(violations, path, _line_for(parsed, "keywords"), "error", "S-09", "Keywords table is empty")
            for entry in keywords_table.array:
                if entry.kind != "string":
                    _add_violation(violations, path, _line_for(parsed, "keywords"), "error", "S-10", "Keywords must be strings")
                    break

        states_value = fields.get("states")
        states_table = _as_table(states_value)
        initial_state = _as_string(fields.get("initial_state"))

        on_feel = fields.get("on_feel")
        if on_feel is None:
            state_on_feel_ok = False
            if states_table is not None:
                for state_def in states_table.fields.values():
                    if state_def.kind == "table":
                        state_on_feel = state_def.value.fields.get("on_feel")
                        if state_on_feel and state_on_feel.kind in ("string", "function"):
                            state_on_feel_ok = True
                            break
            if not state_on_feel_ok:
                _add_violation(violations, path, 1, "error", "SN-01", "Missing on_feel field")
        elif on_feel.kind not in ("string", "function"):
            _add_violation(violations, path, _line_for(parsed, "on_feel"), "error", "SN-02", "on_feel must be string or function")

        description = fields.get("description")
        if description is None:
            _add_violation(violations, path, 1, "warning", "S-11", "Missing description field")
        elif description.kind not in ("string", "function"):
            _add_violation(violations, path, _line_for(parsed, "description"), "warning", "S-11", "description should be string or function")

        if parsed.material is None:
            _add_violation(violations, path, 1, "warning", "MAT-01", "Missing material field")
        else:
            mat_names = materials.get("names", set())
            mat_guid_to_name = materials.get("guid_to_name", {})
            mat_value = parsed.material
            mat_bare = mat_value.strip("{}")
            if mat_value in mat_names:
                _add_violation(violations, path, _line_for(parsed, "material"), "warning", "MAT-03",
                               f"Material '{mat_value}' referenced by name - prefer GUID for consistency")
            elif mat_bare in mat_guid_to_name:
                pass  # GUID reference - valid, no warning
            else:
                _add_violation(violations, path, _line_for(parsed, "material"), "error", "MAT-02",
                               f"Unknown material '{mat_value}'")

    if parsed.template == "room":
        description = fields.get("description")
        if description is None:
            _add_violation(violations, path, 1, "warning", "RM-01", "Missing room description")

    states_value = fields.get("states")
    states_table = _as_table(states_value)
    if states_table is not None:
        state_keys = set(states_table.fields.keys())
        initial_state = _as_string(fields.get("initial_state"))
        if initial_state is None:
            _add_violation(violations, path, _line_for(parsed, "states"), "error", "FSM-01", "initial_state missing for FSM")
        elif initial_state not in state_keys:
            _add_violation(violations, path, _line_for(parsed, "initial_state"), "error", "FSM-04", "initial_state not defined in states")

        transitions_value = fields.get("transitions")
        transitions_table = _as_table(transitions_value)
        if transitions_table is not None:
            for trans in transitions_table.array:
                if trans.kind != "table":
                    continue
                from_state = _as_string(trans.value.fields.get("from"))
                to_state = _as_string(trans.value.fields.get("to"))
                if from_state and from_state not in state_keys:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error", "TR-01", f"Transition from '{from_state}' not in states")
                if to_state and to_state not in state_keys:
                    _add_violation(violations, path, _line_for(parsed, "transitions"), "error", "TR-02", f"Transition to '{to_state}' not in states")


def _load_materials(project_root: Path) -> Dict[str, object]:
    """Load material names and GUIDs from src/meta/materials/*.lua."""
    materials_dir = project_root / "src" / "meta" / "materials"
    if not materials_dir.exists():
        return {"names": set(), "guid_to_name": {}}
    names: set = set()
    guid_to_name: Dict[str, str] = {}
    guid_re = re.compile(r'guid\s*=\s*"([^"]+)"')
    for f in materials_dir.iterdir():
        if f.suffix != ".lua":
            continue
        name = f.stem
        names.add(name)
        try:
            mat_content = f.read_text(encoding="utf-8")
            m = guid_re.search(mat_content)
            if m:
                bare = m.group(1).strip("{}")
                guid_to_name[bare] = name
        except OSError:
            pass
    return {"names": names, "guid_to_name": guid_to_name}


def _collect_lua_files(path: Path) -> List[Path]:
    if path.is_file():
        return [path] if path.suffix == ".lua" else []
    lua_files: List[Path] = []
    for root, _, files in os.walk(path):
        for filename in files:
            if filename.endswith(".lua"):
                lua_files.append(Path(root) / filename)
    return lua_files


def _format_text(violations: List[Violation], by_owner: bool = False) -> str:
    if by_owner and violations:
        return _format_text_by_owner(violations)
    lines = []
    for v in violations:
        lines.append(f"{v.file} : {v.line} : {v.severity.upper()} : {v.rule_id} : [{v.owner}] : {v.message}")
    return "\n".join(lines)


def _format_text_by_owner(violations: List[Violation]) -> str:
    """Group violations by squad owner for easy assignment."""
    from collections import defaultdict
    by_owner: Dict[str, List[Violation]] = defaultdict(list)
    for v in violations:
        by_owner[v.owner].append(v)
    lines = []
    for owner in sorted(by_owner.keys()):
        vlist = by_owner[owner]
        lines.append(f"\n=== {owner} ({len(vlist)} violations) ===")
        for v in vlist:
            lines.append(f"  {v.file} : {v.line} : {v.severity.upper()} : {v.rule_id} : {v.message}")
    return "\n".join(lines)


def _format_json(violations: List[Violation], files_scanned: int, exit_code: int,
                 cache_stats: Optional[Dict] = None) -> str:
    payload = {
        "meta_check_version": "3.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "files_scanned": files_scanned,
        "violations": [
            {"file": v.file, "line": v.line, "severity": v.severity,
             "rule_id": v.rule_id, "message": v.message,
             "fixable": v.fixable, "fix_safety": v.fix_safety, "owner": v.owner}
            for v in violations
        ],
        "summary": {
            "total_files": files_scanned,
            "errors": sum(1 for v in violations if v.severity == "error"),
            "warnings": sum(1 for v in violations if v.severity == "warning"),
            "infos": sum(1 for v in violations if v.severity == "info"),
            "fixable_count": sum(1 for v in violations if v.fixable),
            "safe_fixes": sum(1 for v in violations if v.fixable and v.fix_safety == "safe"),
            "unsafe_fixes": sum(1 for v in violations if v.fixable and v.fix_safety == "unsafe"),
        },
        "exit_code": exit_code,
    }
    owner_counts: Dict[str, int] = {}
    for v in violations:
        owner_counts[v.owner] = owner_counts.get(v.owner, 0) + 1
    payload["summary"]["by_owner"] = owner_counts
    if cache_stats:
        payload["cache"] = cache_stats
    return json.dumps(payload, indent=2)


def _list_rules_text() -> str:
    """Format all rules as a human-readable table."""
    rules = rule_registry.get_all_rules()
    lines = [f"{'Rule':<10} {'Severity':<10} {'Fixable':<10} {'Safety':<8} {'Category':<15} Description"]
    lines.append("-" * 100)
    for rule_id in sorted(rules):
        r = rules[rule_id]
        fix = "yes" if r.fixable else "no"
        safety = r.fix_safety if r.fixable else "-"
        lines.append(f"{r.id:<10} {r.severity:<10} {fix:<10} {safety:<8} {r.category:<15} {r.description}")
    return "\n".join(lines)


def main() -> int:
    global _active_config, _squad_router

    parser_cli = argparse.ArgumentParser(description="Meta-check validator for MMO meta files")
    parser_cli.add_argument("path", nargs="?", default="src/meta/", help="File or directory to validate")
    parser_cli.add_argument("--format", default="text", choices=("text", "json"), help="Output format")
    parser_cli.add_argument("--severity", default="all", choices=("all", "warning", "error"), help="Minimum severity to report")
    parser_cli.add_argument("--output", default=None, help="Write output to file")
    parser_cli.add_argument("--verbose", action="store_true", help="Verbose output")
    parser_cli.add_argument("--config", default=None, help="Path to .meta-check.json config file")
    parser_cli.add_argument("--list-rules", action="store_true", help="List all rules and exit")
    parser_cli.add_argument("--init-config", action="store_true", help="Generate default .meta-check.json and exit")
    parser_cli.add_argument("--by-owner", action="store_true", help="Group text output by squad member owner")
    parser_cli.add_argument("--no-cache", action="store_true", help="Disable incremental caching (full re-scan)")

    args = parser_cli.parse_args()

    root = Path(__file__).resolve().parents[2]

    if args.list_rules:
        print(_list_rules_text())
        return 0

    if args.init_config:
        out = config_mod.write_default_config(root)
        print(f"Created {out}")
        return 0

    if args.config:
        config_path = Path(args.config)
        if not config_path.is_absolute():
            config_path = (root / config_path).resolve()
        if config_path.exists():
            _active_config = config_mod.parse_config(config_path.read_text(encoding="utf-8"))
        else:
            print(f"WARNING: Config file not found: {config_path}", file=sys.stderr)
            _active_config = config_mod.CheckConfig()
    else:
        _active_config = config_mod.load_config(root)

    routing_overrides = getattr(_active_config, 'squad_routing', None)
    _squad_router = squad_routing_mod.SquadRouter(routing_overrides)

    target = Path(args.path)
    if not target.is_absolute():
        target = (root / target).resolve()

    lua_files = _collect_lua_files(target)
    if not lua_files:
        print("No .lua files found.")
        return 65

    use_cache = not args.no_cache
    cache = cache_mod.load_cache(root) if use_cache else cache_mod.LintCache()
    cache_hits = 0
    cache_misses = 0
    file_hashes: Dict[str, str] = {}

    any_file_changed = False
    for path in lua_files:
        h = cache_mod.hash_file(path)
        file_hashes[str(path)] = h
        if cache.get_cached(str(path), h) is None:
            any_file_changed = True

    materials = _load_materials(root)
    violations: List[Violation] = []
    parsed_files: List[ParsedFile] = []

    for path in lua_files:
        file_key = str(path)
        h = file_hashes[file_key]

        if use_cache and not any_file_changed:
            cached = cache.get_cached(file_key, h)
            if cached is not None:
                cache_hits += 1
                for cv in cached:
                    violations.append(Violation(
                        file=cv["file"], line=cv["line"],
                        severity=cv["severity"], rule_id=cv["rule_id"],
                        message=cv["message"],
                        fixable=cv.get("fixable", False),
                        fix_safety=cv.get("fix_safety", "unsafe"),
                        owner=cv.get("owner", _squad_router.owner_for(cv["rule_id"])),
                    ))
                parsed = _parse_file(path, [])
                if parsed:
                    parsed_files.append(parsed)
                continue

        cache_misses += 1
        parsed = _parse_file(path, violations)
        if parsed:
            parsed_files.append(parsed)

    for parsed in parsed_files:
        file_key = str(parsed.path)
        if use_cache and not any_file_changed and cache.get_cached(file_key, file_hashes.get(file_key, "")) is not None:
            continue
        _validate_file(parsed, materials, violations)

    if use_cache:
        for parsed in parsed_files:
            file_key = str(parsed.path)
            h = file_hashes.get(file_key)
            if h is None:
                continue
            file_violations = [
                {"file": v.file, "line": v.line, "severity": v.severity,
                 "rule_id": v.rule_id, "message": v.message,
                 "fixable": v.fixable, "fix_safety": v.fix_safety, "owner": v.owner}
                for v in violations
                if v.file == file_key and not cache_mod.is_cross_file_rule(v.rule_id)
            ]
            cache.update(file_key, h, file_violations)

    guid_map: Dict[str, List[ParsedFile]] = {}
    keyword_map: Dict[str, List[ParsedFile]] = {}
    for parsed in parsed_files:
        if parsed.guid:
            guid_map.setdefault(parsed.guid, []).append(parsed)
        if parsed.kind in ("object", "creature"):
            for keyword in parsed.keywords:
                keyword_map.setdefault(keyword.lower(), []).append(parsed)

    for guid, files in guid_map.items():
        if len(files) > 1:
            for parsed in files:
                _add_violation(violations, parsed.path, _line_for(parsed, "guid"), "error", "XF-01", f"Duplicate guid '{guid}'")

    for keyword, files in keyword_map.items():
        if len(files) > 1:
            # Smart XF-03: skip category keywords and config-allowlisted keywords
            if keyword in CATEGORY_KEYWORDS:
                continue
            if _active_config.is_keyword_allowed(keyword):
                continue
            file_list = ", ".join(sorted({f.path.name for f in files}))
            for parsed in files:
                _add_violation(violations, parsed.path, _line_for(parsed, "keywords"), "warning", "XF-03", f"Keyword '{keyword}' appears in multiple files: {file_list}")

    # -----------------------------------------------------------------
    # Cross-file data collection for V2 validators
    # -----------------------------------------------------------------
    room_ids: set = set()
    object_ids: set = set()
    injury_ids: set = set()
    level_room_sets: Dict[str, set] = {}

    for p in parsed_files:
        obj_id = _as_string(p.fields.get("id"))
        if p.kind == "room" and obj_id:
            room_ids.add(obj_id)
        elif p.kind in ("object", "creature") and obj_id:
            object_ids.add(obj_id)
        elif p.kind == "injury" and obj_id:
            injury_ids.add(obj_id)
        elif p.kind == "level":
            rooms_t = _as_table(p.fields.get("rooms"))
            if rooms_t:
                lvl_rooms: set = set()
                for entry in rooms_t.array:
                    s = _as_string(entry)
                    if s:
                        lvl_rooms.add(s)
                level_room_sets[str(p.path)] = lvl_rooms

    # Level validation (needs cross-file data)
    for parsed in parsed_files:
        if parsed.kind == "level":
            _validate_level(parsed, room_ids, object_ids, violations)

    # -----------------------------------------------------------------
    # Cross-reference checks (XR-01 through XR-11)
    # -----------------------------------------------------------------

    # XR-01: Healing item IDs in healing_interactions resolve to objects
    if object_ids:
        for parsed in parsed_files:
            if parsed.kind == "injury":
                hi_v = parsed.fields.get("healing_interactions")
                hi_t = _as_table(hi_v)
                if hi_t:
                    for item_id in hi_t.fields:
                        if item_id not in object_ids:
                            _add_violation(violations, parsed.path,
                                           _line_for(parsed, "healing_interactions"),
                                           "warning", "XR-01",
                                           f"Healing item '{item_id}' not found in object files")

    # XR-03: requires_item_cures references valid injury IDs
    if injury_ids:
        for parsed in parsed_files:
            if parsed.kind == "injury":
                trans_v = parsed.fields.get("transitions")
                trans_t = _as_table(trans_v)
                if trans_t:
                    for t_entry in trans_t.array:
                        if t_entry.kind == "table":
                            ric = _as_string(t_entry.value.fields.get("requires_item_cures"))
                            if ric and ric not in injury_ids:
                                _add_violation(violations, parsed.path,
                                               _line_for(parsed, "transitions"),
                                               "warning", "XR-03",
                                               f"requires_item_cures '{ric}' not a known injury id")

    # XR-08: Level completion rooms exist as room files
    if room_ids:
        for parsed in parsed_files:
            if parsed.kind == "level":
                comp_v = parsed.fields.get("completion")
                comp_t = _as_table(comp_v)
                if comp_t:
                    for c_entry in comp_t.array:
                        if c_entry.kind == "table":
                            cr = _as_string(c_entry.value.fields.get("room"))
                            if cr and cr not in room_ids:
                                _add_violation(violations, parsed.path,
                                               _line_for(parsed, "completion"),
                                               "warning", "XR-08",
                                               f"Completion room '{cr}' not found in room files")

    # XR-10: Every room file belongs to at least one level
    if level_room_sets:
        all_level_rooms: set = set()
        for rooms in level_room_sets.values():
            all_level_rooms.update(rooms)
        for parsed in parsed_files:
            if parsed.kind == "room":
                rid = _as_string(parsed.fields.get("id"))
                if rid and rid not in all_level_rooms:
                    _add_violation(violations, parsed.path, 1, "warning", "XR-10",
                                   f"Room '{rid}' not assigned to any level")

    # XR-02: Objects with on_use.cures reference valid injury IDs
    if injury_ids:
        for parsed in parsed_files:
            if parsed.kind in ("object", "creature"):
                on_use_v = parsed.fields.get("on_use")
                if on_use_v is not None:
                    on_use_t = _as_table(on_use_v)
                    if on_use_t is not None:
                        cures = _as_string(on_use_t.fields.get("cures"))
                        if cures and cures not in injury_ids:
                            _add_violation(violations, parsed.path,
                                           _line_for(parsed, "on_use"),
                                           "warning", "XR-02",
                                           f"on_use.cures '{cures}' not a known injury id")

    # XR-04: Object material values reference material files (covered by MAT-02)
    # XR-05: Template material = "generic" is intentional (INFO)
    template_ids: set = set()
    generic_templates: Set[str] = set()
    for parsed in parsed_files:
        if parsed.kind == "template":
            tid = _as_string(parsed.fields.get("id"))
            if tid:
                template_ids.add(tid)
            mat = _as_string(parsed.fields.get("material"))
            if mat and mat == "generic" and mat not in materials.get("names", set()):
                generic_templates.add(tid or "")
                _add_violation(violations, parsed.path,
                               _line_for(parsed, "material"),
                               "info", "XR-05",
                               "Template uses 'generic' material (instances must override)")

    # XR-05b: Objects inheriting a generic-material template without override
    if generic_templates:
        for parsed in parsed_files:
            if parsed.kind in ("object", "creature"):
                tmpl = _as_string(parsed.fields.get("template"))
                if tmpl and tmpl in generic_templates:
                    obj_mat = _as_string(parsed.fields.get("material"))
                    if obj_mat is None or obj_mat == "generic":
                        _add_violation(violations, parsed.path,
                                       _line_for(parsed, "template"),
                                       "warning", "XR-05b",
                                       f"Object inherits '{tmpl}' template with generic material "
                                       f"but does not override material")

    # XR-06: Every template value on objects resolves to a template file
    if template_ids:
        for parsed in parsed_files:
            if parsed.kind in ("object", "creature", "room"):
                tmpl = _as_string(parsed.fields.get("template"))
                if tmpl and tmpl not in template_ids and tmpl != "level":
                    _add_violation(violations, parsed.path,
                                   _line_for(parsed, "template"),
                                   "error", "XR-06",
                                   f"Template '{tmpl}' not found in template files")

    # XR-09: Level boundary exit directions exist on rooms (WARNING)
    # Requires room exit data — check if room exits table has the declared direction
    if room_ids:
        room_exit_dirs: Dict[str, set] = {}
        for parsed in parsed_files:
            if parsed.kind == "room":
                rid = _as_string(parsed.fields.get("id"))
                exits_v = parsed.fields.get("exits")
                exits_t = _as_table(exits_v)
                if rid and exits_t:
                    room_exit_dirs[rid] = set(exits_t.fields.keys())
        for parsed in parsed_files:
            if parsed.kind == "level":
                bounds_v = parsed.fields.get("boundaries")
                bt = _as_table(bounds_v)
                if bt:
                    exit_v = bt.fields.get("exit")
                    exit_t = _as_table(exit_v)
                    if exit_t:
                        for e_entry in exit_t.array:
                            if e_entry.kind != "table":
                                continue
                            ef = e_entry.value.fields
                            er = _as_string(ef.get("room"))
                            ed = _as_string(ef.get("exit_direction"))
                            if er and ed and er in room_exit_dirs:
                                if ed not in room_exit_dirs[er]:
                                    _add_violation(violations, parsed.path,
                                                   _line_for(parsed, "boundaries"),
                                                   "warning", "XR-09",
                                                   f"Room '{er}' has no '{ed}' exit")

    # XR-11: GUID global uniqueness (already covered by XF-01 guid_map above)

    # -----------------------------------------------------------------
    # Phase 2: GUID Cross-Reference Validation (GUID-01, GUID-02, GUID-03)
    # -----------------------------------------------------------------

    # Build bare GUID → object path map for cross-reference
    obj_guid_bare: Dict[str, ParsedFile] = {}
    for parsed in parsed_files:
        if parsed.kind in ("object", "creature") and parsed.guid:
            bare = parsed.guid.strip("{}")
            obj_guid_bare[bare] = parsed

    # Collect all type_ids from room instances (recursive walk)
    all_referenced_guids: Set[str] = set()

    def _collect_instance_type_ids(
        table_value: Optional[LuaValue],
        room_parsed: ParsedFile,
        violations_list: List[Violation],
        seen_ids: Set[str],
    ) -> None:
        """Recursively walk room instances to validate type_ids and instance ids."""
        if table_value is None or table_value.kind != "table":
            return
        for item in table_value.value.array:
            if item.kind != "table":
                continue
            item_fields = item.value.fields
            instance_id = _as_string(item_fields.get("id"))
            type_id = _as_string(item_fields.get("type_id"))

            # GUID-03: Duplicate instance id within same room
            if instance_id is not None:
                if instance_id in seen_ids:
                    _add_violation(violations_list, room_parsed.path,
                                   _line_for(room_parsed, "instances"),
                                   "error", "GUID-03",
                                   f"Duplicate instance id '{instance_id}' in room")
                seen_ids.add(instance_id)

            # GUID-01: type_id must resolve to a known object GUID
            if type_id is not None:
                bare_type_id = type_id.strip("{}")
                all_referenced_guids.add(bare_type_id)
                if bare_type_id not in obj_guid_bare:
                    _add_violation(violations_list, room_parsed.path,
                                   _line_for(room_parsed, "instances"),
                                   "error", "GUID-01",
                                   f"Instance '{instance_id or '?'}' has type_id "
                                   f"'{type_id}' which does not match any object GUID")

            # Recurse into nested relationships
            for rel in ("on_top", "contents", "nested", "underneath"):
                rel_value = item_fields.get(rel)
                if rel_value is not None:
                    _collect_instance_type_ids(
                        rel_value, room_parsed, violations_list, seen_ids)

    for parsed in parsed_files:
        if parsed.kind == "room":
            instances_v = parsed.fields.get("instances")
            seen_instance_ids: Set[str] = set()
            _collect_instance_type_ids(instances_v, parsed, violations, seen_instance_ids)

    # GUID-02: Orphan objects — GUID not referenced by any room instance
    has_rooms = any(p.kind == "room" for p in parsed_files)
    if has_rooms:
        for parsed in parsed_files:
            if parsed.kind in ("object", "creature") and parsed.guid:
                bare = parsed.guid.strip("{}")
                if bare not in all_referenced_guids:
                    obj_id = _as_string(parsed.fields.get('id')) or '?'
                    if _active_config.is_orphan_allowed(obj_id):
                        continue
                    _add_violation(violations, parsed.path,
                                   _line_for(parsed, "guid"),
                                   "warning", "GUID-02",
                                   f"Object '{obj_id}' "
                                   f"GUID not referenced by any room instance")

    # -----------------------------------------------------------------
    # Phase 2: EXIT Validation (EXIT-01, EXIT-02)
    # -----------------------------------------------------------------

    # EXIT-01: Exit target must reference a valid room
    # EXIT-02: Bidirectional exit check
    room_exit_map: Dict[str, Dict[str, str]] = {}
    for parsed in parsed_files:
        if parsed.kind == "room":
            rid = _as_string(parsed.fields.get("id"))
            exits_v = parsed.fields.get("exits")
            exits_t = _as_table(exits_v)
            if rid and exits_t:
                room_exits: Dict[str, str] = {}
                for direction, exit_val in exits_t.fields.items():
                    if exit_val.kind == "table":
                        target = _as_string(exit_val.value.fields.get("target"))
                        if target:
                            room_exits[direction] = target
                            if target not in room_ids:
                                _add_violation(violations, parsed.path,
                                               _line_for(parsed, "exits"),
                                               "error", "EXIT-01",
                                               f"Exit '{direction}' targets room "
                                               f"'{target}' which does not exist")
                room_exit_map[rid] = room_exits

    for room_id, exits in room_exit_map.items():
        for direction, target in exits.items():
            if target in room_exit_map:
                target_exits = room_exit_map[target]
                has_return = any(t == room_id for t in target_exits.values())
                if not has_return:
                    for parsed in parsed_files:
                        if parsed.kind == "room":
                            rid = _as_string(parsed.fields.get("id"))
                            if rid == room_id:
                                _add_violation(violations, parsed.path,
                                               _line_for(parsed, "exits"),
                                               "warning", "EXIT-02",
                                               f"Exit '{direction}' goes to '{target}' "
                                               f"but '{target}' has no exit back to "
                                               f"'{room_id}'")

    # -----------------------------------------------------------------
    # Phase 4: Portal Validation (EXIT-01 through EXIT-07, XR-07)
    # -----------------------------------------------------------------

    # Build portal object index: id → ParsedFile
    portal_objects: Dict[str, ParsedFile] = {}
    for parsed in parsed_files:
        if parsed.kind in ("object", "creature"):
            tmpl = _as_string(parsed.fields.get("template"))
            if tmpl == "portal":
                obj_id = _as_string(parsed.fields.get("id"))
                if obj_id:
                    portal_objects[obj_id] = parsed

    # Build room exit → portal ID mapping (thin references)
    # Structure: { room_id: { direction: portal_id } }
    room_portal_refs: Dict[str, Dict[str, str]] = {}
    for parsed in parsed_files:
        if parsed.kind == "room":
            rid = _as_string(parsed.fields.get("id"))
            exits_v = parsed.fields.get("exits")
            exits_t = _as_table(exits_v)
            if rid and exits_t:
                refs: Dict[str, str] = {}
                for direction, exit_val in exits_t.fields.items():
                    if exit_val.kind == "table":
                        portal_id = _as_string(exit_val.value.fields.get("portal"))
                        if portal_id:
                            refs[direction] = portal_id
                if refs:
                    room_portal_refs[rid] = refs

    # EXIT-01: Portal must have portal.target defined and non-nil
    for obj_id, parsed in portal_objects.items():
        portal_v = parsed.fields.get("portal")
        portal_t = _as_table(portal_v)
        if portal_t is None:
            _add_violation(violations, parsed.path,
                           _line_for(parsed, "portal") or 1,
                           "error", "EXIT-01",
                           f"Portal '{obj_id}' missing portal table")
        else:
            target_v = portal_t.fields.get("target")
            if target_v is None or target_v.kind == "nil":
                _add_violation(violations, parsed.path,
                               _line_for(parsed, "portal"),
                               "error", "EXIT-01",
                               f"Portal '{obj_id}' has no portal.target defined")
            elif _as_string(target_v) is None:
                _add_violation(violations, parsed.path,
                               _line_for(parsed, "portal"),
                               "error", "EXIT-01",
                               f"Portal '{obj_id}' portal.target must be a string")

    # EXIT-02: Every portal FSM state must declare traversable = true/false
    for obj_id, parsed in portal_objects.items():
        states_v = parsed.fields.get("states")
        states_t = _as_table(states_v)
        if states_t is not None:
            for state_name, state_val in states_t.fields.items():
                st = _as_table(state_val)
                if st is None:
                    continue
                trav_v = st.fields.get("traversable")
                if trav_v is None:
                    _add_violation(violations, parsed.path,
                                   _line_for(parsed, "states"),
                                   "error", "EXIT-02",
                                   f"Portal '{obj_id}' state '{state_name}' "
                                   f"missing traversable declaration")
                elif _value_kind(trav_v) != "boolean":
                    _add_violation(violations, parsed.path,
                                   _line_for(parsed, "states"),
                                   "error", "EXIT-02",
                                   f"Portal '{obj_id}' state '{state_name}' "
                                   f"traversable must be boolean")

    # EXIT-03: Every bidirectional_id must have exactly ONE matching partner
    bidir_map: Dict[str, List[str]] = {}
    for obj_id, parsed in portal_objects.items():
        portal_v = parsed.fields.get("portal")
        portal_t = _as_table(portal_v)
        if portal_t is not None:
            bidir_v = portal_t.fields.get("bidirectional_id")
            if bidir_v is not None and bidir_v.kind != "nil":
                bidir_id = _as_string(bidir_v)
                if bidir_id:
                    bidir_map.setdefault(bidir_id, []).append(obj_id)

    for bidir_id, obj_ids in bidir_map.items():
        if len(obj_ids) == 1:
            parsed = portal_objects[obj_ids[0]]
            _add_violation(violations, parsed.path,
                           _line_for(parsed, "portal"),
                           "error", "EXIT-03",
                           f"Portal '{obj_ids[0]}' bidirectional_id '{bidir_id}' "
                           f"has no matching partner")
        elif len(obj_ids) > 2:
            for oid in obj_ids:
                parsed = portal_objects[oid]
                _add_violation(violations, parsed.path,
                               _line_for(parsed, "portal"),
                               "error", "EXIT-03",
                               f"Portal '{oid}' bidirectional_id '{bidir_id}' "
                               f"has {len(obj_ids) - 1} partners (expected exactly 1)")

    # EXIT-04: Portal direction_hint should match the room exit direction key
    # Build reverse map: portal_id → [(room_id, direction)]
    portal_to_room_dirs: Dict[str, List[Tuple[str, str]]] = {}
    for room_id, refs in room_portal_refs.items():
        for direction, portal_id in refs.items():
            portal_to_room_dirs.setdefault(portal_id, []).append((room_id, direction))

    for obj_id, parsed in portal_objects.items():
        portal_v = parsed.fields.get("portal")
        portal_t = _as_table(portal_v)
        if portal_t is not None:
            hint_v = portal_t.fields.get("direction_hint")
            hint = _as_string(hint_v)
            if hint and obj_id in portal_to_room_dirs:
                for room_id, direction in portal_to_room_dirs[obj_id]:
                    if hint != direction:
                        _add_violation(violations, parsed.path,
                                       _line_for(parsed, "portal"),
                                       "warning", "EXIT-04",
                                       f"Portal '{obj_id}' direction_hint '{hint}' "
                                       f"doesn't match room '{room_id}' exit "
                                       f"direction '{direction}'")

    # EXIT-05: Thin exit reference must point to an object with template="portal"
    for room_id, refs in room_portal_refs.items():
        room_parsed = None
        for p in parsed_files:
            if p.kind == "room" and _as_string(p.fields.get("id")) == room_id:
                room_parsed = p
                break
        if room_parsed is None:
            continue
        for direction, portal_id in refs.items():
            if portal_id in portal_objects:
                pass  # Valid portal reference
            elif portal_id in object_ids:
                # Object exists but is not a portal
                _add_violation(violations, room_parsed.path,
                               _line_for(room_parsed, "exits"),
                               "warning", "EXIT-05",
                               f"Exit '{direction}' portal '{portal_id}' "
                               f"references object that is not template='portal'")

    # EXIT-06: No inline exit state allowed — exit tables must not have
    # open, locked, hidden, broken, mutations, keywords fields
    BANNED_EXIT_FIELDS = {"open", "locked", "hidden", "broken", "mutations", "keywords"}
    for parsed in parsed_files:
        if parsed.kind == "room":
            exits_v = parsed.fields.get("exits")
            exits_t = _as_table(exits_v)
            if exits_t is not None:
                for direction, exit_val in exits_t.fields.items():
                    if exit_val.kind != "table":
                        continue
                    exit_fields = exit_val.value.fields
                    for banned in BANNED_EXIT_FIELDS:
                        if banned in exit_fields:
                            _add_violation(violations, parsed.path,
                                           _line_for(parsed, "exits"),
                                           "error", "EXIT-06",
                                           f"Exit '{direction}' has inline field "
                                           f"'{banned}' — use portal object instead")

    # EXIT-07: Portal object should have on_feel (P6 darkness requirement)
    for obj_id, parsed in portal_objects.items():
        on_feel = parsed.fields.get("on_feel")
        if on_feel is None:
            # Check per-state on_feel
            states_v = parsed.fields.get("states")
            states_t = _as_table(states_v)
            has_state_on_feel = False
            if states_t is not None:
                for state_val in states_t.fields.values():
                    st = _as_table(state_val)
                    if st and st.fields.get("on_feel") is not None:
                        has_state_on_feel = True
                        break
            if not has_state_on_feel:
                _add_violation(violations, parsed.path, 1,
                               "warning", "EXIT-07",
                               f"Portal '{obj_id}' missing on_feel "
                               f"(required for darkness navigation)")

    # XR-07: Thin exit portal field must resolve to a valid object ID
    for room_id, refs in room_portal_refs.items():
        room_parsed = None
        for p in parsed_files:
            if p.kind == "room" and _as_string(p.fields.get("id")) == room_id:
                room_parsed = p
                break
        if room_parsed is None:
            continue
        for direction, portal_id in refs.items():
            if portal_id not in object_ids:
                _add_violation(violations, room_parsed.path,
                               _line_for(room_parsed, "exits"),
                               "warning", "XR-07",
                               f"Exit '{direction}' portal '{portal_id}' "
                               f"does not match any object ID")

    # LV-40: number uniqueness across levels
    level_numbers: Dict[int, List[ParsedFile]] = {}
    for parsed in parsed_files:
        if parsed.kind == "level":
            num_v = parsed.fields.get("number")
            if num_v is not None and _value_kind(num_v) == "number":
                n = int(num_v.value)
                level_numbers.setdefault(n, []).append(parsed)
    for num, files in level_numbers.items():
        if len(files) > 1:
            for parsed in files:
                _add_violation(violations, parsed.path, _line_for(parsed, "number"),
                               "error", "LV-40",
                               f"Duplicate level number {num}")

    severity_filter = args.severity
    if severity_filter == "error":
        filtered = [v for v in violations if v.severity == "error"]
    elif severity_filter == "warning":
        filtered = [v for v in violations if v.severity in ("error", "warning")]
    else:
        filtered = violations

    if filtered and any(v.severity == "error" for v in filtered):
        exit_code = 1
    elif filtered and any(v.severity == "warning" for v in filtered):
        exit_code = 2
    else:
        exit_code = 0

    cache_stats = {"enabled": use_cache, "hits": cache_hits, "misses": cache_misses}

    if args.format == "json":
        output = _format_json(filtered, len(lua_files), exit_code, cache_stats)
    else:
        output = _format_text(filtered, by_owner=args.by_owner)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
    else:
        if output:
            print(output)

    if args.verbose:
        print(f"Files scanned: {len(lua_files)}")
        print(f"Violations: {len(filtered)}")
        if use_cache:
            print(f"Cache: {cache_hits} hits, {cache_misses} misses")

    if use_cache:
        valid_paths = {str(p) for p in lua_files}
        cache.prune(valid_paths)
        cache_mod.save_cache(root, cache)

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
