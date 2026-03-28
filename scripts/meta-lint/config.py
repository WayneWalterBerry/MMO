"""
Configuration loader for meta-check.

Supports a `.meta-check.json` config file at project root with per-rule
overrides for severity and enable/disable.

Config format:
{
    "rules": {
        "XF-03": { "enabled": false },
        "XR-05b": { "enabled": true, "severity": "error" }
    },
    "categories": {
        "injury": { "enabled": false }
    },
    "keyword_allowlist": ["garment", "clothing", "container"],
    "orphan_allowlist": {
        "matchbox-open": "mutation-target",
        "glass-shard": "mutation-target"
    }
}

Missing keys inherit defaults from rule_registry.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Set

import importlib.util
import os
import sys

_dir = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("rule_registry", os.path.join(_dir, "rule_registry.py"))
rule_registry = importlib.util.module_from_spec(_spec)
sys.modules.setdefault("rule_registry", rule_registry)
_spec.loader.exec_module(rule_registry)


# ---------------------------------------------------------------------------
# Environment profiles — per-level/sandbox rule overrides
# ---------------------------------------------------------------------------

ENVIRONMENTS: Dict[str, Dict] = {
    "level-01": {
        "profile": "strict",
        "disable": [],
    },
    "level-02": {
        "profile": "moderate",
        "disable": ["XF-03"],
    },
    "sandbox": {
        "profile": "permissive",
        "disable": ["S-12", "S-13", "XR-05"],
    },
}


def get_environment(name: str) -> Optional[Dict]:
    """Return an environment profile by name, or None if unknown."""
    return ENVIRONMENTS.get(name)


def apply_environment(cfg: "CheckConfig", env_name: str) -> "CheckConfig":
    """Disable rules specified by an environment profile.

    Raises ValueError for unknown environment names.
    """
    env = get_environment(env_name)
    if env is None:
        raise ValueError(
            f"Unknown environment '{env_name}'. "
            f"Valid environments: {', '.join(sorted(ENVIRONMENTS))}"
        )
    for rule_id in env.get("disable", []):
        cfg.rules[rule_id] = RuleConfig(enabled=False)
    return cfg


# Per-rule configuration defaults.  Rules can declare structured parameters
# here; user overrides in .meta-check.json are merged on top at load time.
DEFAULT_RULE_CONFIG: Dict[str, Dict] = {
    "XF-03": {
        "allowed_shared": ["match", "key", "door"],
        "cross_room_severity": "info",
    },
}


def get_rule_config(rule_id: str, key: str, default=None):
    """Look up a per-rule configuration value from defaults.

    Returns the value for *key* under *rule_id*, or *default* if the rule
    or key is not present in DEFAULT_RULE_CONFIG.
    """
    rule = DEFAULT_RULE_CONFIG.get(rule_id)
    if rule is None:
        return default
    return rule.get(key, default)


@dataclass
class RuleConfig:
    enabled: bool = True
    severity: Optional[str] = None   # None = use registry default


@dataclass
class CheckConfig:
    rules: Dict[str, RuleConfig] = field(default_factory=dict)
    disabled_categories: Set[str] = field(default_factory=set)
    keyword_allowlist: Set[str] = field(default_factory=set)
    orphan_allowlist: Dict[str, str] = field(default_factory=dict)
    squad_routing: Optional[Dict[str, str]] = None
    rule_params: Dict[str, Dict] = field(default_factory=dict)

    def get_rule_config(self, rule_id: str, key: str, default=None):
        """Look up per-rule config: user overrides first, then defaults."""
        user = self.rule_params.get(rule_id)
        if user is not None:
            val = user.get(key)
            if val is not None:
                return val
        return get_rule_config(rule_id, key, default)

    def is_rule_enabled(self, rule_id: str) -> bool:
        """Check if a rule is enabled (per-rule overrides beat category)."""
        rc = self.rules.get(rule_id)
        if rc is not None:
            return rc.enabled
        rule = rule_registry.get_rule(rule_id)
        if rule and rule.category in self.disabled_categories:
            return False
        return True

    def effective_severity(self, rule_id: str) -> str:
        """Return configured severity, falling back to registry default."""
        rc = self.rules.get(rule_id)
        if rc is not None and rc.severity is not None:
            return rc.severity
        return rule_registry.get_default_severity(rule_id)

    def is_keyword_allowed(self, keyword: str) -> bool:
        """Return True if a keyword is in the collision allowlist."""
        return keyword.lower() in self.keyword_allowlist

    def is_orphan_allowed(self, object_id: str) -> bool:
        """Return True if an object ID is in the GUID-02 orphan allowlist."""
        return object_id in self.orphan_allowlist


_VALID_SEVERITIES = {"error", "warning", "info"}


def load_config(project_root: Path) -> CheckConfig:
    """Load .meta-check.json from project root. Returns defaults if absent."""
    config_path = project_root / ".meta-check.json"
    if not config_path.exists():
        return CheckConfig()
    return parse_config(config_path.read_text(encoding="utf-8"))


def parse_config(json_text: str) -> CheckConfig:
    """Parse config JSON text into a CheckConfig."""
    data = json.loads(json_text)
    cfg = CheckConfig()

    rules_data = data.get("rules", {})
    for rule_id, opts in rules_data.items():
        rc = RuleConfig()
        if "enabled" in opts:
            rc.enabled = bool(opts["enabled"])
        if "severity" in opts:
            sev = opts["severity"].lower()
            if sev not in _VALID_SEVERITIES:
                raise ValueError(f"Invalid severity '{sev}' for rule {rule_id}")
            rc.severity = sev
        cfg.rules[rule_id] = rc
        # Collect additional per-rule params (beyond enabled/severity)
        extra = {k: v for k, v in opts.items() if k not in ("enabled", "severity")}
        if extra:
            cfg.rule_params[rule_id] = extra

    categories_data = data.get("categories", {})
    for cat_name, cat_opts in categories_data.items():
        if not cat_opts.get("enabled", True):
            cfg.disabled_categories.add(cat_name)

    allowlist = data.get("keyword_allowlist", [])
    cfg.keyword_allowlist = {kw.lower() for kw in allowlist}

    orphan_data = data.get("orphan_allowlist", {})
    if isinstance(orphan_data, dict):
        cfg.orphan_allowlist = {k: v for k, v in orphan_data.items()}

    routing_data = data.get("squad_routing", None)
    if isinstance(routing_data, dict):
        cfg.squad_routing = routing_data

    return cfg


def write_default_config(project_root: Path) -> Path:
    """Generate a default .meta-check.json with all rules listed."""
    all_rules = rule_registry.get_all_rules()
    rules_section = {}
    for rule_id, meta in sorted(all_rules.items()):
        rules_section[rule_id] = {
            "enabled": True,
            "severity": meta.severity,
        }
    config = {
        "_comment": "meta-check configuration — per-rule overrides",
        "rules": rules_section,
        "categories": {},
        "keyword_allowlist": [],
    }
    out_path = project_root / ".meta-check.json"
    out_path.write_text(json.dumps(config, indent=2), encoding="utf-8")
    return out_path
