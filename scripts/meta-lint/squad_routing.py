"""
Squad Routing — Maps rule IDs to owning squad members.

When meta-check reports violations, each one is tagged with the squad
member responsible for fixing it. The Coordinator can use this to
auto-assign work.

Routing precedence:
  1. Exact rule ID match (e.g., "GUID-01" → "Bart")
  2. Category prefix match (e.g., "EXIT-*" → "Sideshow Bob")
  3. Fallback to "unassigned"

Config override via .meta-check.json:
  "squad_routing": {
      "EXIT-*": "Sideshow Bob",
      "GUID-01": "Bart"
  }
"""

from __future__ import annotations

import fnmatch
from typing import Dict, List, Optional, Tuple


_DEFAULT_ROUTING: Dict[str, str] = {
    "S-*":        "Smithers",
    "SI-*":       "Flanders",
    "PARSE-*":    "Bart",
    "G-*":        "Bart",
    "FSM-*":      "Bart",
    "TR-*":       "Bart",
    "SN-*":       "Bart",
    "TD-*":       "Bart",
    "D-*":        "Smithers",
    "T-*":        "Smithers",
    "INJ-*":      "Flanders",
    "MD-*":       "Flanders",
    "MAT-*":      "Flanders",
    "RM-*":       "Moe",
    "LV-*":       "Comic Book Guy",
    "XF-*":       "Smithers",
    "XR-*":       "Smithers",
    "GUID-*":     "Bart",
    "EXIT-*":     "Sideshow Bob",
    "CREATURE-*": "Flanders",
    "LOOT-*":     "Flanders",
}


class SquadRouter:
    """Resolves rule IDs to squad member owners."""

    def __init__(self, overrides: Optional[Dict[str, str]] = None):
        self._table: Dict[str, str] = dict(_DEFAULT_ROUTING)
        if overrides:
            self._table.update(overrides)
        self._exact: Dict[str, str] = {}
        self._patterns: List[Tuple[str, str]] = []
        for pattern, owner in self._table.items():
            if "*" in pattern or "?" in pattern:
                self._patterns.append((pattern, owner))
            else:
                self._exact[pattern] = owner
        self._patterns.sort(key=lambda p: len(p[0]), reverse=True)

    def owner_for(self, rule_id: str) -> str:
        """Return the squad member who owns a given rule."""
        if rule_id in self._exact:
            return self._exact[rule_id]
        for pattern, owner in self._patterns:
            if fnmatch.fnmatch(rule_id, pattern):
                return owner
        return "unassigned"

    def get_routing_table(self) -> Dict[str, str]:
        """Return a copy of the full routing table."""
        return dict(self._table)
