-- torch.lua — FSM-managed consumable light source (Hallway)
-- States: lit → extinguished ↔ relit → spent (terminal)
-- Starts lit in the hallway
return {
    guid = "d95glu9s-6077-4a80-c393-e57156345678",
    template = "small-item",

    id = "torch",
    material = "wood",
    keywords = {"torch", "brand", "firebrand", "flambeau", "light", "fire"},
    size = 3,
    weight = 1.5,
    categories = {"light source", "tool", "wooden"},
    portable = true,

    name = "a burning torch",
    description = "A torch burns with a bright, smoky orange flame. The pitch-soaked rags at the head crackle and spit. It throws harsh, dancing light -- cruder than a candle, but far brighter. Smoke curls upward, blackening the ceiling.",
    room_presence = "Torches burn in iron brackets along the walls, casting dancing orange light.",
    on_feel = "Warm wooden shaft, smooth from use. The head radiates intense heat -- don't touch that end.",
    on_smell = "Burning pitch and smoke. Sharp, resinous, and slightly acrid. A working smell.",
    on_listen = "Crackling and spitting. The pitch pops and hisses. A low roar from the flame.",
    casts_light = true,
    light_radius = 4,
    provides_tool = "fire_source",

    location = nil,

    burn_duration = 10800,
    remaining_burn = 10800,

    prerequisites = {
        light = { requires = {"fire_source"} },
    },

    initial_state = "lit",
    _state = "lit",

    states = {
        lit = {
            name = "a burning torch",
            description = "A torch burns with a bright, smoky orange flame. The pitch-soaked rags at the head crackle and spit. It throws harsh, dancing light -- cruder than a candle, but far brighter. Smoke curls upward, blackening the ceiling.",
            room_presence = "Torches burn in iron brackets along the walls, casting dancing orange light.",
            on_feel = "Warm wooden shaft, smooth from use. The head radiates intense heat -- don't touch that end.",
            on_smell = "Burning pitch and smoke. Sharp, resinous, and slightly acrid. A working smell.",
            on_listen = "Crackling and spitting. The pitch pops and hisses. A low roar from the flame.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 4,

            timed_events = {
                { event = "transition", delay = 10800, to_state = "spent" },
            },
        },

        extinguished = {
            name = "an extinguished torch",
            description = "A torch, recently put out. The head is a charred mass of rags and pitch, still smoking faintly. The wooden shaft is warm. It could be relit.",
            room_presence = "A spent torch smolders in its bracket.",
            on_feel = "Warm wood. The head is hot and sticky with half-melted pitch -- don't grab that end. Charred fabric crumbles at the touch.",
            on_smell = "Hot pitch and smoke. Dying embers.",
            on_listen = "A faint hissing as the pitch cools.",
            casts_light = false,
        },

        spent = {
            name = "a burnt-out torch",
            description = "A burnt-out torch. The wooden shaft is charred halfway down. The head is a lump of carbon and ash. It's done.",
            on_feel = "Charred wood, crumbly. The head is a brittle carbon mass that breaks apart in your hand.",
            on_smell = "Stale smoke and cold carbon.",
            casts_light = false,
            terminal = true,
        },
    },

    transitions = {
        {
            from = "lit", to = "extinguished", verb = "extinguish",
            aliases = {"put out", "douse", "snuff"},
            message = "You smother the torch. The flame dies with a hiss and a curl of acrid smoke. The head glows dull orange for a moment, then fades.",
            mutate = {
                weight = function(w) return w * 0.8 end,
                keywords = { add = "extinguished" },
            },
        },
        {
            from = "extinguished", to = "lit", verb = "light",
            aliases = {"relight", "ignite"},
            requires_tool = "fire_source",
            message = "The pitch catches again, and the torch roars back to life. Bright orange flame, heat, and the smell of burning resin.",
            fail_message = "You have nothing to light it with.",
            mutate = {
                keywords = { remove = "extinguished" },
            },
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The torch gutters, spits, and dies. The last of the pitch is consumed, leaving a charred stump trailing a thin banner of smoke.",
            mutate = {
                weight = 0.5,
                categories = { remove = "light source" },
                keywords = { add = "spent" },
            },
        },
    },

    mutations = {},
}
