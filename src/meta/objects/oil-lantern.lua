-- oil-lantern.lua — FSM-managed light source (Puzzle 010: Light Upgrade)
-- States: empty → fueled → lit ↔ extinguished → spent (terminal)
return {
    guid = "2e4aj8h9-b5c6-4f67-1289-3465ab234567",
    template = "small-item",

    id = "oil-lantern",
    material = "iron",
    keywords = {"lantern", "oil lantern", "lamp", "iron lantern", "hurricane lamp"},
    size = 2,
    weight = 1.2,
    categories = {"light source", "tool", "metal"},
    portable = true,

    name = "an iron oil lantern",
    description = "An iron oil lantern with a small glass window, hinged door, and a carrying ring on top. The oil reservoir is bone dry -- the wick is a brown crisp. It's useless without fuel.",
    room_presence = "An iron lantern sits on a shelf, its glass panel dark and dusty.",
    on_feel = "Cold iron frame, glass panel on one side. A small hinged door. The reservoir inside is dry -- rough metal. A carry ring on top.",
    on_smell = "Old metal and the ghost of lamp oil.",
    on_listen = "Creaks slightly when lifted -- the hinged door swings.",
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
            name = "an iron oil lantern",
            description = "An iron oil lantern with a small glass window, hinged door, and a carrying ring on top. The oil reservoir is bone dry -- the wick is a brown crisp. It's useless without fuel.",
            room_presence = "An iron lantern sits on a shelf, its glass panel dark and dusty.",
            on_feel = "Cold iron frame, glass panel on one side. A small hinged door. The reservoir inside is dry -- rough metal. A carry ring on top.",
            on_smell = "Old metal and the ghost of lamp oil.",
            on_listen = "Creaks slightly when lifted -- the hinged door swings.",
            casts_light = false,
        },

        fueled = {
            name = "a fueled oil lantern",
            description = "The lantern's reservoir glistens with oil. The wick has soaked it up -- dark and saturated, ready to burn. The glass panel shows a distorted view of the wick.",
            on_feel = "Cold iron frame. Inside, the wick is wet and oily to the touch. The reservoir is heavy with oil.",
            on_smell = "Lamp oil -- mineral, slightly acrid.",
            casts_light = false,
        },

        lit = {
            name = "a lit oil lantern",
            description = "The lantern burns with a bright, steady flame behind its glass panel. Warm amber light radiates in all directions -- brighter and more reliable than a candle. The iron frame heats up.",
            room_presence = "An iron lantern burns with a bright amber glow.",
            on_feel = "Warm iron. The glass panel radiates heat. The carry ring is still cool enough to hold.",
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
            name = "an extinguished oil lantern",
            description = "The lantern has been put out. The glass panel is fogged with soot, and the wick smolders faintly. Oil remains in the reservoir -- it could be relit.",
            on_feel = "Warm iron, cooling quickly. The glass is sooty. Wick still warm. Oil in the reservoir -- you can feel its weight.",
            on_smell = "Smoke and cooling oil. Hot metal.",
            on_listen = "A faint tick as the metal contracts.",
            casts_light = false,
        },

        spent = {
            name = "a spent oil lantern",
            description = "The lantern's reservoir is dry. The wick is a charred black thread. The glass panel is opaque with soot. It would need more oil to function again.",
            on_feel = "Cold iron. Dry reservoir. Dead wick -- brittle and charred. Sooty glass.",
            on_smell = "Stale smoke and burnt oil residue.",
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
            fail_message = "The lantern has no oil. The wick is bone dry -- lighting it would accomplish nothing.",
            mutate = {
                weight = function(w) return w + 0.5 end,
            },
        },
        {
            from = "fueled", to = "lit", verb = "light",
            aliases = {"ignite"},
            requires_tool = "fire_source",
            message = "You open the hinged door and touch the flame to the wick. It catches immediately -- a bright, steady flame blooms behind the glass. Warm amber light pushes the darkness back. Much better than a candle.",
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
            message = "The oily wick catches again. Light returns, steady and warm behind the sooty glass.",
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
    },

    mutations = {},
}
