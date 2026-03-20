-- match.lua — FSM-managed consumable (3-turn burn)
-- States: unlit → lit → spent (terminal). One file, one object, one FSM.
return {
    guid = "009b0347-2ba3-45d1-a733-7a587ad1f5c9",

    id = "match",
    keywords = {"match", "stick", "matchstick", "lucifer", "wooden match"},
    size = 1,
    weight = 0.01,
    categories = {"small", "consumable"},
    portable = true,

    -- Initial state properties (unlit)
    name = "a wooden match",
    description = "A small wooden match with a bulbous red-brown tip. The head is slightly rough to the touch and smells faintly of sulphur. Unlit and inert -- it needs a striker surface to ignite.",
    on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
    on_smell = "Faintly sulfurous.",
    casts_light = false,

    location = nil,

    -- FSM
    initial_state = "unlit",
    _state = "unlit",

    states = {
        unlit = {
            name = "a wooden match",
            description = "A small wooden match with a bulbous red-brown tip. The head is slightly rough to the touch and smells faintly of sulphur. Unlit and inert -- it needs a striker surface to ignite.",
            on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
            on_smell = "Faintly sulfurous.",
            casts_light = false,
        },

        lit = {
            name = "a lit match",
            description = "A small wooden match, burning with a flickering flame. The fire creeps slowly down the stick, consuming it. You have seconds before it reaches your fingers.",
            room_presence = "A match burns with a tiny, wavering flame.",
            on_feel = "HOT! You burn your fingers.",
            on_smell = "Burning sulfur and wood.",
            on_listen = "A faint crackling hiss as the wood burns.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 1,
            burn_remaining = 3,

            on_tick = function(obj)
                obj.burn_remaining = obj.burn_remaining - 1
                if obj.burn_remaining <= 0 then
                    return { trigger = "duration_expired" }
                elseif obj.burn_remaining == 1 then
                    return { warning = "The match flame flickers dangerously low..." }
                else
                    return { warning = "The match burns steadily. (" .. obj.burn_remaining .. " turns remaining)" }
                end
            end,
        },

        spent = {
            name = "a spent match",
            description = "A blackened match stub, cold and inert.",
            on_feel = "A cold, blackened stick. Dead.",
            on_smell = "Charred wood, and nothing else.",
            casts_light = false,
            terminal = true,
        },
    },

    transitions = {
        {
            from = "unlit", to = "lit", verb = "strike",
            aliases = {"light", "ignite"},
            requires_property = "has_striker",
            message = "You drag the match head across the striker strip. It sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke. A tiny flame dances at the tip.",
            fail_message = "You need a rough surface to strike it on. A matchbox striker, perhaps.",
        },
        {
            from = "lit", to = "unlit", verb = "extinguish",
            message = "You pinch the flame out. A thin ribbon of smoke rises from the blackened tip, then nothing. Darkness returns.",
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "duration_expired",
            message = "The match flame dies. Your fingers are cold and dark.",
        },
    },
}
