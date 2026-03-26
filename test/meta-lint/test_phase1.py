#!/usr/bin/env python3
"""
Tests for meta-check Phase 1 improvements:
  - Rule registry metadata
  - Per-rule configuration
  - Smart XF-03 keyword filtering
  - MD-19 melting/ignition conflict detection
  - XR-05b generic material inheritance
  - Safe/unsafe fix classification
"""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

# Add the scripts directory so we can import sibling modules
_test_dir = Path(__file__).resolve().parent
_project_root = _test_dir.parent.parent
_scripts_dir = _project_root / "scripts" / "meta-lint"

# Import modules via importlib (same approach as lint.py)
import importlib.util as _ilu

def _load_mod(name: str, path: Path):
    spec = _ilu.spec_from_file_location(name, path)
    mod = _ilu.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

rule_registry = _load_mod("rule_registry", _scripts_dir / "rule_registry.py")
config_mod = _load_mod("config", _scripts_dir / "config.py")


# ===========================================================================
# Rule Registry Tests
# ===========================================================================

class TestRuleRegistry(unittest.TestCase):

    def test_all_rules_populated(self):
        rules = rule_registry.get_all_rules()
        self.assertGreater(len(rules), 50, "Should have 50+ rules registered")

    def test_get_known_rule(self):
        rule = rule_registry.get_rule("XF-03")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.id, "XF-03")
        self.assertEqual(rule.severity, "warning")
        self.assertEqual(rule.category, "cross-file")
        self.assertTrue(rule.fixable)
        self.assertEqual(rule.fix_safety, "unsafe")

    def test_get_unknown_rule(self):
        self.assertIsNone(rule_registry.get_rule("FAKE-99"))

    def test_default_severity(self):
        self.assertEqual(rule_registry.get_default_severity("S-01"), "error")
        self.assertEqual(rule_registry.get_default_severity("TD-18"), "warning")
        self.assertEqual(rule_registry.get_default_severity("TD-19"), "info")
        # Unknown rule defaults to "warning"
        self.assertEqual(rule_registry.get_default_severity("NOPE"), "warning")

    def test_fixable_rules(self):
        self.assertTrue(rule_registry.is_fixable("TD-04"))
        self.assertFalse(rule_registry.is_fixable("S-01"))

    def test_fix_safety(self):
        self.assertEqual(rule_registry.get_fix_safety("TD-04"), "safe")
        self.assertEqual(rule_registry.get_fix_safety("XF-03"), "unsafe")

    def test_rules_by_category(self):
        material_rules = rule_registry.get_rules_by_category("material")
        self.assertIn("MD-02", material_rules)
        self.assertIn("MD-19", material_rules)
        self.assertNotIn("XF-03", material_rules)

    def test_xr05b_registered(self):
        rule = rule_registry.get_rule("XR-05b")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "warning")
        self.assertEqual(rule.category, "cross-ref")
        self.assertTrue(rule.fixable)

    def test_md19_upgraded_to_warning(self):
        rule = rule_registry.get_rule("MD-19")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "warning")
        self.assertEqual(rule.description, "Melting/ignition point conflict")

    def test_all_rules_have_valid_severity(self):
        for rule_id, meta in rule_registry.get_all_rules().items():
            self.assertIn(meta.severity, ("error", "warning", "info"),
                          f"Rule {rule_id} has invalid severity: {meta.severity}")

    def test_all_rules_have_valid_fix_safety(self):
        for rule_id, meta in rule_registry.get_all_rules().items():
            self.assertIn(meta.fix_safety, ("safe", "unsafe"),
                          f"Rule {rule_id} has invalid fix_safety: {meta.fix_safety}")


# ===========================================================================
# Configuration Tests
# ===========================================================================

class TestConfig(unittest.TestCase):

    def test_default_config(self):
        cfg = config_mod.CheckConfig()
        self.assertTrue(cfg.is_rule_enabled("XF-03"))
        self.assertEqual(cfg.effective_severity("XF-03"), "warning")

    def test_disable_rule(self):
        cfg = config_mod.parse_config(json.dumps({
            "rules": {"XF-03": {"enabled": False}}
        }))
        self.assertFalse(cfg.is_rule_enabled("XF-03"))
        self.assertTrue(cfg.is_rule_enabled("S-01"))

    def test_override_severity(self):
        cfg = config_mod.parse_config(json.dumps({
            "rules": {"MD-19": {"severity": "error"}}
        }))
        self.assertEqual(cfg.effective_severity("MD-19"), "error")
        # Other rules unaffected
        self.assertEqual(cfg.effective_severity("XF-03"), "warning")

    def test_disable_category(self):
        cfg = config_mod.parse_config(json.dumps({
            "categories": {"injury": {"enabled": False}}
        }))
        self.assertFalse(cfg.is_rule_enabled("INJ-02"))
        self.assertFalse(cfg.is_rule_enabled("INJ-20"))
        # Non-injury rules still enabled
        self.assertTrue(cfg.is_rule_enabled("XF-03"))

    def test_rule_override_beats_category(self):
        cfg = config_mod.parse_config(json.dumps({
            "rules": {"INJ-02": {"enabled": True}},
            "categories": {"injury": {"enabled": False}}
        }))
        # INJ-02 explicitly enabled even though category disabled
        self.assertTrue(cfg.is_rule_enabled("INJ-02"))
        # Other injury rules still disabled
        self.assertFalse(cfg.is_rule_enabled("INJ-20"))

    def test_keyword_allowlist(self):
        cfg = config_mod.parse_config(json.dumps({
            "keyword_allowlist": ["door", "Barrel"]
        }))
        self.assertTrue(cfg.is_keyword_allowed("door"))
        self.assertTrue(cfg.is_keyword_allowed("DOOR"))
        self.assertTrue(cfg.is_keyword_allowed("barrel"))
        self.assertFalse(cfg.is_keyword_allowed("sword"))

    def test_invalid_severity_raises(self):
        with self.assertRaises(ValueError):
            config_mod.parse_config(json.dumps({
                "rules": {"XF-03": {"severity": "critical"}}
            }))

    def test_empty_config(self):
        cfg = config_mod.parse_config("{}")
        self.assertTrue(cfg.is_rule_enabled("XF-03"))
        self.assertEqual(cfg.effective_severity("S-01"), "error")

    def test_load_from_nonexistent_path(self):
        cfg = config_mod.load_config(Path("C:\\nonexistent\\path"))
        self.assertTrue(cfg.is_rule_enabled("XF-03"))

    def test_combined_overrides(self):
        cfg = config_mod.parse_config(json.dumps({
            "rules": {
                "XF-03": {"enabled": False},
                "MD-19": {"severity": "error", "enabled": True},
            },
            "categories": {"material": {"enabled": False}},
            "keyword_allowlist": ["test-keyword"]
        }))
        self.assertFalse(cfg.is_rule_enabled("XF-03"))
        self.assertTrue(cfg.is_rule_enabled("MD-19"))
        self.assertEqual(cfg.effective_severity("MD-19"), "error")
        self.assertFalse(cfg.is_rule_enabled("MD-02"))
        self.assertTrue(cfg.is_keyword_allowed("test-keyword"))


# ===========================================================================
# Integration Tests — Run lint.py against synthetic files
# ===========================================================================

class TestCheckIntegration(unittest.TestCase):
    """Tests that run the actual checker against synthetic Lua files."""

    def setUp(self):
        """Create a temporary directory structure mimicking src/meta/."""
        self._tmpdir = tempfile.mkdtemp(prefix="meta-check-test-",
                                        dir=str(_project_root))
        self.root = Path(self._tmpdir)
        for subdir in ["objects", "templates", "materials", "world", "levels", "injuries"]:
            (self.root / "src" / "meta" / subdir).mkdir(parents=True)

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def _write(self, rel_path: str, content: str):
        p = self.root / rel_path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
        return p

    def _run_check(self, target_path: str = "src/meta/", config_json: str = None):
        """Run lint.py and return (exit_code, violations_list)."""
        import subprocess
        cmd = [sys.executable, str(_scripts_dir / "lint.py"),
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

    def test_xf03_category_keywords_filtered(self):
        """Category keywords like 'garment' shouldn't trigger XF-03."""
        self._write("src/meta/materials/wool.lua",
                     'return { guid = "{a32c4964-22f4-4add-a3a9-b51a39db1498}", name = "wool", density = 1, hardness = 1, flexibility = 0.8, absorbency = 0.5, opacity = 1, flammability = 0.3, conductivity = 0.1, fragility = 0.2, value = 1, ignition_point = 300 }')
        self._write("src/meta/templates/small-item.lua",
                     'return { guid = "00000000-0000-0000-0000-000000000001", id = "small-item", name = "Small Item", keywords = {}, description = "test", size = 1, weight = 1, portable = true, material = "wool", container = false, capacity = 0, contents = {} }')
        self._write("src/meta/objects/cloak.lua",
                     'return { guid = "{00000000-0000-0000-0000-000000000010}", id = "cloak", template = "small-item", name = "a cloak", keywords = {"cloak", "garment", "clothing"}, description = "A cloak", on_feel = "Soft.", material = "wool" }')
        self._write("src/meta/objects/trousers.lua",
                     'return { guid = "{00000000-0000-0000-0000-000000000011}", id = "trousers", template = "small-item", name = "trousers", keywords = {"trousers", "garment", "clothing"}, description = "Pants", on_feel = "Rough.", material = "wool" }')

        _, violations = self._run_check()
        xf03 = [v for v in violations if v["rule_id"] == "XF-03"]
        xf03_msgs = " ".join(v["message"] for v in xf03)
        self.assertNotIn("garment", xf03_msgs, "Category keyword 'garment' should be filtered")
        self.assertNotIn("clothing", xf03_msgs, "Category keyword 'clothing' should be filtered")

    def test_xf03_config_allowlist(self):
        """Keywords in the config allowlist shouldn't trigger XF-03."""
        self._write("src/meta/materials/iron.lua",
                     'return { guid = "{e02485b5-dbaa-41d3-a288-0fe9a307b8e4}", name = "iron", density = 7, hardness = 5, flexibility = 0.1, absorbency = 0, opacity = 1, flammability = 0, conductivity = 0.7, fragility = 0.2, value = 2 }')
        self._write("src/meta/templates/small-item.lua",
                     'return { guid = "00000000-0000-0000-0000-000000000001", id = "small-item", name = "Small Item", keywords = {}, description = "test", size = 1, weight = 1, portable = true, material = "iron", container = false, capacity = 0, contents = {} }')
        self._write("src/meta/objects/sword-a.lua",
                     'return { guid = "{00000000-0000-0000-0000-000000000020}", id = "sword-a", template = "small-item", name = "sword", keywords = {"sword", "blade"}, description = "test", on_feel = "Cold.", material = "iron" }')
        self._write("src/meta/objects/sword-b.lua",
                     'return { guid = "{00000000-0000-0000-0000-000000000021}", id = "sword-b", template = "small-item", name = "sword b", keywords = {"shortsword", "blade"}, description = "test", on_feel = "Cold.", material = "iron" }')

        config = json.dumps({"keyword_allowlist": ["blade"]})
        _, violations = self._run_check(config_json=config)
        xf03 = [v for v in violations if v["rule_id"] == "XF-03"]
        xf03_msgs = " ".join(v["message"] for v in xf03)
        self.assertNotIn("blade", xf03_msgs, "Allowlisted keyword 'blade' should be filtered")

    def test_md19_detects_melting_before_ignition(self):
        """MD-19 should warn when melting_point <= ignition_point."""
        self._write("src/meta/materials/wax.lua",
                     'return { guid = "{005f9e64-f6f1-41cc-8195-0aa783e7aafa}", name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1, melting_point = 60, ignition_point = 230 }')
        _, violations = self._run_check("src/meta/materials/")
        md19 = [v for v in violations if v["rule_id"] == "MD-19"]
        self.assertEqual(len(md19), 1)
        self.assertIn("60", md19[0]["message"])
        self.assertIn("230", md19[0]["message"])
        self.assertIn("melts before", md19[0]["message"])
        self.assertEqual(md19[0]["severity"], "warning")

    def test_md19_info_when_ignition_below_melting(self):
        """MD-19 should be info when ignition_point < melting_point."""
        self._write("src/meta/materials/exotic.lua",
                     'return { guid = "{11111111-1111-1111-1111-111111111111}", name = "exotic", density = 2, hardness = 3, flexibility = 0.1, absorbency = 0, opacity = 1, flammability = 0.9, conductivity = 0.5, fragility = 0.1, value = 5, melting_point = 500, ignition_point = 200 }')
        _, violations = self._run_check("src/meta/materials/")
        md19 = [v for v in violations if v["rule_id"] == "MD-19"]
        self.assertEqual(len(md19), 1)
        self.assertEqual(md19[0]["severity"], "info")

    def test_config_disable_rule(self):
        """Disabled rules should produce no violations."""
        self._write("src/meta/materials/wax.lua",
                     'return { guid = "{005f9e64-f6f1-41cc-8195-0aa783e7aafa}", name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1, melting_point = 60, ignition_point = 230 }')
        config = json.dumps({"rules": {"MD-19": {"enabled": False}}})
        _, violations = self._run_check("src/meta/materials/", config_json=config)
        md19 = [v for v in violations if v["rule_id"] == "MD-19"]
        self.assertEqual(len(md19), 0, "Disabled MD-19 should produce no violations")

    def test_config_severity_override(self):
        """Config severity override should change violation severity."""
        self._write("src/meta/materials/wax.lua",
                     'return { guid = "{005f9e64-f6f1-41cc-8195-0aa783e7aafa}", name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1, melting_point = 60, ignition_point = 230 }')
        config = json.dumps({"rules": {"MD-19": {"severity": "error"}}})
        exit_code, violations = self._run_check("src/meta/materials/", config_json=config)
        md19 = [v for v in violations if v["rule_id"] == "MD-19"]
        self.assertTrue(len(md19) > 0)
        self.assertEqual(md19[0]["severity"], "error")

    def test_json_output_includes_fix_metadata(self):
        """JSON output should include fixable and fix_safety fields."""
        self._write("src/meta/materials/iron.lua",
                     'return { guid = "{e02485b5-dbaa-41d3-a288-0fe9a307b8e4}", name = "iron", density = 7, hardness = 5, flexibility = 0.1, absorbency = 0, opacity = 1, flammability = 0, conductivity = 0.7, fragility = 0.2, value = 2 }')
        self._write("src/meta/templates/small-item.lua",
                     'return { guid = "00000000-0000-0000-0000-000000000001", id = "small-item", name = "Small Item", keywords = {}, description = "test", size = 1, weight = 1, portable = true, material = "iron", container = false, capacity = 0, contents = {} }')
        self._write("src/meta/objects/test-obj.lua",
                     'return { guid = "{00000000-0000-0000-0000-000000000030}", id = "test-obj", template = "small-item", name = "test", keywords = {"test"}, description = "test", on_feel = "test.", material = "iron" }')
        _, violations = self._run_check()
        if violations:
            v = violations[0]
            self.assertIn("fixable", v)
            self.assertIn("fix_safety", v)

    def test_disable_category(self):
        """Disabling a category should suppress all rules in it."""
        self._write("src/meta/materials/wax.lua",
                     'return { guid = "{005f9e64-f6f1-41cc-8195-0aa783e7aafa}", name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1, melting_point = 60, ignition_point = 230 }')
        config = json.dumps({"categories": {"material": {"enabled": False}}})
        _, violations = self._run_check("src/meta/materials/", config_json=config)
        material_rules = [v for v in violations if v["rule_id"].startswith("MD-")]
        self.assertEqual(len(material_rules), 0, "All MD-* rules should be suppressed")


if __name__ == "__main__":
    unittest.main()
