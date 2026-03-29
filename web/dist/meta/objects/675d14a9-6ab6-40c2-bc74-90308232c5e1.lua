-- oil-lantern.lua — FSM-managed light source (Puzzle 010: Light Upgrade)
-- States: empty → fueled → lit ↔ extinguished → spent → (refuel) fueled
-- Broken state: glass chimney shatters (terminal)
-- Wind-resistant: glass chimney protects flame from gusts
return {
    guid = "{675d14a9-6ab6-40c2-bc74-90308232c5e1}",
    template = "small-item",

    id = "oil-lantern",
    material = "brass",
    keywords = {"lantern", "oil lantern", "lamp", "brass lantern", "hurricane lamp"},
    size = 2,
    weight = 1.2,
    categories = {"light source", "tool", "metal"},
    portable = true,
    wind_resistant = true,

    name = "a brass oil lantern",
    description = "A brass oil lantern with a glass chimney, hinged door, and a carrying ring on top. The oil reservoir is bone dry -- the wick is a brown crisp. It's useless without fuel.",
    room_presence = "A brass lantern sits on a shelf, its glass chimney dark and dusty.",
    on_feel = "Cold brass frame, a glass chimney on one side. A small hinged door. The reservoir inside is dry -- rough metal. A carry ring on top.",
    on_smell = "Old metal and the ghost of lamp oil.",
    on_listen = "Creaks slightly when lifted -- the hinged door swings.",

    -- Sound events (WAVE-1 Track 1A)
    sounds = {
        on_state_lit = "lantern-ignite.opus",
        on_verb_break = "glass-shatter.opus",
    },

    casts_light = false,

    location = nil,

    burn_duration = 14400,
    remaining_burn = 14400,

    prerequisites = {
        light = {
            requires = {"fire_source"},
            requires_state = "fueled",
        },
        fuel = {
            requires = {"lamp-oil"},
        },
    },

    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "a brass oil lantern",
            description = "A brass oil lantern with a glass chimney, hinged door, and a carrying ring on top. The oil reservoir is bone dry -- the wick is a brown crisp. It's useless without fuel.",
            room_presence = "A brass lantern sits on a shelf, its glass chimney dark and dusty.",
            on_feel = "Cold brass frame, a glass chimney on one side. A small hinged door. The reservoir inside is dry -- rough metal. A carry ring on top.",
            on_smell = "Old metal and the ghost of lamp oil.",
            on_listen = "Creaks slightly when lifted -- the hinged door swings.",
            casts_light = false,
        },

        fueled = {
            name = "a fueled brass lantern",
            description = "The lantern's reservoir glistens with oil. The wick has soaked it up -- dark and saturated, ready to burn. The glass chimney shows a distorted view of the wick.",
            on_feel = "Cold brass frame. Inside, the wick is wet and oily to the touch. The reservoir is heavy with oil.",
            on_smell = "Lamp oil -- mineral, slightly acrid.",
            casts_light = false,
        },

        lit = {
            name = "a lit brass lantern",
            description = "The lantern burns with a bright, steady flame behind its glass chimney. Warm amber light radiates in all directions -- brighter and more reliable than a candle. The brass frame heats up.",
            room_presence = "A brass lantern burns with a bright amber glow.",
            on_feel = "A brass lantern with a glass chimney, warm to the touch.",
            on_smell = "Burning lamp oil -- clean, mineral smoke.",
            on_listen = "A low, steady hiss from the wick. The flame purrs.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 3,

            timed_events = {
                { event = "transition", delay = 14400, to_state = "spent" },
            },
        },

        extinguished = {
            name = "an extinguished brass lantern",
            description = "The lantern has been put out. The glass chimney is fogged with soot, and the wick smolders faintly. Oil remains in the reservoir -- it could be relit.",
            on_feel = "Warm brass, cooling quickly. The glass chimney is sooty. Wick still warm. Oil in the reservoir -- you can feel its weight.",
            on_smell = "Smoke and cooling oil. Hot metal.",
            on_listen = "A faint tick as the metal contracts.",
            casts_light = false,
        },

        spent = {
            name = "a spent brass lantern",
            description = "The lantern's reservoir is dry. The wick is a charred black thread. The glass chimney is opaque with soot. It would need more oil to function again.",
            on_feel = "Cold brass. Dry reservoir. Dead wick -- brittle and charred. Sooty glass chimney.",
            on_smell = "Stale smoke and burnt oil residue.",
            casts_light = false,
        },

        broken = {
            name = "a broken brass lantern",
            description = "The glass chimney has shattered, leaving jagged shards in the brass frame. Oil has leaked out and the wick hangs exposed. Even with fuel, the flame would gutter in any breeze. It's ruined.",
            on_feel = "Brass frame intact but the chimney is gone -- jagged glass edges where it used to sit. Careful. The reservoir is cracked and empty.",
            on_smell = "Spilled lamp oil and a sharp mineral edge from broken glass.",
            on_listen = "Loose glass rattles inside the frame.",
            casts_light = false,
            terminal = true,
        },
    },

    transitions = {
        {
            from = "empty", to = "fueled", verb = "pour",
            aliases = {"fill", "fuel"},
            requires_tool = "lamp-oil",
            message = "You carefully pour the oil into the lantern's reservoir. The wick darkens as it soaks up the fuel. The lantern is ready to light.",
            fail_message = "You have no oil to pour into the lantern.",
            mutate = {
                weight = function(w) return w + 0.5 end,
            },
        },
        {
            from = "spent", to = "fueled", verb = "pour",
            aliases = {"fill", "fuel", "refuel"},
            requires_tool = "lamp-oil",
            message = "You pour fresh oil into the spent lantern. The charred wick soaks it up slowly -- dark and heavy. The lantern is ready to burn again.",
            fail_message = "You have no oil to refuel the lantern with.",
            mutate = {
                weight = function(w) return w + 0.5 end,
                keywords = { remove = "spent" },
            },
        },
        {
            from = "fueled", to = "lit", verb = "light",
            aliases = {"ignite"},
            requires_tool = "fire_source",
            message = "You open the hinged door and touch the flame to the wick. It catches immediately -- a bright, steady flame blooms behind the glass chimney. Warm amber light pushes the darkness back. Much better than a candle.",
            fail_message = "You have nothing to light it with.",
        },
        {
            from = "lit", to = "extinguished", verb = "extinguish",
            aliases = {"blow", "put out", "snuff"},
            message = "You lift the glass door and blow out the flame. The wick smolders and dies. Darkness reclaims its territory.",
            mutate = {
                weight = function(w) return math.max(w * 0.85, 1.2) end,
                keywords = { add = "sooty" },
            },
        },
        {
            from = "extinguished", to = "lit", verb = "light",
            aliases = {"relight", "ignite"},
            requires_tool = "fire_source",
            message = "The oily wick catches again. Light returns, steady and warm behind the sooty glass chimney.",
            fail_message = "You have nothing to relight it with.",
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The lantern flame sputters, shrinks, and dies. The oil is exhausted. The last of the light fades to a dull orange glow, then nothing.",
            mutate = {
                weight = 1.2,
                categories = { remove = "light source" },
                keywords = { add = "spent" },
            },
        },
        -- Glass chimney shatters — terminal from any non-broken state
        {
            from = "empty", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "drop"},
            message = "The glass chimney shatters with a bright, sharp crack. Shards scatter across the floor. The brass frame is intact but the lantern is ruined.",
        },
        {
            from = "fueled", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "drop"},
            message = "The glass chimney explodes outward. Oil splashes from the cracked reservoir, pooling on the ground. The brass frame survives but the lantern is done.",
            mutate = {
                weight = function(w) return math.max(w - 0.5, 0.8) end,
            },
        },
        {
            from = "lit", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "drop"},
            message = "The glass chimney shatters and the flame leaps free for a moment before guttering out. Oil drips from the cracked reservoir, the wick sputtering its last. Broken.",
            mutate = {
                weight = function(w) return math.max(w - 0.5, 0.8) end,
                categories = { remove = "light source" },
            },
        },
        {
            from = "extinguished", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "drop"},
            message = "The glass chimney cracks and falls apart in the brass frame. Remaining oil seeps out through the fractures. The lantern is beyond repair.",
            mutate = {
                weight = function(w) return math.max(w - 0.5, 0.8) end,
            },
        },
        {
            from = "spent", to = "broken", verb = "break",
            aliases = {"smash", "shatter", "drop"},
            message = "The sooty glass chimney shatters easily -- it was already weakened by heat. Shards and soot dust scatter. The brass frame is all that remains.",
        },
    },

    mutations = {},
}
