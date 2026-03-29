-- poison-gas-vent-plugged.lua — Mutation target: vent after player plugs it with cloth
-- Source: poison-gas-vent.lua (verb: plug, requires_tool: cloth)
-- Decision: D-EFFECTS-PIPELINE, D-14 (code mutation IS state change)
-- Issue: #403 (broken mutation edge), #162 (original vent)
-- The gas hazard is neutralized. Reverse mutation: unplug → poison-gas-vent
return {
    guid = "{ed54b7b3-c48d-4503-96ec-ae19c0da8ab2}",
    template = "furniture",

    id = "poison-gas-vent-plugged",
    material = "iron",
    keywords = {"vent", "plugged vent", "gas vent", "pipe", "plugged pipe", "blocked vent"},
    size = 3,
    weight = 50,
    categories = {"metal", "mechanism", "disabled"},
    portable = false,
    room_position = "protruding from the wall near the floor",

    effects_pipeline = true,

    is_trap = false,
    is_armed = false,
    is_dangerous = false,
    is_plugged = true,

    name = "a plugged vent pipe",
    description = "A corroded iron pipe protrudes from the wall near the floor, its crack stuffed tight with a wad of cloth. The hissing has stopped. The air is clearing, though a faint sweetness lingers.",
    room_presence = "A cracked iron pipe near the floor has been plugged with cloth. The air is clearing.",
    on_feel = "The pipe is cold iron, rough with corrosion. A wad of cloth is stuffed firmly into the crack — packed tight, not going anywhere. The metal is still beneath your fingers. No vibration, no pressure.",
    on_smell = "A fading sweetness hangs in the air, thin and retreating. The cloying heaviness is gone.",
    on_listen = "Silence. The hissing has stopped completely. Just the faint creak of old iron cooling.",
    on_taste = "The air tastes cleaner. A ghost of sweetness on your tongue, but the numbness is fading.",

    location = nil,

    -- No FSM needed — this is a stable post-mutation state
    -- The only transition is unplug, which mutates back to the source object

    mutations = {
        unplug = {
            becomes = "poison-gas-vent",
            message = "You pull the cloth free. The hissing resumes immediately. The sweet smell creeps back.",
        },
    },

    prerequisites = {
        unplug = {
            requires_state = nil,
            warns = { "hazard", "gas", "re-exposure" },
        },
    },
}
