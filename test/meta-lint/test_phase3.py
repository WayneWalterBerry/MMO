#!/usr/bin/env python3
"""
Tests for meta-check Phase 3 improvements:
  - Squad routing: rule→owner mapping
  - Incremental caching: SHA-256 file hashing, cache hit/miss
  - Config integration: routing overrides, --by-owner, --no-cache
"""

import json
import os
import sys
import unittest
from pathlib import Path

_test_dir = Path(__file__).resolve().parent
_project_root = _test_dir.parent.parent
_scripts_dir = _project_root / "scripts" / "meta-lint"

import importlib.util as _ilu


def _load_mod(name: str, path: Path):
    spec = _ilu.spec_from_file_location(name, path)
    mod = _ilu.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


rule_registry = _load_mod("rule_registry", _scripts_dir / "rule_registry.py")
config_mod = _load_mod("config", _scripts_dir / "config.py")
squad_routing = _load_mod("squad_routing", _scripts_dir / "squad_routing.py")
cache_mod = _load_mod("cache", _scripts_dir / "cache.py")


class TestSquadRouting(unittest.TestCase):

    def setUp(self):
        self.router = squad_routing.SquadRouter()

    def test_structure_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("S-01"), "Bart")

    def test_parse_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("PARSE-01"), "Bart")

    def test_guid_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("G-01"), "Bart")
        self.assertEqual(self.router.owner_for("GUID-01"), "Bart")
        self.assertEqual(self.router.owner_for("GUID-02"), "Bart")
        self.assertEqual(self.router.owner_for("GUID-03"), "Bart")

    def test_fsm_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("FSM-01"), "Bart")

    def test_transition_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("TR-01"), "Bart")

    def test_sensory_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("SN-01"), "Bart")

    def test_template_rules_to_bart(self):
        self.assertEqual(self.router.owner_for("TD-02"), "Bart")

    def test_injury_rules_to_flanders(self):
        self.assertEqual(self.router.owner_for("INJ-02"), "Flanders")

    def test_material_rules_to_flanders(self):
        self.assertEqual(self.router.owner_for("MD-02"), "Flanders")
        self.assertEqual(self.router.owner_for("MAT-01"), "Flanders")

    def test_room_rules_to_moe(self):
        self.assertEqual(self.router.owner_for("RM-01"), "Moe")

    def test_level_rules_to_comic_book_guy(self):
        self.assertEqual(self.router.owner_for("LV-01"), "Comic Book Guy")

    def test_crossfile_rules_to_smithers(self):
        self.assertEqual(self.router.owner_for("XF-01"), "Smithers")
        self.assertEqual(self.router.owner_for("XF-03"), "Smithers")
        self.assertEqual(self.router.owner_for("XR-01"), "Smithers")

    def test_exit_rules_to_sideshow_bob(self):
        self.assertEqual(self.router.owner_for("EXIT-01"), "Sideshow Bob")
        self.assertEqual(self.router.owner_for("EXIT-02"), "Sideshow Bob")

    def test_creature_rules_to_flanders(self):
        self.assertEqual(self.router.owner_for("CREATURE-001"), "Flanders")

    def test_unknown_rule_unassigned(self):
        self.assertEqual(self.router.owner_for("NOPE-99"), "unassigned")

    def test_config_override(self):
        router = squad_routing.SquadRouter(overrides={"EXIT-*": "Moe"})
        self.assertEqual(router.owner_for("EXIT-01"), "Moe")
        self.assertEqual(router.owner_for("S-01"), "Bart")

    def test_exact_override_beats_pattern(self):
        router = squad_routing.SquadRouter(overrides={"GUID-01": "Nelson"})
        self.assertEqual(router.owner_for("GUID-01"), "Nelson")
        self.assertEqual(router.owner_for("GUID-02"), "Bart")

    def test_routing_table_copy(self):
        table = self.router.get_routing_table()
        table["S-*"] = "Nobody"
        self.assertEqual(self.router.owner_for("S-01"), "Bart")

    def test_all_registered_rules_have_owner(self):
        """Every rule in the registry should route to a named owner."""
        rules = rule_registry.get_all_rules()
        for rule_id in rules:
            owner = self.router.owner_for(rule_id)
            self.assertNotEqual(owner, "unassigned",
                                f"Rule {rule_id} has no squad routing")


class TestCacheModule(unittest.TestCase):

    def test_cross_file_rule_detection(self):
        self.assertTrue(cache_mod.is_cross_file_rule("XF-01"))
        self.assertTrue(cache_mod.is_cross_file_rule("GUID-01"))
        self.assertTrue(cache_mod.is_cross_file_rule("EXIT-01"))
        self.assertTrue(cache_mod.is_cross_file_rule("LV-40"))
        self.assertFalse(cache_mod.is_cross_file_rule("S-01"))
        self.assertFalse(cache_mod.is_cross_file_rule("TD-02"))

    def test_empty_cache(self):
        cache = cache_mod.LintCache()
        self.assertIsNone(cache.get_cached("test.lua", "abc123"))

    def test_cache_update_and_hit(self):
        cache = cache_mod.LintCache()
        violations = [{"file": "t.lua", "line": 1, "severity": "error",
                       "rule_id": "S-01", "message": "Missing table"}]
        cache.update("t.lua", "h1", violations)
        result = cache.get_cached("t.lua", "h1")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["rule_id"], "S-01")

    def test_cache_miss_on_hash_change(self):
        cache = cache_mod.LintCache()
        cache.update("t.lua", "h1", [])
        self.assertIsNone(cache.get_cached("t.lua", "h2"))

    def test_cache_filters_cross_file_rules(self):
        cache = cache_mod.LintCache()
        violations = [
            {"file": "t.lua", "line": 1, "severity": "error",
             "rule_id": "S-01", "message": "Missing"},
            {"file": "t.lua", "line": 5, "severity": "warning",
             "rule_id": "XF-03", "message": "Collision"},
        ]
        cache.update("t.lua", "h1", violations)
        result = cache.get_cached("t.lua", "h1")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["rule_id"], "S-01")

    def test_cache_prune(self):
        cache = cache_mod.LintCache()
        cache.update("a.lua", "h1", [])
        cache.update("b.lua", "h2", [])
        cache.update("deleted.lua", "h3", [])
        cache.prune({"a.lua", "b.lua"})
        self.assertIsNotNone(cache.get_cached("a.lua", "h1"))
        self.assertIsNone(cache.get_cached("deleted.lua", "h3"))

    def test_cache_invalidate(self):
        cache = cache_mod.LintCache()
        cache.update("t.lua", "h1", [])
        cache.invalidate("t.lua")
        self.assertIsNone(cache.get_cached("t.lua", "h1"))

    def test_cache_serialization_roundtrip(self):
        cache = cache_mod.LintCache()
        violations = [{"file": "x.lua", "line": 10, "severity": "warning",
                       "rule_id": "TD-04", "message": "ID mismatch"}]
        cache.update("x.lua", "abc", violations)
        data = {"version": cache.version,
                "entries": {fp: {"file_hash": e.file_hash, "violations": e.violations}
                            for fp, e in cache.entries.items()}}
        loaded = cache_mod.LintCache()
        for fp, ed in json.loads(json.dumps(data))["entries"].items():
            loaded.entries[fp] = cache_mod.CacheEntry(
                file_hash=ed["file_hash"], violations=ed["violations"])
        result = loaded.get_cached("x.lua", "abc")
        self.assertEqual(len(result), 1)

    def test_invalid_cache_version_ignored(self):
        test_dir = _project_root / "test" / "meta-lint"
        cache_path = test_dir / ".test-cache-version.json"
        try:
            cache_path.write_text(json.dumps({"version": 999, "entries": {}}), encoding="utf-8")
            loaded = cache_mod.load_cache(test_dir)
            self.assertEqual(len(loaded.entries), 0)
        finally:
            cache_path.unlink(missing_ok=True)


class TestConfigSquadRouting(unittest.TestCase):

    def test_parse_squad_routing(self):
        cfg = config_mod.parse_config(json.dumps({
            "squad_routing": {"EXIT-*": "Moe", "S-01": "Nelson"}
        }))
        self.assertIsNotNone(cfg.squad_routing)
        self.assertEqual(cfg.squad_routing["EXIT-*"], "Moe")

    def test_no_squad_routing_default(self):
        cfg = config_mod.parse_config(json.dumps({}))
        self.assertIsNone(cfg.squad_routing)

    def test_squad_routing_invalid_type_ignored(self):
        cfg = config_mod.parse_config(json.dumps({"squad_routing": "not a dict"}))
        self.assertIsNone(cfg.squad_routing)


if __name__ == "__main__":
    unittest.main()
