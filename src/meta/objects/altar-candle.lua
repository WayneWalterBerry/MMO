-- altar-candle.lua — Ceremonial candle, longer-burning than standard candle (Deep Cellar puzzle 017)
-- States: unlit → lit → extinguished (relightable) → spent (terminal)
-- Thicker and taller than regular candle, used in altar/alcove rituals
return {
    guid = "{a677a95b-7f86-4f6c-a4a4-3cbac596240c}",
    template = "small-item",

    id = "altar-candle",
    material = "wax",
    keywords = {"altar candle", "thick candle", "ceremonial candle", "ritual candle", "tall candle"},
    size = 2,
    weight = 2,
    categories = {"light source", "small", "burnable"},
    portable = true,

    name = "a thick altar candle",
    description = "A tall, thick candle of pale beeswax, the kind used in ceremonies. It stands nearly a foot high and is as wide as your wrist. The surface is smooth and faintly golden, stamped with a repeating spiral pattern. The wick is new and white, never lit. It smells of honey and old churches.",
    on_feel = "Smooth, dense beeswax -- heavier than tallow, and slightly tacky. The spiral pattern is raised under your fingertips. The candle is solid and substantial, designed to burn for hours.",
    on_smell = "Honey and beeswax. Sweet, clean, and faintly floral -- nothing like cheap tallow. A ceremonial smell.",
    on_listen = "Silent.",
    on_taste = "Waxy sweetness. Beeswax tastes cleaner than tallow -- almost pleasant, in a bland, honeyed way.",
    casts_light = false,

    location = nil,

    burn_duration = 14400,     -- 4 hours game time (double the regular candle)
    remaining_burn = 14400,

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
            name = "a thick altar candle",
            description = "A tall, thick candle of pale beeswax, the kind used in ceremonies. It stands nearly a foot high and is as wide as your wrist. The surface is smooth and faintly golden, stamped with a repeating spiral pattern. The wick is new and white, never lit. It smells of honey and old churches.",
            on_feel = "Smooth, dense beeswax -- heavier than tallow, and slightly tacky. The spiral pattern is raised under your fingertips. The candle is solid and substantial, designed to burn for hours.",
            on_smell = "Honey and beeswax. Sweet, clean, and faintly floral -- nothing like cheap tallow. A ceremonial smell.",
            on_listen = "Silent.",
            on_taste = "Waxy sweetness. Beeswax tastes cleaner than tallow -- almost pleasant, in a bland, honeyed way.",
            casts_light = false,

            on_look = function(self)
                return self.description .. "\n\nThe thick wick has never been lit. This candle was made to burn for a long time."
            end,
        },

        lit = {
            name = "a lit altar candle",
            description = "The altar candle burns with a tall, steady golden flame -- brighter and calmer than a tallow candle. The beeswax melts slowly, pooling in a wide, shallow well around the wick. Warm honeyed light fills the space, and the spiral pattern on the wax seems to turn in the flickering glow. A faint sweetness hangs in the air.",
            room_presence = "A thick altar candle burns with a steady golden flame, casting warm honeyed light.",
            on_feel = "Warm beeswax, softening near the flame. The candle is still solid -- it burns slowly. Liquid wax pools at the top, hot to the touch.",
            on_smell = "Burning beeswax -- sweet, warm honey and a trace of floral pollen. The air itself tastes golden.",
            on_listen = "A soft, steady hiss. The flame is quiet and disciplined, unlike the sputtering of tallow.",
            on_taste = "Sweet wax vapor on your lips. Honey and warmth.",
            provides_tool = "fire_source",
            casts_light = true,
            light_radius = 3,

            timed_events = {
                { event = "transition", delay = 14400, to_state = "spent" },
            },

            on_look = function(self)
                return self.description .. "\n\nThe flame is tall and unwavering. This candle will burn for hours yet."
            end,
        },

        extinguished = {
            name = "a half-burned altar candle",
            description = "A thick beeswax candle, recently extinguished. The wick is black and smoking, and a wide pool of wax is cooling and hardening around it. The spiral pattern is partially obscured by drippings. It could be relit.",
            room_presence = "A thick altar candle sits dark, a thread of smoke rising from its blackened wick.",
            on_feel = "Warm, dense beeswax. The top is a cooling lake of liquid wax, slightly tacky. The wick is soft and bent, still hot.",
            on_smell = "Warm beeswax and smoke. The honey scent is stronger when the flame is out -- released from the cooling wax.",
            on_listen = "A faint ticking as the wax cools and contracts.",
            on_taste = "Warm wax. Sweet and bland.",
            casts_light = false,

            on_look = function(self)
                return self.description .. "\n\nThe wick is still warm. It could be relit."
            end,
        },

        spent = {
            name = "a spent altar candle",
            description = "A wide disc of hardened beeswax and a blackened stub of wick. The tall ceremonial candle is gone, consumed entirely. The spiral pattern survives only at the very edges, where wax drippings froze before reaching the base.",
            on_feel = "A flat disc of hard wax, smooth on top and rough at the edges. The wick stub is brittle carbon. Cold and finished.",
            on_smell = "The ghost of honey. Stale wax.",
            on_listen = "Silent.",
            on_taste = "Dead wax. The sweetness is gone.",
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
            message = "The thick wick catches slowly, then blooms into a tall golden flame. Warm, honeyed light floods outward, and the spiral pattern on the wax seems to come alive in the glow. The air sweetens with beeswax.",
            fail_message = "You have nothing to light it with. The pale wick waits, untouched.",
        },
        {
            from = "lit", to = "extinguished", verb = "extinguish",
            aliases = {"blow", "put out", "snuff"},
            message = "You blow out the altar candle. The tall flame bends, flickers, and dies. A thick column of smoke rises from the wick, and the warm golden light retreats. Darkness reclaims its territory.",
            mutate = {
                weight = function(w) return math.max(w * 0.8, 0.5) end,
                keywords = { add = "half-burned" },
            },
        },
        {
            from = "extinguished", to = "lit", verb = "light",
            aliases = {"relight", "ignite"},
            requires_tool = "fire_source",
            message = "The wick catches again, and the altar candle returns to life with its steady golden flame. Warm light and the scent of beeswax fill the space once more.",
            fail_message = "You have nothing to relight it with.",
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The altar candle gutters at last. The tall flame shrinks to a blue nub, flickers once, and goes out. The beeswax is consumed, leaving only a flat disc of hardened drippings and a carbon stub. The ceremony is over.",
            mutate = {
                weight = 0.3,
                size = 0,
                keywords = { add = "spent" },
                categories = { remove = "light source" },
            },
        },
    },

    mutations = {},
}
