#!/usr/bin/env python3
"""
Tests for meta-check Phase 2: GUID cross-reference and EXIT validation.

Rules tested:
  - GUID-01: Room instance type_id must reference a known object GUID
  - GUID-02: Orphan object not referenced by any room instance
  - GUID-03: Duplicate instance id within same room
  - EXIT-01: Exit target must reference a valid room
  - EXIT-02: Bidirectional exit mismatch
  - _detect_kind: rooms/ directory recognition
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_test_dir = Path(__file__).resolve().parent
_project_root = _test_dir.parent.parent
_scripts_dir = _project_root / "scripts" / "meta-lint"
_lint_script = _scripts_dir / "lint.py"

import importlib.util as _ilu

def _load_mod(name: str, path: Path):
    spec = _ilu.spec_from_file_location(name, path)
    mod = _ilu.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

rule_registry = _load_mod("rule_registry_p2", _scripts_dir / "rule_registry.py")


# ===========================================================================
# Rule Registry Tests
# ===========================================================================

class TestPhase2RuleRegistry(unittest.TestCase):

    def test_guid01_registered(self):
        rule = rule_registry.get_rule("GUID-01")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "error")
        self.assertEqual(rule.category, "guid-xref")

    def test_guid02_registered(self):
        rule = rule_registry.get_rule("GUID-02")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "warning")

    def test_guid03_registered(self):
        rule = rule_registry.get_rule("GUID-03")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "error")

    def test_exit01_registered(self):
        rule = rule_registry.get_rule("EXIT-01")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "error")
        self.assertEqual(rule.category, "exit")

    def test_exit02_registered(self):
        rule = rule_registry.get_rule("EXIT-02")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "warning")

    def test_phase2_rules_count(self):
        """Phase 2 adds 5 new rules to the registry."""
        all_rules = rule_registry.get_all_rules()
        guid_rules = {k: v for k, v in all_rules.items() if k.startswith("GUID-")}
        exit_rules = {k: v for k, v in all_rules.items() if k.startswith("EXIT-")}
        self.assertEqual(len(guid_rules), 3)
        self.assertEqual(len(exit_rules), 2)


# ===========================================================================
# Integration Tests
# ===========================================================================

class TestPhase2Integration(unittest.TestCase):

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp(prefix="meta-lint-p2-",
                                         dir=str(_project_root))
        self.root = Path(self._tmpdir)
        for subdir in ["objects", "templates", "materials", "rooms", "levels"]:
            (self.root / "src" / "meta" / subdir).mkdir(parents=True)

    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _write(self, rel_path: str, content: str):
        p = self.root / rel_path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
        return p

    def _run_lint(self, target_path: str = "src/meta/", config_json: str = None):
        cmd = [sys.executable, str(_lint_script),
               str(self.root / target_path), "--format", "json"]
        if config_json:
            cfg_path = self.root / ".meta-check.json"
            cfg_path.write_text(config_json, encoding="utf-8")
            cmd.extend(["--config", str(cfg_path)])
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.root))
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            self.fail(f"lint.py produced invalid JSON:\nSTDOUT: {result.stdout}\nSTDERR: {result.stderr}")
        return data.get("exit_code", -1), data.get("violations", [])

    def _setup_base_files(self):
        self._write("src/meta/materials/wood.lua",
            'return { guid = "{be03ddf1-2bb1-48e7-bf67-5fcc6e2a79cf}", name = "wood", density = 0.6, hardness = 4, flexibility = 0.3, '
            'absorbency = 0.4, opacity = 1, flammability = 0.7, conductivity = 0.1, '
            'fragility = 0.3, value = 2, ignition_point = 300 }')
        self._write("src/meta/templates/small-item.lua",
            'return { guid = "00000000-0000-0000-0000-000000000001", id = "small-item", '
            'name = "Small Item", keywords = {}, description = "test", size = 1, '
            'weight = 1, portable = true, material = "wood", container = false, '
            'capacity = 0, contents = {} }')

    # -- GUID-01 --

    def test_guid01_valid_type_id(self):
        """No GUID-01 when type_id matches an object GUID."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid01 = [v for v in violations if v["rule_id"] == "GUID-01"]
        self.assertEqual(len(guid01), 0, "Valid type_id should not trigger GUID-01")

    def test_guid01_fabricated_type_id(self):
        """GUID-01 error when type_id does not match any object GUID."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "ffffffff-ffff-ffff-ffff-ffffffffffff" } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid01 = [v for v in violations if v["rule_id"] == "GUID-01"]
        self.assertGreater(len(guid01), 0, "Fabricated type_id should trigger GUID-01")
        self.assertIn("ffffffff", guid01[0]["message"])

    def test_guid01_braced_type_id_matches(self):
        """GUID-01 normalizes braced type_id to match braced object GUID."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}" } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid01 = [v for v in violations if v["rule_id"] == "GUID-01"]
        self.assertEqual(len(guid01), 0)

    def test_guid01_nested_instances(self):
        """GUID-01 validates type_ids in nested relationships."""
        self._setup_base_files()
        self._write("src/meta/objects/table-obj.lua",
            'return { guid = "{aaaaaaaa-0000-0000-0000-000000000001}", '
            'id = "table-obj", template = "small-item", name = "a table", '
            'keywords = {"table"}, description = "A table.", '
            'on_feel = "Solid.", material = "wood" }')
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-0000-0000-0000-000000000002}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "table-obj", type = "Table", '
            'type_id = "aaaaaaaa-0000-0000-0000-000000000001", '
            'on_top = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "ffffffff-0000-0000-0000-ffffffffffff" } '
            '} } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid01 = [v for v in violations if v["rule_id"] == "GUID-01"]
        self.assertEqual(len(guid01), 1)
        self.assertIn("candle", guid01[0]["message"])

    # -- GUID-02 --

    def test_guid02_orphan_object(self):
        """GUID-02 warning for objects not referenced by any room."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, exits = {} }')
        _, violations = self._run_lint()
        guid02 = [v for v in violations if v["rule_id"] == "GUID-02"]
        self.assertGreater(len(guid02), 0)
        msgs = " ".join(v["message"] for v in guid02)
        self.assertIn("candle", msgs)

    def test_guid02_referenced_not_orphan(self):
        """GUID-02 should NOT fire for referenced objects."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid02 = [v for v in violations if v["rule_id"] == "GUID-02"]
        self.assertEqual(len(guid02), 0)

    # -- GUID-03 --

    def test_guid03_duplicate_instance_id(self):
        """GUID-03 error for duplicate instance ids in same room."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" }, '
            '{ id = "candle", type = "Candle", '
            'type_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid03 = [v for v in violations if v["rule_id"] == "GUID-03"]
        self.assertGreater(len(guid03), 0)

    def test_guid03_unique_ids_ok(self):
        """GUID-03 should NOT fire when instance ids are unique."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/objects/torch.lua",
            'return { guid = "{bbbbbbbb-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "torch", template = "small-item", name = "a torch", '
            'keywords = {"torch"}, description = "A torch.", '
            'on_feel = "Warm.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", '
            'instances = { '
            '{ id = "candle", type = "Candle", '
            'type_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" }, '
            '{ id = "torch", type = "Torch", '
            'type_id = "bbbbbbbb-bbbb-cccc-dddd-eeeeeeeeeeee" } '
            '}, exits = {} }')
        _, violations = self._run_lint()
        guid03 = [v for v in violations if v["rule_id"] == "GUID-03"]
        self.assertEqual(len(guid03), 0)

    # -- EXIT-01 --

    def test_exit01_valid_target(self):
        """No EXIT-01 when exit targets a valid room."""
        self._setup_base_files()
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, '
            'exits = { north = { target = "hallway" } } }')
        self._write("src/meta/rooms/hallway.lua",
            'return { guid = "22222222-2222-3333-4444-555555555555", '
            'template = "room", id = "hallway", name = "Hallway", '
            'keywords = {"hallway"}, description = "A hall.", '
            'on_feel = "Cold stone.", instances = {}, '
            'exits = { south = { target = "bedroom" } } }')
        _, violations = self._run_lint()
        exit01 = [v for v in violations if v["rule_id"] == "EXIT-01"]
        self.assertEqual(len(exit01), 0)

    def test_exit01_invalid_target(self):
        """EXIT-01 error when exit targets a non-existent room."""
        self._setup_base_files()
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, '
            'exits = { north = { target = "nonexistent" } } }')
        _, violations = self._run_lint()
        exit01 = [v for v in violations if v["rule_id"] == "EXIT-01"]
        self.assertGreater(len(exit01), 0)
        self.assertIn("nonexistent", exit01[0]["message"])

    # -- EXIT-02 --

    def test_exit02_bidirectional_ok(self):
        """No EXIT-02 when exits are bidirectional."""
        self._setup_base_files()
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, '
            'exits = { north = { target = "hallway" } } }')
        self._write("src/meta/rooms/hallway.lua",
            'return { guid = "22222222-2222-3333-4444-555555555555", '
            'template = "room", id = "hallway", name = "Hallway", '
            'keywords = {"hallway"}, description = "A hall.", '
            'on_feel = "Cold stone.", instances = {}, '
            'exits = { south = { target = "bedroom" } } }')
        _, violations = self._run_lint()
        exit02 = [v for v in violations if v["rule_id"] == "EXIT-02"]
        self.assertEqual(len(exit02), 0)

    def test_exit02_one_way_exit(self):
        """EXIT-02 warning when room A exits to B but B has no exit back."""
        self._setup_base_files()
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, '
            'exits = { north = { target = "hallway" } } }')
        self._write("src/meta/rooms/hallway.lua",
            'return { guid = "22222222-2222-3333-4444-555555555555", '
            'template = "room", id = "hallway", name = "Hallway", '
            'keywords = {"hallway"}, description = "A hall.", '
            'on_feel = "Cold stone.", instances = {}, exits = {} }')
        _, violations = self._run_lint()
        exit02 = [v for v in violations if v["rule_id"] == "EXIT-02"]
        self.assertGreater(len(exit02), 0)
        self.assertIn("hallway", exit02[0]["message"])

    # -- rooms/ directory detection --

    def test_detect_kind_rooms_directory(self):
        """Files in src/meta/rooms/ should be detected as room kind."""
        self._setup_base_files()
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, exits = {} }')
        _, violations = self._run_lint()
        s09 = [v for v in violations if v["rule_id"] == "S-09"
               and "bedroom" in v.get("file", "")]
        self.assertEqual(len(s09), 0, "Room file should not get S-09 object validation")

    # -- Config disable --

    def test_guid02_disabled_via_config(self):
        """GUID-02 can be disabled via .meta-check.json."""
        self._setup_base_files()
        self._write("src/meta/objects/candle.lua",
            'return { guid = "{aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee}", '
            'id = "candle", template = "small-item", name = "a candle", '
            'keywords = {"candle"}, description = "A candle.", '
            'on_feel = "Waxy.", material = "wood" }')
        self._write("src/meta/rooms/bedroom.lua",
            'return { guid = "11111111-2222-3333-4444-555555555555", '
            'template = "room", id = "bedroom", name = "Bedroom", '
            'keywords = {"bedroom"}, description = "A room.", '
            'on_feel = "Cold stone.", instances = {}, exits = {} }')
        config = '{"rules": {"GUID-02": {"enabled": false}}}'
        _, violations = self._run_lint(config_json=config)
        guid02 = [v for v in violations if v["rule_id"] == "GUID-02"]
        self.assertEqual(len(guid02), 0)


if __name__ == "__main__":
    unittest.main()
