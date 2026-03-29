-- engine/sound/defaults.lua
-- Default verb-to-sound fallback table. When an object has no specific
-- sound for an event, the sound manager falls back to these generics.
-- Object-specific sounds in obj.sounds[key] ALWAYS override defaults.
-- See: sound-implementation-plan.md v1.1, Track 0A

return {
    -- Verb interaction sounds (on_verb_*)
    on_verb_break      = "generic-break.opus",
    on_verb_open       = "generic-creak.opus",
    on_verb_close      = "generic-close.opus",
    on_verb_lock       = "generic-lock.opus",
    on_verb_unlock     = "generic-unlock.opus",
    on_verb_light      = "generic-ignite.opus",
    on_verb_extinguish = "generic-extinguish.opus",
    on_verb_eat        = "generic-eat.opus",
    on_verb_drink      = "generic-drink.opus",
    on_verb_drop       = "generic-drop.opus",
    on_verb_take       = "generic-take.opus",
    on_verb_pour       = "generic-pour.opus",

    -- Combat impact sounds (on_verb_*)
    on_verb_hit        = "generic-blunt-hit.opus",
    on_verb_slash      = "generic-slash-hit.opus",
    on_verb_cut        = "generic-slash-hit.opus",
}
