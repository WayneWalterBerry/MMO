"""
Test helpers for meta-lint test suites.

Provides convenience functions for running the linter, asserting
on its JSON output, and shared Lua content constants for fixtures.
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_DIR = PROJECT_ROOT / "scripts" / "meta-lint"
LINT_PY = SCRIPTS_DIR / "lint.py"


# ---------------------------------------------------------------------------
# Shared Lua content constants for test scaffolding
# ---------------------------------------------------------------------------

MINIMAL_MATERIAL_WOOL = (
    'return { guid = "{a32c4964-22f4-4add-a3a9-b51a39db1498}", '
    'name = "wool", density = 1, hardness = 1, flexibility = 0.8, '
    'absorbency = 0.5, opacity = 1, flammability = 0.3, '
    'conductivity = 0.1, fragility = 0.2, value = 1, ignition_point = 300 }'
)

MINIMAL_MATERIAL_IRON = (
    'return { guid = "{e02485b5-dbaa-41d3-a288-0fe9a307b8e4}", '
    'name = "iron", density = 7, hardness = 5, flexibility = 0.1, '
    'absorbency = 0, opacity = 1, flammability = 0, '
    'conductivity = 0.7, fragility = 0.2, value = 2 }'
)

MINIMAL_TEMPLATE = (
    'return { guid = "00000000-0000-0000-0000-000000000001", '
    'id = "small-item", name = "Small Item", keywords = {}, '
    'description = "test", size = 1, weight = 1, portable = true, '
    'material = "wool", container = false, capacity = 0, contents = {} }'
)


def write_file(root: Path, rel_path: str, content: str) -> Path:
    """Write a file under root, creating parent dirs as needed."""
    p = root / rel_path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return p


# ---------------------------------------------------------------------------
# Lint runner
# ---------------------------------------------------------------------------

def run_lint(target: str, flags: Optional[List[str]] = None,
             cwd: Optional[str] = None) -> dict:
    """Run lint.py on a target path and return the parsed JSON output.

    Args:
        target: File or directory path to lint.
        flags: Additional CLI flags (e.g., ["--severity", "error"]).
        cwd: Working directory for the subprocess.

    Returns:
        Parsed JSON dict with keys: violations, summary, exit_code, etc.
    """
    cmd = [sys.executable, str(LINT_PY), target, "--format", "json", "--no-cache"]
    if flags:
        cmd.extend(flags)
    result = subprocess.run(
        cmd, capture_output=True, text=True,
        cwd=cwd or str(PROJECT_ROOT)
    )
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        raise RuntimeError(
            f"lint.py produced invalid JSON:\n"
            f"STDOUT: {result.stdout}\nSTDERR: {result.stderr}"
        )


# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

def get_violations(output: dict) -> List[dict]:
    """Extract the violations list from lint output."""
    return output.get("violations", [])


def violations_for_rule(output: dict, rule_id: str) -> List[dict]:
    """Return all violations matching a specific rule ID."""
    return [v for v in get_violations(output) if v["rule_id"] == rule_id]


def assert_violation(output: dict, rule_id: str, msg: str = ""):
    """Assert that at least one violation exists for the given rule_id."""
    matches = violations_for_rule(output, rule_id)
    assert len(matches) > 0, (
        f"Expected violation for {rule_id} but found none. {msg}\n"
        f"All violations: {[v['rule_id'] for v in get_violations(output)]}"
    )


def assert_no_violation(output: dict, rule_id: str, msg: str = ""):
    """Assert that NO violations exist for the given rule_id."""
    matches = violations_for_rule(output, rule_id)
    assert len(matches) == 0, (
        f"Expected no violation for {rule_id} but found {len(matches)}. {msg}\n"
        f"Violations: {matches}"
    )


def count_violations(output: dict, rule_id: str) -> int:
    """Count how many violations exist for a rule_id."""
    return len(violations_for_rule(output, rule_id))


def assert_violation_severity(output: dict, rule_id: str, severity: str,
                               msg: str = ""):
    """Assert that all violations for rule_id have the expected severity."""
    matches = violations_for_rule(output, rule_id)
    assert len(matches) > 0, f"No violations for {rule_id} to check severity"
    for v in matches:
        assert v["severity"] == severity, (
            f"Expected {rule_id} severity='{severity}', "
            f"got '{v['severity']}'. {msg}"
        )
