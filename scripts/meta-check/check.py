#!/usr/bin/env python3
"""
meta-check: static validator for MMO meta .lua files.
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
from typing import Dict, List, Optional, Tuple

try:
    from lark import Lark, Tree, Token
except ImportError:
    print("ERROR: lark not installed. Run: pip install lark")
    sys.exit(1)


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
    if os.sep + "src" + os.sep + "meta" + os.sep + "world" + os.sep in lower:
        return "room"
    if os.sep + "src" + os.sep + "meta" + os.sep + "levels" + os.sep in lower:
        return "level"
    if os.sep + "src" + os.sep + "meta" + os.sep + "templates" + os.sep in lower:
        return "template"
    if os.sep + "src" + os.sep + "meta" + os.sep + "injuries" + os.sep in lower:
        return "injury"
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


def _add_violation(violations: List[Violation], path: Path, line: int, severity: str, rule_id: str, message: str) -> None:
    violations.append(Violation(
        file=str(path),
        line=line,
        severity=severity,
        rule_id=rule_id,
        message=message,
    ))


def _line_for(parsed: ParsedFile, field: str, fallback: int = 1) -> int:
    pos = parsed.positions.get(field)
    return pos[0] if pos else fallback


def _validate_file(parsed: ParsedFile, materials: set, violations: List[Violation]) -> None:
    path = parsed.path
    fields = parsed.fields

    if parsed.kind in ("template", "level", "injury", "unknown"):
        return

    if parsed.guid is None:
        _add_violation(violations, path, 1, "error", "S-02", "Missing guid field")
    elif not (GUID_RE_BRACED.match(parsed.guid) or GUID_RE_BARE.match(parsed.guid)):
        _add_violation(violations, path, _line_for(parsed, "guid"), "error", "G-01", "Invalid guid format")

    template = parsed.template
    if template is None:
        _add_violation(violations, path, 1, "error", "S-07", "Missing template field")
    else:
        allowed = {"small-item", "container", "furniture", "room", "sheet", "level"}
        if template not in allowed:
            _add_violation(violations, path, _line_for(parsed, "template"), "error", "S-07", f"Unknown template '{template}'")

    if _as_string(fields.get("id")) is None:
        _add_violation(violations, path, 1, "error", "S-04", "Missing id field")
    if _as_string(fields.get("name")) is None:
        _add_violation(violations, path, 1, "error", "S-06", "Missing name field")

    if parsed.kind == "object":
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
        elif parsed.material not in materials:
            _add_violation(violations, path, _line_for(parsed, "material"), "error", "MAT-02", f"Unknown material '{parsed.material}'")

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


def _load_materials(project_root: Path) -> set:
    materials_path = project_root / "src" / "engine" / "materials" / "init.lua"
    if not materials_path.exists():
        return set()
    contents = materials_path.read_text(encoding="utf-8")
    materials = set()
    in_registry = False
    depth = 0
    for line in contents.splitlines():
        if not in_registry:
            if "materials.registry" in line and "{" in line:
                in_registry = True
                depth += line.count("{") - line.count("}")
            continue
        m = re.match(r"\s*([a-zA-Z0-9_]+)\s*=\s*\{", line)
        if m:
            materials.add(m.group(1))
        depth += line.count("{") - line.count("}")
        if depth <= 0:
            break
    return materials


def _collect_lua_files(path: Path) -> List[Path]:
    if path.is_file():
        return [path] if path.suffix == ".lua" else []
    lua_files: List[Path] = []
    for root, _, files in os.walk(path):
        for filename in files:
            if filename.endswith(".lua"):
                lua_files.append(Path(root) / filename)
    return lua_files


def _format_text(violations: List[Violation]) -> str:
    lines = []
    for v in violations:
        lines.append(f"{v.file} : {v.line} : {v.severity.upper()} : {v.rule_id} : {v.message}")
    return "\n".join(lines)


def _format_json(violations: List[Violation], files_scanned: int, exit_code: int) -> str:
    payload = {
        "meta_check_version": "1.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "files_scanned": files_scanned,
        "violations": [
            {
                "file": v.file,
                "line": v.line,
                "severity": v.severity,
                "rule_id": v.rule_id,
                "message": v.message,
            }
            for v in violations
        ],
        "summary": {
            "total_files": files_scanned,
            "errors": sum(1 for v in violations if v.severity == "error"),
            "warnings": sum(1 for v in violations if v.severity == "warning"),
            "infos": sum(1 for v in violations if v.severity == "info"),
        },
        "exit_code": exit_code,
    }
    return json.dumps(payload, indent=2)


def main() -> int:
    parser_cli = argparse.ArgumentParser(description="Meta-check validator for MMO meta files")
    parser_cli.add_argument("path", nargs="?", default="src/meta/", help="File or directory to validate")
    parser_cli.add_argument("--format", default="text", choices=("text", "json"), help="Output format")
    parser_cli.add_argument("--severity", default="all", choices=("all", "warning", "error"), help="Minimum severity to report")
    parser_cli.add_argument("--output", default=None, help="Write output to file")
    parser_cli.add_argument("--verbose", action="store_true", help="Verbose output")

    args = parser_cli.parse_args()

    root = Path(__file__).resolve().parents[2]
    target = Path(args.path)
    if not target.is_absolute():
        target = (root / target).resolve()

    lua_files = _collect_lua_files(target)
    if not lua_files:
        print("No .lua files found.")
        return 65

    materials = _load_materials(root)
    violations: List[Violation] = []
    parsed_files: List[ParsedFile] = []

    for path in lua_files:
        parsed = _parse_file(path, violations)
        if parsed:
            parsed_files.append(parsed)

    for parsed in parsed_files:
        _validate_file(parsed, materials, violations)

    guid_map: Dict[str, List[ParsedFile]] = {}
    keyword_map: Dict[str, List[ParsedFile]] = {}
    for parsed in parsed_files:
        if parsed.guid:
            guid_map.setdefault(parsed.guid, []).append(parsed)
        if parsed.kind == "object":
            for keyword in parsed.keywords:
                keyword_map.setdefault(keyword.lower(), []).append(parsed)

    for guid, files in guid_map.items():
        if len(files) > 1:
            for parsed in files:
                _add_violation(violations, parsed.path, _line_for(parsed, "guid"), "error", "XF-01", f"Duplicate guid '{guid}'")

    for keyword, files in keyword_map.items():
        if len(files) > 1:
            file_list = ", ".join(sorted({f.path.name for f in files}))
            for parsed in files:
                _add_violation(violations, parsed.path, _line_for(parsed, "keywords"), "warning", "XF-03", f"Keyword '{keyword}' appears in multiple files: {file_list}")

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

    if args.format == "json":
        output = _format_json(filtered, len(lua_files), exit_code)
    else:
        output = _format_text(filtered)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
    else:
        if output:
            print(output)

    if args.verbose:
        print(f"Files scanned: {len(lua_files)}")
        print(f"Violations: {len(filtered)}")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
