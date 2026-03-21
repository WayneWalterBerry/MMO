-- match.lua — FSM-managed consumable (single-use, no relight)
-- States: unlit → lit → spent (terminal). Once out, it's done.
-- Key difference from candle: extinguishing goes to SPENT, not to a relightable state.
return {
    guid = "009b0347-2ba3-45d1-a733-7a587ad1f5c9",

    id = "match",
    material = "wood",
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

    -- Timer metadata
    burn_duration = 30,        -- ~30 seconds game time

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

            timed_events = {
                { event = "transition", delay = 30, to_state = "spent" },
            },
        },

        spent = {
            name = "a spent match",
            description = "A blackened match stub, cold and inert. The head has crumbled away entirely.",
            on_feel = "A cold, blackened stick. Fragile. Dead.",
            on_smell = "Charred wood, and nothing else.",
            casts_light = false,
            terminal = true,
            consumable = true,
        },
    },

    transitions = {
        {
            from = "unlit", to = "lit", verb = "strike",
            aliases = {"light", "ignite"},
            requires_property = "has_striker",
            message = "You drag the match head across the striker strip. It sputters once, twice -- then catches with a sharp hiss and a curl of sulphur smoke. A tiny flame dances at the tip.",
            fail_message = "You need a rough surface to strike it on. A matchbox striker, perhaps.",
            mutate = {
                keywords = { add = "burning" },
            },
        },
        {
            from = "lit", to = "spent", verb = "extinguish",
            aliases = {"blow", "put out"},
            message = "You blow out the match. The blackened head crumbles. It's useless now.",
            mutate = {
                weight = 0.005,
                keywords = { add = "blackened" },
                categories = { add = "useless" },
            },
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The match flame reaches your fingers and dies. You drop the blackened stub.",
            mutate = {
                weight = 0.005,
                keywords = { add = "blackened" },
                categories = { add = "useless" },
            },
        },
    },

    mutations = {},
}
