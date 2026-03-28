"""
Pytest configuration for meta-lint (meta-check) tests.

Provides fixtures for running the linter against synthetic Lua files
in isolated temporary directory structures.
"""

import json
import subprocess
import sys
from pathlib import Path

import pytest

# Project paths
PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_DIR = PROJECT_ROOT / "scripts" / "meta-lint"
LINT_PY = SCRIPTS_DIR / "lint.py"

# Make scripts/meta-lint importable for direct module access
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import importlib.util as _ilu

def _load_sibling(name: str):
    spec = _ilu.spec_from_file_location(name, SCRIPTS_DIR / f"{name}.py")
    mod = _ilu.module_from_spec(spec)
    sys.modules.setdefault(name, mod)
    spec.loader.exec_module(mod)
    return mod

rule_registry = _load_sibling("rule_registry")
config_mod = _load_sibling("config")


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def tmp_meta_dir(tmp_path):
    """Create a temporary src/meta/-like structure for isolated testing.

    Returns the tmp_path root. Files should be written under
    tmp_path / "src" / "meta" / {subdirectory}.
    """
    for subdir in ("objects", "templates", "materials", "world", "rooms",
                   "levels", "injuries", "creatures"):
        (tmp_path / "src" / "meta" / subdir).mkdir(parents=True, exist_ok=True)
    return tmp_path


@pytest.fixture
def lint_runner(tmp_meta_dir):
    """Returns a callable that runs lint.py against the tmp_meta_dir.

    Usage:
        exit_code, violations = lint_runner()
        exit_code, violations = lint_runner(target="src/meta/objects/")
        exit_code, violations = lint_runner(config={"rules": {"XF-03": {"enabled": False}}})
    """
    def _run(target: str = "src/meta/", config: dict = None, extra_flags: list = None):
        target_path = tmp_meta_dir / target
        cmd = [sys.executable, str(LINT_PY), str(target_path),
               "--format", "json", "--no-cache"]
        if config is not None:
            cfg_path = tmp_meta_dir / ".meta-check.json"
            cfg_path.write_text(json.dumps(config), encoding="utf-8")
            cmd.extend(["--config", str(cfg_path)])
        if extra_flags:
            cmd.extend(extra_flags)
        result = subprocess.run(cmd, capture_output=True, text=True,
                                cwd=str(tmp_meta_dir))
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            pytest.fail(
                f"lint.py produced invalid JSON:\n"
                f"STDOUT: {result.stdout}\nSTDERR: {result.stderr}"
            )
        return data.get("exit_code", -1), data.get("violations", [])
    return _run


@pytest.fixture
def sample_object():
    """Minimal valid object Lua content."""
    return (
        'return {\n'
        '    guid = "{10000000-0000-0000-0000-000000000001}",\n'
        '    id = "test-object",\n'
        '    template = "small-item",\n'
        '    name = "a test object",\n'
        '    keywords = {"test", "object"},\n'
        '    description = "A plain test object.",\n'
        '    on_feel = "Smooth and unremarkable.",\n'
        '    material = "wool"\n'
        '}'
    )


@pytest.fixture
def sample_room():
    """Minimal valid room Lua content."""
    return (
        'return {\n'
        '    guid = "{20000000-0000-0000-0000-000000000001}",\n'
        '    id = "test-room",\n'
        '    template = "room",\n'
        '    name = "Test Room",\n'
        '    description = "A bare test room with stone walls.",\n'
        '    on_feel = "Cold stone underfoot.",\n'
        '    keywords = {"room"},\n'
        '    instances = {},\n'
        '    exits = {}\n'
        '}'
    )


@pytest.fixture
def sample_creature():
    """Minimal valid creature Lua content."""
    return (
        'return {\n'
        '    guid = "{30000000-0000-0000-0000-000000000001}",\n'
        '    id = "test-creature",\n'
        '    template = "small-item",\n'
        '    name = "a test creature",\n'
        '    keywords = {"creature"},\n'
        '    description = "A test creature.",\n'
        '    on_feel = "Warm fur.",\n'
        '    material = "wool"\n'
        '}'
    )


@pytest.fixture
def sample_portal():
    """Minimal valid portal Lua content."""
    return (
        'return {\n'
        '    guid = "{40000000-0000-0000-0000-000000000001}",\n'
        '    id = "test-portal",\n'
        '    template = "small-item",\n'
        '    name = "a wooden door",\n'
        '    keywords = {"door", "portal"},\n'
        '    description = "A sturdy wooden door.",\n'
        '    on_feel = "Rough oak planks.",\n'
        '    material = "wool"\n'
        '}'
    )
