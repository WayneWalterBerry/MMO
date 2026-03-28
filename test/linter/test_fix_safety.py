"""
Tests for fix_safety classification in the rule registry.

Validates that every rule has correct fix_safety metadata matching
Bart's audit in docs/meta-lint/fix-safety-audit.md.

References: WAVE-3, D-LINTER-FIX-AUDIT.
"""

import sys
from pathlib import Path

import pytest

# Ensure scripts/meta-lint is importable
_scripts_dir = Path(__file__).resolve().parents[2] / "scripts" / "meta-lint"
if str(_scripts_dir) not in sys.path:
    sys.path.insert(0, str(_scripts_dir))

import importlib.util as _ilu


def _load_mod(name):
    spec = _ilu.spec_from_file_location(name, _scripts_dir / f"{name}.py")
    mod = _ilu.module_from_spec(spec)
    sys.modules.setdefault(name, mod)
    spec.loader.exec_module(mod)
    return mod


_reg = _load_mod("rule_registry")
ALL_RULES = _reg.get_all_rules()
VALID_FIX_SAFETY = {"safe", "unsafe", None}


# ---------------------------------------------------------------------------
# Structural invariants
# ---------------------------------------------------------------------------

def test_minimum_rule_count():
    """Registry must have at least 200 rules (no accidental drops)."""
    assert len(ALL_RULES) >= 200, f"Expected >=200 rules, found {len(ALL_RULES)}"


def test_fix_safety_values_valid():
    """fix_safety must be 'safe', 'unsafe', or None."""
    for rid, rule in ALL_RULES.items():
        assert rule.fix_safety in VALID_FIX_SAFETY, (
            f"{rid} has invalid fix_safety={rule.fix_safety!r}")


def test_fixable_rules_have_safety_classification():
    """fixable=True rules must declare fix_safety as 'safe' or 'unsafe'."""
    for rid, rule in ALL_RULES.items():
        if rule.fixable:
            assert rule.fix_safety in ("safe", "unsafe"), (
                f"{rid} is fixable but fix_safety={rule.fix_safety!r}")


def test_non_fixable_rules_have_none_safety():
    """fixable=False rules must have fix_safety=None."""
    for rid, rule in ALL_RULES.items():
        if not rule.fixable:
            assert rule.fix_safety is None, (
                f"{rid} not fixable but fix_safety={rule.fix_safety!r} (expected None)")


# ---------------------------------------------------------------------------
# Spot-checks from the audit doc (10 rules across all three classes)
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("rule_id", [
    "S-01", "S-02", "G-01", "TD-04", "TD-11", "SN-02", "FSM-04", "TR-01",
])
def test_known_safe_rules(rule_id):
    """Rules audited as 'safe' must be fixable with fix_safety='safe'."""
    rule = ALL_RULES[rule_id]
    assert rule.fixable is True, f"{rule_id} should be fixable"
    assert rule.fix_safety == "safe", f"{rule_id} should be safe"


@pytest.mark.parametrize("rule_id", [
    "S-11", "TD-07", "TD-23", "XF-03", "INJ-08",
])
def test_known_unsafe_rules(rule_id):
    """Rules audited as 'unsafe' must be fixable with fix_safety='unsafe'."""
    rule = ALL_RULES[rule_id]
    assert rule.fixable is True, f"{rule_id} should be fixable"
    assert rule.fix_safety == "unsafe", f"{rule_id} should be unsafe"


@pytest.mark.parametrize("rule_id", [
    "PARSE-01", "S-07", "XF-01", "TD-02", "TD-03",
])
def test_known_not_fixable_rules(rule_id):
    """Rules audited as 'false' must not be fixable, fix_safety=None."""
    rule = ALL_RULES[rule_id]
    assert rule.fixable is False, f"{rule_id} should not be fixable"
    assert rule.fix_safety is None, f"{rule_id} should be None"
