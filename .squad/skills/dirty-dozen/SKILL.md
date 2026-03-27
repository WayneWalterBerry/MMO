# Skill: The Dirty Dozen

**Confidence:** medium
**Author:** Squad Coordinator (observed pattern, 2026-03-27)
**Domain:** LLM playtesting, parallel bug hunting

## Summary

Spawn 12 Nelson (Tester) instances simultaneously, each seeded with a different gameplay scenario, streaming results to independent files, and logging all bugs found as GitHub Issues. The agents hunt aggressively for bugs — they do NOT fix anything.

## When to Use

- After shipping a major feature phase (Phase 2, Phase 3, etc.)
- After implementing a new gameplay system (combat, food, crafting, etc.)
- When Wayne says "playtest", "find bugs", "dirty dozen", or "spawn Nelsons"
- Before a web deploy to validate the build

## Pattern

### Step 1: Clean Up Output Directory

Move any stale files from `test-pass/` root into `test-pass/legacy/`. Keep `README.md` in place.

```powershell
Get-ChildItem -Path "test-pass\*.md" | Where-Object { $_.Name -ne "README.md" } | 
  Move-Item -Destination "test-pass\legacy\"
```

### Step 2: Determine Next Pass Number

Check `test-pass/gameplay/` for the highest existing pass number and increment from there.

### Step 3: Seed 12 Scenarios

Each Nelson gets a UNIQUE gameplay scenario targeting different features. Seed ideas by category:

**Combat & Creatures:**
- Kill each creature type (rat, cat, wolf, spider, bat)
- Kick verb combat
- Multi-creature room encounters

**Death & Reshape:**
- Corpse reshape verification (template switch, sensory text)
- Furniture corpse (wolf — not portable)
- Byproduct drops (spider → silk)
- Inventory drops (wolf → gnawed-bone)

**Food System:**
- Full kill→cook→eat loop (critical path)
- Eat raw meat → food poisoning
- Cook without fire source → rejection
- Corpse spoilage FSM progression

**Cure System:**
- Cure rabies with poultice
- Cure spider venom with antidote
- Late-stage cure rejection

**Navigation & Admin:**
- goto command (all rooms)
- Multi-room exploration
- Sensory exploration (smell, feel in each room)

**Edge Cases:**
- Double-kill (attack already dead creature)
- Take non-portable object
- Cook non-cookable item
- Eat non-food item

### Step 4: Spawn All 12 in Parallel

Use the `task` tool with `mode: "background"` for ALL 12 in a single tool-calling turn. Each agent gets:

```
agent_type: "general-purpose"
mode: "background"
name: "nelson-{pass-number}"
description: "🧪 Nelson-{N}: {scenario description}"
prompt: |
  You are Nelson, the Tester. TEAM ROOT: {team_root}
  Read .squad/skills/llm-play-testing/SKILL.md before starting.

  TASK: LLM playtest {specific scenario}. Run the game in --headless mode.
  Use `goto {room}` to jump directly to the room you need.

  RULES:
  - Do NOT fix any bugs — only document them
  - Hunt aggressively for bugs — try creative inputs, edge cases, unexpected sequences
  - Log every bug found with: command typed, output received, expected vs actual
  - Use `gh issue create` to file bugs as GitHub Issues with label "bug,squad"

  Write full playtest report to: {team_root}/test-pass/gameplay/{date}-pass-{N}-{slug}.md

  ⚠️ RESPONSE ORDER: After ALL tool calls, write plain text summary as FINAL output.
```

### Step 5: Collect Results

As agents complete, read results. Track:
- Total bugs found across all 12
- Severity breakdown (CRITICAL / HIGH / MEDIUM / LOW)
- Which scenarios passed clean vs found issues

### Step 6: File Remaining Bugs

If any Nelson couldn't file bugs themselves (no gh access), the Coordinator files them as a batch using `gh issue create`.

### Step 7: Report Summary

Present a consolidated table to the user:

```
🧪 Dirty Dozen Complete — 12 playtests, {N} bugs filed

| Pass | Scenario | Result | Bugs |
|------|----------|--------|------|
| 042  | goto cmd | ✅ 9/10 | 1 MEDIUM |
| 043  | kill rat | ✅ 6/8  | 2 LOW |
| ...  | ...      | ...    | ...  |
```

## Key Rules

1. **Nelsons NEVER fix bugs** — log only (GitHub Issues + playtest report)
2. **Each Nelson writes to its OWN file** — no shared output files
3. **All 12 launch in ONE tool call** — maximum parallelism
4. **Every bug gets a GitHub Issue** — with `bug,squad` labels
5. **Use `goto` command** for room navigation (skip manual pathfinding)
6. **Use `--headless` mode** for all game execution
7. **Scenarios should cover the MOST RECENT work** — seed from the latest phase/feature

## Anti-Patterns

- ❌ Don't have Nelsons fix bugs they find
- ❌ Don't serialize the 12 spawns (all parallel)
- ❌ Don't reuse the same scenario for multiple Nelsons
- ❌ Don't skip filing GitHub Issues for "minor" bugs
- ❌ Don't let Nelsons write to the same output file

## History

- **2026-03-27:** First use — 12 Nelsons after Phase 3 ship. Found 12 bugs including 1 CRITICAL (defender=nil in combat resolution). Pattern named "The Dirty Dozen" by Wayne Berry.
