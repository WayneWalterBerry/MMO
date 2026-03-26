#!/usr/bin/env python3
"""Tests for material GUID support (#259)."""
import json, os, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path

_test_dir = Path(__file__).resolve().parent
_project_root = _test_dir.parent.parent
_scripts_dir = _project_root / "scripts" / "meta-lint"
_lint_script = _scripts_dir / "lint.py"
import importlib.util as _ilu
def _load_mod(name, path):
    spec = _ilu.spec_from_file_location(name, path)
    mod = _ilu.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod
rule_registry = _load_mod("rule_registry_mat", _scripts_dir / "rule_registry.py")

class TestMaterialGuidRegistry(unittest.TestCase):
    def test_md04_registered_as_error(self):
        rule = rule_registry.get_rule("MD-04")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "error")
    def test_mat03_registered(self):
        rule = rule_registry.get_rule("MAT-03")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "warning")
    def test_mat02_still_error(self):
        rule = rule_registry.get_rule("MAT-02")
        self.assertIsNotNone(rule)
        self.assertEqual(rule.severity, "error")

class TestMaterialGuidIntegration(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.mkdtemp(prefix="meta-lint-mat-", dir=str(_project_root))
        self.root = Path(self._tmpdir)
        for subdir in ["objects", "templates", "materials", "rooms", "levels"]:
            (self.root / "src" / "meta" / subdir).mkdir(parents=True)
    def tearDown(self):
        shutil.rmtree(self._tmpdir, ignore_errors=True)
    def _write(self, rel_path, content):
        p = self.root / rel_path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
    def _run_lint(self, target_path="src/meta/", config_json=None):
        cmd = [sys.executable, str(_lint_script), str(self.root / target_path), "--format", "json"]
        if config_json:
            cfg_path = self.root / ".meta-check.json"
            cfg_path.write_text(config_json, encoding="utf-8")
            cmd.extend(["--config", str(cfg_path)])
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(self.root))
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            self.fail("lint.py invalid JSON")
        return data.get("exit_code", -1), data.get("violations", [])
    def _setup_base_files(self):
        self._write("src/meta/materials/wood.lua", 'return { guid = "{be03ddf1-2bb1-48e7-bf67-5fcc6e2a79cf}", name = "wood", density = 0.6, hardness = 4, flexibility = 0.3, absorbency = 0.4, opacity = 1, flammability = 0.7, conductivity = 0.1, fragility = 0.3, value = 2, ignition_point = 300 }')
        self._write("src/meta/templates/small-item.lua", 'return { guid = "00000000-0000-0000-0000-000000000001", id = "small-item", name = "Small Item", keywords = {}, description = "test", size = 1, weight = 1, portable = true, material = "wood", container = false, capacity = 0, contents = {} }')
    def _obj(self, material):
        return 'return { guid = "{aaaaaaaa-0000-0000-0000-000000000001}", id = "widget", template = "small-item", name = "a widget", keywords = {"widget"}, description = "test", on_feel = "Smooth.", material = "' + material + '" }'
    def test_md04_missing_guid_is_error(self):
        self._write("src/meta/materials/wax.lua", 'return { name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1 }')
        _, violations = self._run_lint("src/meta/materials/")
        md04 = [v for v in violations if v["rule_id"] == "MD-04"]
        self.assertGreater(len(md04), 0)
        self.assertEqual(md04[0]["severity"], "error")
    def test_md04_valid_braced_guid(self):
        self._write("src/meta/materials/wax.lua", 'return { guid = "{005f9e64-f6f1-41cc-8195-0aa783e7aafa}", name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1 }')
        _, violations = self._run_lint("src/meta/materials/")
        md04 = [v for v in violations if v["rule_id"] == "MD-04"]
        self.assertEqual(len(md04), 0)
    def test_md04_bare_guid_is_error(self):
        self._write("src/meta/materials/wax.lua", 'return { guid = "005f9e64-f6f1-41cc-8195-0aa783e7aafa", name = "wax", density = 0.9, hardness = 1, flexibility = 0.5, absorbency = 0, opacity = 0.8, flammability = 0.6, conductivity = 0.01, fragility = 0.4, value = 1 }')
        _, violations = self._run_lint("src/meta/materials/")
        md04 = [v for v in violations if v["rule_id"] == "MD-04"]
        self.assertGreater(len(md04), 0)
    def test_mat02_unknown_name(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("unobtanium"))
        _, violations = self._run_lint()
        mat02 = [v for v in violations if v["rule_id"] == "MAT-02"]
        self.assertGreater(len(mat02), 0)
    def test_mat02_unknown_guid(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("{ffffffff-ffff-ffff-ffff-ffffffffffff}"))
        _, violations = self._run_lint()
        mat02 = [v for v in violations if v["rule_id"] == "MAT-02"]
        self.assertGreater(len(mat02), 0)
    def test_mat02_valid_guid(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("{be03ddf1-2bb1-48e7-bf67-5fcc6e2a79cf}"))
        _, violations = self._run_lint()
        mat02 = [v for v in violations if v["rule_id"] == "MAT-02"]
        self.assertEqual(len(mat02), 0)
    def test_mat02_valid_bare_guid(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("be03ddf1-2bb1-48e7-bf67-5fcc6e2a79cf"))
        _, violations = self._run_lint()
        mat02 = [v for v in violations if v["rule_id"] == "MAT-02"]
        self.assertEqual(len(mat02), 0)
    def test_mat03_name_warns(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("wood"))
        _, violations = self._run_lint()
        mat03 = [v for v in violations if v["rule_id"] == "MAT-03"]
        self.assertGreater(len(mat03), 0)
        self.assertEqual(mat03[0]["severity"], "warning")
    def test_mat03_no_warn_guid(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("{be03ddf1-2bb1-48e7-bf67-5fcc6e2a79cf}"))
        _, violations = self._run_lint()
        mat03 = [v for v in violations if v["rule_id"] == "MAT-03"]
        self.assertEqual(len(mat03), 0)
    def test_mat03_can_disable(self):
        self._setup_base_files()
        self._write("src/meta/objects/widget.lua", self._obj("wood"))
        config = json.dumps({"rules": {"MAT-03": {"enabled": False}}})
        _, violations = self._run_lint(config_json=config)
        mat03 = [v for v in violations if v["rule_id"] == "MAT-03"]
        self.assertEqual(len(mat03), 0)

if __name__ == "__main__":
    unittest.main()
