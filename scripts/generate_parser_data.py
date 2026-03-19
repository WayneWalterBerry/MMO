#!/usr/bin/env python3
"""
Phase 1: Training Data Generation for Embedding Parser

Scans the Lua source files for verb definitions, object metadata, and room exits,
then generates natural-language command variations as training pairs for the
embedding index.

Requirements (local mode): None beyond Python 3.8+ stdlib
Requirements (llm mode):   pip install openai

Usage:
    python scripts/generate_parser_data.py --mode=local
    python scripts/generate_parser_data.py --mode=llm   # requires OPENAI_API_KEY
    python scripts/generate_parser_data.py --help
"""

import argparse
import csv
import os
import re
import sys
import json
import random
from pathlib import Path
from itertools import product

# ---------------------------------------------------------------------------
# Paths (relative to repo root)
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parent.parent
VERBS_LUA = REPO_ROOT / "src" / "engine" / "verbs" / "init.lua"
OBJECTS_DIR = REPO_ROOT / "src" / "meta" / "objects"
ROOMS_DIR = REPO_ROOT / "src" / "meta" / "world"
OUTPUT_DIR = REPO_ROOT / "data" / "parser"
OUTPUT_CSV = OUTPUT_DIR / "training-pairs.csv"

# ---------------------------------------------------------------------------
# Lua Parsing Helpers
# ---------------------------------------------------------------------------

def extract_verbs(lua_path: Path) -> dict[str, str | None]:
    """
    Parse verbs/init.lua for all handlers["verb"] entries.
    Returns {verb_name: alias_target_or_None}.
    A primary handler has value None; an alias has the target verb name.
    """
    text = lua_path.read_text(encoding="utf-8")

    # Match:  handlers["verb"] = function(...)   → primary
    # Match:  handlers["verb"] = handlers["other"]  → alias
    primary_re = re.compile(r'handlers\["([^"]+)"\]\s*=\s*function\s*\(')
    alias_re = re.compile(r'handlers\["([^"]+)"\]\s*=\s*handlers\["([^"]+)"\]')

    verbs: dict[str, str | None] = {}
    for m in primary_re.finditer(text):
        verbs[m.group(1)] = None
    for m in alias_re.finditer(text):
        verbs[m.group(1)] = m.group(2)

    return verbs


def extract_objects(objects_dir: Path) -> list[dict]:
    """
    Parse each .lua file in objects/ for id, name, and keywords.
    Returns list of dicts: [{id, name, keywords: [str]}].
    """
    objects = []
    if not objects_dir.is_dir():
        print(f"[WARN] Objects directory not found: {objects_dir}", file=sys.stderr)
        return objects

    for lua_file in sorted(objects_dir.glob("*.lua")):
        text = lua_file.read_text(encoding="utf-8")
        obj: dict = {}

        id_match = re.search(r'\bid\s*=\s*"([^"]+)"', text)
        name_match = re.search(r'\bname\s*=\s*"([^"]+)"', text)
        kw_match = re.search(r'keywords\s*=\s*\{([^}]*)\}', text)

        if id_match:
            obj["id"] = id_match.group(1)
        else:
            continue  # skip files without an id

        obj["name"] = name_match.group(1) if name_match else obj["id"]

        if kw_match:
            raw = kw_match.group(1)
            obj["keywords"] = [s.strip().strip('"').strip("'") for s in raw.split(",") if s.strip().strip('"').strip("'")]
        else:
            obj["keywords"] = []

        objects.append(obj)

    return objects


def extract_rooms(rooms_dir: Path) -> list[dict]:
    """
    Parse room .lua files for room id and exit directions.
    Returns list of dicts: [{id, name, exits: [str]}].
    """
    rooms = []
    if not rooms_dir.is_dir():
        print(f"[WARN] Rooms directory not found: {rooms_dir}", file=sys.stderr)
        return rooms

    for lua_file in sorted(rooms_dir.glob("*.lua")):
        text = lua_file.read_text(encoding="utf-8")
        room: dict = {}

        id_match = re.search(r'\bid\s*=\s*"([^"]+)"', text)
        name_match = re.search(r'\bname\s*=\s*"([^"]+)"', text)

        if id_match:
            room["id"] = id_match.group(1)
        else:
            continue

        room["name"] = name_match.group(1) if name_match else room["id"]

        # Extract exit directions: keys of the exits = { ... } table
        exit_dirs = re.findall(r'^\s+(\w+)\s*=\s*\{', text, re.MULTILINE)
        # Filter to common directions (the exits block keys)
        directions = {"north", "south", "east", "west", "up", "down",
                       "northeast", "northwest", "southeast", "southwest",
                       "n", "s", "e", "w", "ne", "nw", "se", "sw"}
        room["exits"] = [d for d in exit_dirs if d.lower() in directions]

        rooms.append(room)

    return rooms


# ---------------------------------------------------------------------------
# Local-Mode Variation Generation (no API calls)
# ---------------------------------------------------------------------------

# Verb synonym groups: canonical verb → list of natural-language alternatives
VERB_SYNONYMS: dict[str, list[str]] = {
    "look":       ["look at", "look", "observe", "gaze at", "peer at", "stare at", "glance at", "inspect"],
    "examine":    ["examine", "inspect", "study", "scrutinize", "check", "check out", "look closely at"],
    "x":          ["x"],
    "find":       ["find", "locate", "spot"],
    "read":       ["read", "peruse", "scan", "skim"],
    "search":     ["search", "rummage through", "look through", "rifle through", "explore"],
    "feel":       ["feel", "touch", "run fingers over", "run hands over", "caress", "fondle", "handle"],
    "touch":      ["touch", "feel", "poke", "prod", "tap"],
    "grope":      ["grope", "fumble at", "grope around"],
    "smell":      ["smell", "sniff", "breathe in", "inhale"],
    "sniff":      ["sniff", "smell", "take a whiff of"],
    "taste":      ["taste", "sample", "try", "nibble"],
    "lick":       ["lick", "taste"],
    "listen":     ["listen to", "listen", "hear", "pay attention to"],
    "hear":       ["hear", "listen to"],
    "take":       ["take", "grab", "pick up", "snag", "snatch", "collect", "gather"],
    "get":        ["get", "fetch", "obtain", "acquire", "retrieve"],
    "pick":       ["pick up", "pick"],
    "grab":       ["grab", "seize", "clutch", "snag"],
    "drop":       ["drop", "release", "let go of", "put down", "set down", "discard", "toss"],
    "open":       ["open", "open up", "pry open", "swing open", "pull open", "unlatch"],
    "close":      ["close", "shut", "slam", "pull closed", "push closed"],
    "shut":       ["shut", "close", "slam shut"],
    "break":      ["break", "smash", "shatter", "destroy", "crack", "bust"],
    "smash":      ["smash", "break", "bash", "crush"],
    "shatter":    ["shatter", "break", "smash to pieces"],
    "tear":       ["tear", "rip", "shred", "tear apart", "pull apart", "rend"],
    "rip":        ["rip", "tear", "rip apart"],
    "inventory":  ["inventory", "i", "check inventory", "what am i carrying", "show inventory"],
    "i":          ["i", "inventory"],
    "light":      ["light", "ignite", "set fire to", "kindle", "set alight"],
    "ignite":     ["ignite", "light", "set ablaze"],
    "extinguish": ["extinguish", "put out", "blow out", "snuff", "douse", "quench"],
    "snuff":      ["snuff", "snuff out", "blow out"],
    "write":      ["write on", "write", "inscribe", "scrawl on", "scribble on", "jot on"],
    "inscribe":   ["inscribe", "engrave", "etch", "carve into"],
    "cut":        ["cut", "slash", "slice", "hack", "carve"],
    "slash":      ["slash", "cut", "slice"],
    "prick":      ["prick", "poke", "jab", "stab lightly", "stick"],
    "sew":        ["sew", "stitch", "mend", "repair"],
    "stitch":     ["stitch", "sew", "mend"],
    "mend":       ["mend", "repair", "fix", "patch"],
    "put":        ["put", "place", "set", "lay", "deposit", "stow"],
    "place":      ["place", "put", "set down", "lay down"],
    "strike":     ["strike", "hit", "whack", "bang"],
    "wear":       ["wear", "put on", "don", "equip", "throw on"],
    "don":        ["don", "put on", "wear"],
    "remove":     ["remove", "take off", "doff", "pull off", "strip off"],
    "eat":        ["eat", "consume", "devour", "munch", "chew", "swallow", "wolf down"],
    "consume":    ["consume", "eat", "ingest"],
    "devour":     ["devour", "eat", "gobble"],
    "burn":       ["burn", "set fire to", "incinerate", "torch", "set ablaze"],
    "time":       ["time", "check time", "what time is it"],
    "help":       ["help", "commands", "what can i do"],
}

ARTICLES = ["", "the ", "a "]
ARTICLE_WEIGHTS = [0.3, 0.5, 0.2]  # bias towards "the"

# Context mapping: verb → likely context for the CSV
VERB_CONTEXT: dict[str, str] = {
    "look": "observation", "examine": "observation", "x": "observation",
    "find": "observation", "read": "observation", "search": "observation",
    "feel": "sensory", "touch": "sensory", "grope": "sensory",
    "smell": "sensory", "sniff": "sensory",
    "taste": "sensory", "lick": "sensory",
    "listen": "sensory", "hear": "sensory",
    "take": "inventory", "get": "inventory", "pick": "inventory", "grab": "inventory",
    "drop": "inventory",
    "open": "interaction", "close": "interaction", "shut": "interaction",
    "break": "interaction", "smash": "interaction", "shatter": "interaction",
    "tear": "interaction", "rip": "interaction",
    "inventory": "meta", "i": "meta",
    "light": "interaction", "ignite": "interaction",
    "extinguish": "interaction", "snuff": "interaction",
    "write": "interaction", "inscribe": "interaction",
    "cut": "interaction", "slash": "interaction",
    "prick": "interaction",
    "sew": "interaction", "stitch": "interaction", "mend": "interaction",
    "put": "inventory", "place": "inventory",
    "strike": "interaction",
    "wear": "inventory", "don": "inventory",
    "remove": "inventory",
    "eat": "interaction", "consume": "interaction", "devour": "interaction",
    "burn": "interaction",
    "time": "meta", "help": "meta",
}

# Verbs that make sense without a direct object
INTRANSITIVE_VERBS = {"look", "search", "listen", "hear", "inventory", "i", "time", "help"}

# Verbs that make sense with a direction instead of an object
DIRECTION_VERBS = {"look", "go", "walk", "run"}


def _pick_article() -> str:
    return random.choices(ARTICLES, weights=ARTICLE_WEIGHTS, k=1)[0]


def _short_name(obj_name: str) -> str:
    """Strip articles from an object name for bare-noun usage."""
    for a in ("a ", "an ", "the ", "some "):
        if obj_name.lower().startswith(a):
            return obj_name[len(a):]
    return obj_name


def generate_local_variations(
    verbs: dict[str, str | None],
    objects: list[dict],
    rooms: list[dict],
    max_variations: int = 0,
) -> list[dict]:
    """
    Generate training pairs using template expansion. No API calls.
    When max_variations > 0, limits per verb+object combo to that many phrases
    (picks the most natural: canonical verb+name, then synonym+name, then keyword forms).
    Returns list of dicts matching CSV schema.
    """
    pairs: list[dict] = []
    phrase_id = 0

    # Collect all exit directions from rooms
    all_directions = set()
    for room in rooms:
        all_directions.update(room.get("exits", []))

    for verb_name in sorted(verbs.keys()):
        synonyms = VERB_SYNONYMS.get(verb_name, [verb_name])
        context = VERB_CONTEXT.get(verb_name, "general")

        # --- Intransitive uses (no object) ---
        if verb_name in INTRANSITIVE_VERBS:
            limit = max_variations if max_variations > 0 else 3
            for syn in synonyms[:limit]:
                phrase_id += 1
                pairs.append({
                    "phrase_id": phrase_id,
                    "phrase_text": syn.strip(),
                    "verb": verb_name,
                    "noun": "",
                    "context": context,
                })

        # --- Direction uses ---
        if verb_name in DIRECTION_VERBS:
            for direction in sorted(all_directions):
                limit = max_variations if max_variations > 0 else 2
                for syn in synonyms[:limit]:
                    phrase_id += 1
                    text = f"{syn} {direction}".strip()
                    pairs.append({
                        "phrase_id": phrase_id,
                        "phrase_text": text,
                        "verb": verb_name,
                        "noun": direction,
                        "context": "navigation",
                    })

        # --- Verb + object combinations ---
        if verb_name not in {"inventory", "i", "time", "help"}:
            for obj in objects:
                obj_id = obj["id"]
                short = _short_name(obj["name"])
                # Build a pool of noun references for this object
                noun_forms: list[str] = []
                noun_forms.append(obj["name"])
                noun_forms.append(short)
                for kw in obj.get("keywords", [])[:4]:
                    noun_forms.append(kw)
                # deduplicate preserving order
                seen: set[str] = set()
                unique_nouns: list[str] = []
                for n in noun_forms:
                    nl = n.lower().strip()
                    if nl and nl not in seen:
                        seen.add(nl)
                        unique_nouns.append(n.lower().strip())

                # When capped, round-robin across synonyms so the index has
                # verb diversity (critical for Tier 2 phrase-text matching).
                # Strategy: each synonym gets one phrase with the best noun form,
                # cycling through synonyms before adding more noun variants.
                combo_count = 0
                cap = max_variations if max_variations > 0 else 0  # 0 = unlimited

                if cap:
                    # Round-robin: cycle synonym → noun pairs
                    generated = []
                    syn_pool = synonyms[:cap]  # use up to N different synonyms
                    noun_pool = unique_nouns[:4]
                    for ni, noun_text in enumerate(noun_pool):
                        if len(generated) >= cap:
                            break
                        for si, syn in enumerate(syn_pool):
                            if len(generated) >= cap:
                                break
                            # Prefer: first round uses each synonym with primary noun
                            idx = ni * len(syn_pool) + si
                            text = f"{syn} {noun_text}".strip()
                            generated.append(text)

                    for text in generated:
                        phrase_id += 1
                        pairs.append({
                            "phrase_id": phrase_id,
                            "phrase_text": text,
                            "verb": verb_name,
                            "noun": obj_id,
                            "context": context,
                        })
                else:
                    # Unlimited: original full expansion
                    for syn in synonyms[:4]:
                        for noun_text in unique_nouns[:4]:
                            phrase_id += 1
                            text = f"{syn} {noun_text}".strip()
                            pairs.append({
                                "phrase_id": phrase_id,
                                "phrase_text": text,
                                "verb": verb_name,
                                "noun": obj_id,
                                "context": context,
                            })

                            if not noun_text.startswith(("a ", "an ", "the ", "some ")):
                                article = _pick_article()
                                if article:
                                    phrase_id += 1
                                    text2 = f"{syn} {article}{noun_text}".strip()
                                    pairs.append({
                                        "phrase_id": phrase_id,
                                        "phrase_text": text2,
                                        "verb": verb_name,
                                        "noun": obj_id,
                                        "context": context,
                                    })

    return pairs


# ---------------------------------------------------------------------------
# LLM-Mode Variation Generation (OpenAI GPT-4)
# ---------------------------------------------------------------------------

def generate_llm_variations(
    verbs: dict[str, str | None],
    objects: list[dict],
    rooms: list[dict],
) -> list[dict]:
    """
    Generate training pairs using OpenAI GPT-4 for natural language variety.
    Requires OPENAI_API_KEY environment variable.
    """
    try:
        from openai import OpenAI
    except ImportError:
        print("[ERROR] openai package not installed. Run: pip install openai", file=sys.stderr)
        sys.exit(1)

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("[ERROR] OPENAI_API_KEY environment variable not set.", file=sys.stderr)
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    pairs: list[dict] = []
    phrase_id = 0

    # Build object summary for prompt context
    obj_summary = []
    for obj in objects:
        kws = ", ".join(obj.get("keywords", [])[:3])
        obj_summary.append(f"  - {obj['id']} ({obj['name']}): keywords=[{kws}]")
    obj_block = "\n".join(obj_summary)

    # Collect unique canonical verbs (skip aliases to avoid redundant API calls)
    canonical_verbs = [v for v, alias in sorted(verbs.items()) if alias is None]

    for verb in canonical_verbs:
        context = VERB_CONTEXT.get(verb, "general")

        prompt = f"""You are generating training data for a text adventure game parser.

The verb is: "{verb}"

Here are the game objects:
{obj_block}

Generate exactly 50 natural-language command variations that a player might type
to use the verb "{verb}" with various objects. Include:
- Different phrasings (formal, casual, terse)
- Article variations ("the", "a", or none)
- Synonym usage for both verb and object references
- Some commands with just the verb (no object) if it makes sense

Output as JSON array of objects:
[{{"text": "grab the brass key", "verb": "{verb}", "noun": "brass-key", "context": "{context}"}}]

Only output the JSON array, nothing else."""

        try:
            response = client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.8,
                max_tokens=4000,
            )
            content = response.choices[0].message.content.strip()
            # Parse JSON from response
            if content.startswith("```"):
                content = content.split("```")[1]
                if content.startswith("json"):
                    content = content[4:]
            variations = json.loads(content)

            for var in variations:
                phrase_id += 1
                pairs.append({
                    "phrase_id": phrase_id,
                    "phrase_text": var["text"],
                    "verb": var.get("verb", verb),
                    "noun": var.get("noun", ""),
                    "context": var.get("context", context),
                })
            print(f"  [{verb}] Generated {len(variations)} variations via GPT-4")

        except Exception as e:
            print(f"  [{verb}] API error: {e}", file=sys.stderr)
            # Fall back to local generation for this verb
            local_pairs = generate_local_variations(
                {verb: verbs[verb]}, objects, rooms
            )
            for lp in local_pairs:
                phrase_id += 1
                lp["phrase_id"] = phrase_id
                pairs.append(lp)
            print(f"  [{verb}] Fell back to local mode ({len(local_pairs)} variations)")

    return pairs


# ---------------------------------------------------------------------------
# Deduplication
# ---------------------------------------------------------------------------

def deduplicate(pairs: list[dict]) -> list[dict]:
    """Remove exact-text duplicates, re-number IDs."""
    seen: set[str] = set()
    unique: list[dict] = []
    for p in pairs:
        key = p["phrase_text"].lower().strip()
        if key not in seen:
            seen.add(key)
            unique.append(p)
    # Re-number
    for i, p in enumerate(unique, start=1):
        p["phrase_id"] = i
    return unique


# ---------------------------------------------------------------------------
# CSV Output
# ---------------------------------------------------------------------------

def write_csv(pairs: list[dict], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["phrase_id", "phrase_text", "verb", "noun", "context"])
        writer.writeheader()
        writer.writerows(pairs)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Generate training data for the embedding-based parser.",
        epilog="""
Examples:
  python scripts/generate_parser_data.py --mode=local
  python scripts/generate_parser_data.py --mode=llm
  python scripts/generate_parser_data.py --mode=local --output data/parser/custom.csv
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--mode", choices=["local", "llm"], default="local",
        help="Generation mode. 'local' uses templates (offline, no deps). "
             "'llm' uses OpenAI GPT-4 (requires OPENAI_API_KEY). Default: local",
    )
    parser.add_argument(
        "--output", type=Path, default=OUTPUT_CSV,
        help=f"Output CSV path. Default: {OUTPUT_CSV.relative_to(REPO_ROOT)}",
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="Random seed for reproducible local generation. Default: 42",
    )
    parser.add_argument(
        "--max-variations", type=int, default=0, dest="max_variations",
        help="Max phrase variations per verb+object combo (0 = unlimited). Default: 0",
    )
    args = parser.parse_args()
    random.seed(args.seed)

    print(f"=== Phase 1: Training Data Generation ({args.mode} mode) ===\n")

    # --- Step 1: Extract verbs ---
    print(f"[1/4] Scanning verbs from {VERBS_LUA.relative_to(REPO_ROOT)} ...")
    if not VERBS_LUA.is_file():
        print(f"[ERROR] Verb file not found: {VERBS_LUA}", file=sys.stderr)
        sys.exit(1)
    verbs = extract_verbs(VERBS_LUA)
    primary = sum(1 for v in verbs.values() if v is None)
    aliases = sum(1 for v in verbs.values() if v is not None)
    print(f"       Found {len(verbs)} verbs ({primary} primary, {aliases} aliases)")

    # --- Step 2: Extract objects ---
    print(f"[2/4] Scanning objects from {OBJECTS_DIR.relative_to(REPO_ROOT)}/ ...")
    objects = extract_objects(OBJECTS_DIR)
    print(f"       Found {len(objects)} objects")

    # --- Step 3: Extract rooms ---
    print(f"[3/4] Scanning rooms from {ROOMS_DIR.relative_to(REPO_ROOT)}/ ...")
    rooms = extract_rooms(ROOMS_DIR)
    exit_count = sum(len(r.get("exits", [])) for r in rooms)
    print(f"       Found {len(rooms)} rooms with {exit_count} exits")

    # --- Step 4: Generate variations ---
    print(f"\n[4/4] Generating command variations ({args.mode} mode) ...")
    if args.mode == "llm":
        pairs = generate_llm_variations(verbs, objects, rooms)
    else:
        pairs = generate_local_variations(verbs, objects, rooms, max_variations=args.max_variations)

    pairs = deduplicate(pairs)
    print(f"       Generated {len(pairs)} unique training pairs")

    # --- Write output ---
    write_csv(pairs, args.output)
    print(f"\n✅ Output written to {args.output.relative_to(REPO_ROOT)}")

    # --- Stats ---
    verb_coverage = set(p["verb"] for p in pairs)
    missing = set(verbs.keys()) - verb_coverage
    print(f"\n--- Stats ---")
    print(f"  Total pairs:      {len(pairs)}")
    print(f"  Verbs covered:    {len(verb_coverage)}/{len(verbs)}")
    if missing:
        print(f"  Missing verbs:    {', '.join(sorted(missing))}")
    print(f"  Unique objects:   {len(set(p['noun'] for p in pairs if p['noun']))}")
    print(f"  Output file size: {args.output.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
