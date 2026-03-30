-- candle.lua — FSM-managed consumable light source
-- States: unlit → lit → extinguished (partial, relightable) or spent (terminal)
-- Timer: burn_duration tracks total burn time; remaining_burn tracks partial.
return {
    guid = "{992df7f3-1b8e-4164-939a-3415f8f6ffe3}",
    template = "small-item",

    id = "candle",
    material = "wax",
    keywords = {"candle", "tallow", "tallow candle"},
    size = 1,
    weight = 1,
    categories = {"light source", "small"},
    portable = true,

    -- Initial state (unlit)
    name = "a tallow candle",
    description = "A stubby tallow candle with a blackened wick curling like a burnt finger. It is not lit.",
    on_feel = "A smooth wax cylinder, slightly greasy. It tapers to a blackened wick at the top.",
    on_smell = "Faintly waxy -- old tallow and a memory of smoke.",
    on_listen = "Silent. Wax and wick.",

    -- Sound events (WAVE-1 Track 1A)
    sounds = {
        on_state_lit = "candle-ignite.opus",
        on_verb_blow = "candle-blow.opus",
        on_verb_extinguish = "candle-blow.opus",
    },

    casts_light = false,

    location = nil,

    -- Timer metadata (engine reads these on state transitions)
    burn_duration = 7200,      -- 2 hours game time in seconds
    remaining_burn = 7200,     -- Tracks partial burn across extinguish/relight cycles

    -- Tier 3 goal planner prerequisites
    prerequisites = {
        light = {
            requires = { "fire_source" },
            auto_steps = { "strike match" },
        },
    },

    -- FSM
    initial_state = "unlit",
    _state = "unlit",

    states = {
        unlit = {
            name = "a tallow candle",
            description = "A stubby tallow candle with a blackened wick curling like a burnt finger. It is not lit.",
            on_feel = "A smooth wax cylinder, slightly greasy. It tapers to a blackened wick at the top.",
            on_smell = "Faintly waxy -- old tallow and a memory of smoke.",
            on_listen = "Silent. Wax and wick.",
            casts_light = false,

            on_look = function(self)
                return self.description .. "\n\nIt could be lit, if you had the means."
            end,
        },

        lit = {
            name = "a lit tallow candle",
            description = "A tallow candle burns with a steady yellow flame, throwing warm amber light across the room. Shadows dance on the walls like drunken puppets. Wax pools around the wick and drips slowly down the sides.",
            room_presence = "A candle burns with a warm amber glow.",
            on_feel = "Warm wax, softening near the flame. Careful -- it's hot.",
            on_smell = "Burning wick and melting tallow. Thin smoke curls upward, acrid and animal.",
            on_listen = "A gentle crackling, and the soft hiss of melting wax. The flame whispers to itself.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 2,

            -- Engine schedules this on entry; uses remaining_burn for actual delay
            timed_events = {
                { event = "transition", delay = 7200, to_state = "spent" },
            },

            on_look = function(self)
                return self.description .. "\n\nThe flame shivers with each breath you take."
            end,
        },

        extinguished = {
            name = "a half-burned candle",
            description = "A tallow candle, recently extinguished. The wick is black and still warm, trailing a thin wisp of smoke. Wax has pooled and hardened in rough drips down the sides. It could be relit.",
            room_presence = "A half-burned candle sits dark, a faint wisp of smoke rising from its wick.",
            on_feel = "Rough wax drippings, still warm from recent burning. The wick is soft and pliant between your fingers.",
            on_smell = "Smoke and warm tallow. The ghost of a flame.",
            casts_light = false,

            on_look = function(self)
                return self.description .. "\n\nThe wick is still warm. It could be relit."
            end,
        },

        spent = {
            name = "a spent candle",
            description = "Nothing but a black nub of carbon and a pool of hardened tallow. The candle is gone, consumed entirely. Not even the wick remains.",
            on_feel = "A hard nub of carbon in a pool of hardened wax. Dead.",
            on_smell = "The ghost of burnt tallow. Nothing more.",
            casts_light = false,
            terminal = true,
            consumable = true,

            on_look = function(self)
                return self.description
            end,
        },
    },

    transitions = {
        {
            from = "unlit", to = "lit", verb = "light",
            aliases = {"ignite"},
            requires_tool = "fire_source",
            message = "The wick catches the flame and curls to life, throwing a warm amber glow across the room. Shadows retreat to the corners like startled cats.",
            fail_message = "You have nothing to light it with. The wick stares back at you, cold and uncooperative.",
        },
        {
            from = "lit", to = "extinguished", verb = "extinguish",
            aliases = {"blow", "put out", "snuff"},
            message = "You blow out the candle. A thin trail of smoke rises from the wick. Darkness closes in.",
            mutate = {
                weight = function(w) return math.max(w * 0.7, 0.1) end,
                keywords = { add = "half-burned" },
            },
        },
        {
            from = "extinguished", to = "lit", verb = "light",
            aliases = {"relight", "ignite"},
            requires_tool = "fire_source",
            message = "The wick catches again, and the candle flickers back to life. The room fills with warm amber light.",
            fail_message = "You have nothing to relight it with.",
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The candle flame gutters, sputters, and dies with a final hiss. The last of the tallow is consumed. Darkness returns, absolute and complete.",
            mutate = {
                weight = 0.05,
                size = 0,
                keywords = { add = "nub" },
                categories = { remove = "light source" },
            },
        },
    },

    mutations = {},
}
