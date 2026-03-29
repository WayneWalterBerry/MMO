# Sound Plan Review — Smithers (UI/Parser Engineer)

**Plan:** `projects/sound/sound-implementation-plan.md` + `sound-web-pipeline-notes.md`  
**Date:** 2026-03-30  
**Verdict:** ⚠️ Concerns  

---

## Findings

### 1. ✅ Parser Loop Not Affected
The sound system is integrated at event level (FSM, verbs, mutations), not at parsing level. Parser pipeline remains unchanged. ✅ Good separation of concerns.

### 2. ✅ Text Output Canonical
"Every sound-triggering event already produces text output" (from sound-web-pipeline-notes.md). This is correct architecture. Sounds are additive, not substitutive. No codepath where sound replaces text.

Example from plan:
```lua
verbs.break = function(context, noun)
    print(obj.mutations.break.message)  -- "The mirror shatters!" (text always)
    if _G._web_sound and obj.sounds and obj.sounds.on_verb_break then
        _G._web_sound.play(obj.sounds.on_verb_break)  -- sound optional
    end
end
```

This pattern ensures text is unconditional. ✅

### 3. ⚠️ **BLOCKER: Verb Handler Integration Point Undefined**
The plan says WAVE-2 includes "effects pipeline play_sound type" and "verb handler narration integration," but doesn't spec:

**How do verb handlers fire sounds?**

Option A: Each verb handler hardcodes sound calls:
```lua
verbs.listen = function(context, noun)
    print(obj.on_listen)
    _G._web_sound.play("creature-vocalization")  -- hard-coded here
end
```

Option B: Sound manager integrates into effects pipeline (Bart's domain):
```lua
verbs.listen = function(context, noun)
    print(obj.on_listen)
    context.sound_manager:trigger(obj, "listen")  -- generic handler
end
```

**Current risk:** If Option A, I (Smithers) must edit 31+ verb handlers to add sound calls. If Option B, Bart handles it in sound manager. The plan doesn't say which.

**Recommendation:** Bart clarifies in WAVE-0: "Sound manager provides `trigger(obj, event_key)` method. Verb handlers call this generic method (not hardcoded per-verb). Smithers integrates one generic pattern into verbs/init.lua."

### 4. ⚠️ **BLOCKER: Narration Formatting Unclear**
The plan says "Smithers: verb handler narration sounds" but doesn't define what this means.

**Question:** When a creature vocalizes during combat, how does sound integrate with narration?

Example from gameplay:
```
Player types: attack wolf

Expected output (text):
"You strike the wolf with your dagger. It snarls, a deep angry sound."

Expected output (sound):
[combat-hit.ogg plays] then [wolf-snarl.ogg plays]
```

But the timing is subtle. Do I (Smithers) need to:
- (a) Add delays to text output to sync with sound duration?
- (b) Emit text and sound simultaneously (browser timing handles it)?
- (c) Emit all text, then all sounds (fire-and-forget)?

**Current risk:** If sound and text are out of sync, narration feels wrong. But the plan doesn't spec timing.

**Recommendation:** Add to WAVE-2: "Sound + narration timing: text emits first (unconditional), sound fires concurrently (async, non-blocking). No delays in text output. Sound lag is acceptable."

### 5. ⚠️ Concern: Ambiguous "on_listen" Behavior
Objects have `on_listen` text (e.g., "A low growl."). In WAVE-2, when a player types LISTEN, does:

**Scenario:**
```
Player types: listen
Object: wolf (creature)
on_listen: "A low growl."
sounds.on_verb_listen: "wolf-growl-low.ogg"
```

Current code flow:
```lua
verbs.listen = function(context, noun)
    obj = find_object(noun)
    print(obj.on_listen)  -- prints "A low growl."
    -- Now what? Does Smithers or sound_manager fire the sound?
end
```

If sound_manager fires sound automatically on FSM state (creature in "patrol" state), then `on_listen` text describes the sound that's already looping.

**Is the sound:**
- (a) Already ambient-looping (creature state fires it)?
- (b) Fired fresh on the LISTEN verb?
- (c) Both (ambient loop + verb retrigger)?

**Recommendation:** Bart + Smithers coordinate in WAVE-2: "LISTEN verb triggers fresh sound (one-shot) even if creature ambient loop is active. Concurrent one-shots are allowed (max 4 total)."

### 6. ✅ No UI Loop Impact
The terminal UI (status bar, output formatting) doesn't need changes for sound. Sounds are silent to TUI. No fps/latency impact from sound calls (async, no-op on headless). ✅

### 7. ⚠️ Concern: Fallback Error Handling
The plan says "wrapped in pcall() so sound failure never crashes the game."

But from verb handler perspective: if I'm writing:
```lua
verbs.break = function(context, noun)
    local result = do_break(obj)
    context.sound_manager:trigger(obj, "break")  -- might fail
    print("The mirror shatters!")
end
```

What if `context.sound_manager` is nil (headless mode)? I need to check:
```lua
if context.sound_manager then
    context.sound_manager:trigger(...)
end
```

**Current risk:** If the plan expects verb handlers to defensively check `sound_manager`, but doesn't document this pattern, I might miss some verbs.

**Recommendation:** Bart provides a pattern function in `src/engine/sound/init.lua`:
```lua
function M:trigger_safe(obj, event)
    if not self then return end  -- self is nil in headless
    self:trigger(obj, event)
end
```

Then verb handlers use: `context.sound_manager:trigger_safe(obj, "break")` (always safe, nil-safe).

### 8. ✅ Autoplay Policy Understood
Browser autoplay is unlocked by first keypress. This happens in the input handler before any text is printed. So by the time ambient sounds would play (room entry), AudioContext is running. ✅ No issues.

### 9. ⚠️ Concern: Spell/Incantation Verb Sounds
The plan mentions "Tier 3 (polish)" includes "UI/system sounds" (item pickup, drop). But are there any NEW verbs that trigger sounds (e.g., spell incantation with unique sound)?

**Currently:** No new verbs planned, just sounds on existing verbs. ✅ OK.

**But if future:** Smithers would need to define new verb sound behavior. Document this as Phase 2.

### 10. ⚠️ Concern: Combat Integration Vague
Combat is complex (Bart's domain, but I integrate verb output). The plan says "WAVE-2: combat dispatch working" but doesn't spec:

Does a single combat action emit:
- (a) One text line + one sound?
- (b) Multiple text lines (attack description, damage, opponent response) + multiple sounds (hit + opponent vocalization)?
- (c) All text first, then all sounds?

**Current risk:** Combat flow might stutter if sounds interrupt narration.

**Recommendation:** Bart + Smithers coordinate combat sound integration in WAVE-2. Likely: "All combat text first, then all combat sounds (fire-and-forget)."

---

## Consolidated Verdict

**The plan is sound architecturally, but has 2 blockers and 3 concerns around verb handler integration, timing, and error handling patterns.**

### Blockers (Must Fix Before WAVE-2)

1. **Verb handler integration point:** Bart clarifies whether sound calls are (a) per-verb hardcoded or (b) generic sound_manager.trigger() pattern. If (b), Smithers integrates one pattern.
2. **Narration + sound timing:** Document that text emits first (unconditional), sounds fire concurrently (async). No text delays for sound sync.

### Concerns (Strongly Recommended)

3. Ambiguous on_listen behavior: Clarify whether LISTEN verb retriggers sound or ambient loop is sufficient.
4. Fallback error handling: Bart provides nil-safe `trigger_safe()` pattern for defensive verb handler calls.
5. Combat integration specifics: Bart + Smithers detail combat sound sequence (all text first, then all sounds).

---

**Reviewed by:** Smithers (UI/Parser Engineer)  
**Confidence:** Medium (2 blockers, integration points need coordination)  
**Signature:** ⚠️
