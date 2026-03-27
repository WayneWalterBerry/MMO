"""
Configuration loader for meta-check.

Supports a `.meta-check.json` config file at project root with per-rule
overrides for severity and enable/disable.

Config format:
{
    "rules": {
        "XF-03": { "enabled": false },
        "MD-19": { "severity": "warning" },
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
