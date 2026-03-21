# Test Pass Directory

This directory contains organized test pass reports from the MMO project team.

## Directory Structure

### `/gameplay`
System and gameplay test passes written by **Nelson**.

These test passes verify core gameplay mechanics, system interactions, and overall playtest sessions. Each pass is a comprehensive report of a playtesting session covering mechanics, balance, edge cases, and integration points.

**Current status:** 9 passes recorded (2026-03-19 through 2026-03-21)

### `/objects`
Object-specific test passes written by **Lisa**.

These test passes focus on verifying object properties, behaviors, state mutations, material properties, and engine integrations. Each pass covers detailed verification of object attributes added by developers.

**Current status:** 1 pass recorded (2026-03-21)

## Naming Convention

All test pass files follow this format:

```
YYYY-MM-DD-pass-NNN.md
```

Where:
- **YYYY-MM-DD** = Date the test pass was completed (ISO 8601 format)
- **pass-NNN** = Sequential pass number within each subfolder (zero-padded to 3 digits)

**Examples:**
- `2026-03-19-pass-001.md` — First gameplay test pass
- `2026-03-20-pass-005.md` — Fifth gameplay test pass
- `2026-03-21-pass-001.md` — First objects test pass

Each subfolder maintains its own sequential numbering.

## Ownership & Responsibilities

| Subfolder | Owner | Purpose | Reporting |
|-----------|-------|---------|-----------|
| `gameplay/` | Nelson | System playtests, mechanics verification, integration testing | Comprehensive session reports |
| `objects/` | Lisa | Object behavior, properties, mutations, engine integration | Detailed verification passes |

## What Each Test Pass Should Contain

Every test pass report should include:

1. **Header information** — Title, date, tester name, build version
2. **Scope** — What systems/objects are being tested
3. **Test methodology** — How the testing was conducted
4. **Test cases & results** — Detailed findings, pass/fail status for each item
5. **Issues found** — Any bugs, inconsistencies, or areas needing attention
6. **Sign-off** — Confirmation of pass completion and tester signature

## Creating a New Test Pass

When ready to create a new test pass:

1. **Determine the subfolder**: Use `gameplay/` for system tests, `objects/` for object tests
2. **Get the next sequence number**: Count existing passes in that subfolder and increment
3. **Name the file**: `YYYY-MM-DD-pass-NNN.md` (today's date, zero-padded sequence)
4. **Write the report**: Follow the template structure above
5. **Commit with git**: Preserve the history of the test pass

**Example commands:**
```bash
# Create a new gameplay test (if pass-009 is latest, next is pass-010)
echo "# Playtest Report 010 — Nelson the Tester" > test-pass/gameplay/2026-03-22-pass-010.md

# Create a new objects test (if pass-001 is latest, next is pass-002)
echo "# Object Test Pass — 2026-03-22" > test-pass/objects/2026-03-22-pass-002.md
```

## References

- [Test Pass Charter](../docs/) — Detailed requirements for test passes
- [Project Roadmap](../plan/) — Overall project timeline and milestones
