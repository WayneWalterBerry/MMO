-- match.lua -- FSM-managed object (see meta/fsms/match.lua for state definitions)
-- States: unlit -> lit -> spent (terminal). 3-turn burn when lit.
return {
    guid = "009b0347-2ba3-45d1-a733-7a587ad1f5c9",

    id = "match",
    name = "a wooden match",
    keywords = {"match", "stick", "matchstick", "lucifer", "wooden match"},
    description = "A small wooden match with a bulbous red-brown tip. The head is slightly rough to the touch and smells faintly of sulphur. Unlit and inert -- it needs a striker surface to ignite.",

    on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
    on_smell = "Faintly sulfurous.",

    size = 1,
    weight = 0.01,
    categories = {"small", "consumable"},
    portable = true,
    casts_light = false,

    location = nil,

    _fsm_id = "match",
    _state = "unlit",
}
