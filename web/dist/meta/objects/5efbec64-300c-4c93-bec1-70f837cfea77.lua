-- incense-stick.lua — Consumable aromatic light source (Deep Cellar puzzle 017)
-- States: unlit → lit → spent
-- Burns in the incense burner to produce fragrant smoke
return {
    guid = "{5efbec64-300c-4c93-bec1-70f837cfea77}",
    template = "small-item",

    id = "incense-stick",
    material = "plant",
    keywords = {"incense", "incense stick", "joss stick", "stick", "aromatic stick"},
    size = 1,
    weight = 0.1,
    categories = {"consumable", "small", "burnable"},
    portable = true,

    name = "a stick of incense",
    description = "A slender stick of incense, about the length of your hand. The tip is coated in a dense, dark resin flecked with pale fragments of sandalwood and myrrh. The bamboo core is smooth and straight. Unlit, it releases only a faint, dry sweetness.",
    on_feel = "A thin, rigid stick -- bamboo core, slightly rough where the resin coating begins. The tip is dense and crumbly between your fingers. Fragrant dust clings to your skin.",
    on_smell = "Even unlit, it exhales a quiet promise -- sandalwood and myrrh, compressed and waiting. A temple smell, sealed in resin.",
    on_listen = "Silent.",
    on_taste = "Bitter and dusty. Resin and dried herbs. Not meant for eating.",
    casts_light = false,

    location = nil,

    burn_duration = 5400,      -- 1.5 hours game time (shorter than candle, longer than match)
    remaining_burn = 5400,

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
            name = "a stick of incense",
            description = "A slender stick of incense, about the length of your hand. The tip is coated in a dense, dark resin flecked with pale fragments of sandalwood and myrrh. The bamboo core is smooth and straight. Unlit, it releases only a faint, dry sweetness.",
            on_feel = "A thin, rigid stick -- bamboo core, slightly rough where the resin coating begins. The tip is dense and crumbly between your fingers. Fragrant dust clings to your skin.",
            on_smell = "Even unlit, it exhales a quiet promise -- sandalwood and myrrh, compressed and waiting. A temple smell, sealed in resin.",
            on_listen = "Silent.",
            on_taste = "Bitter and dusty. Resin and dried herbs. Not meant for eating.",
            casts_light = false,

            on_look = function(self)
                return self.description .. "\n\nThe resin-coated tip could be lit."
            end,
        },

        lit = {
            name = "a burning stick of incense",
            description = "The incense stick burns with a tiny orange ember at its tip, no flame -- just a patient, glowing coal. A thin ribbon of pale smoke rises in a perfectly straight column before curling into lazy spirals. The air thickens with sandalwood, myrrh, and something deeper -- a dark, sweet earthiness that clings to fabric and skin.",
            room_presence = "Fragrant smoke curls from a burning stick of incense, filling the air with sandalwood and myrrh.",
            on_feel = "Warm bamboo. The burning tip radiates gentle heat -- not enough to hurt, but enough to notice. The smoke is soft against your hand.",
            on_smell = "Overpowering now -- sandalwood and myrrh, layered with cedar undertones and a faint floral sweetness. The smoke coats everything. You can taste it on your lips.",
            on_listen = "A faint, papery crackling as the resin burns. The sound of patience.",
            on_taste = "The smoke settles on your tongue -- sweet, bitter, resinous. It lingers.",
            casts_light = false, -- incense doesn't cast useful light
            provides_tool = "fragrant_smoke",

            timed_events = {
                { event = "transition", delay = 5400, to_state = "spent" },
            },

            on_look = function(self)
                return self.description .. "\n\nThe ember creeps slowly down the stick."
            end,
        },

        spent = {
            name = "a spent incense stick",
            description = "A curled finger of pale grey ash clinging to a bamboo splint. The incense is consumed entirely -- nothing remains but the ghost of its fragrance in the air and a dusting of ash where it burned.",
            on_feel = "A bare bamboo splint, feather-light. The ash crumbles at the slightest touch, dissolving into powder.",
            on_smell = "The memory of sandalwood, fading. Grey ash smells of nothing.",
            on_listen = "Silent.",
            on_taste = "Ash. Bitter and empty.",
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
            aliases = {"ignite", "burn"},
            requires_tool = "fire_source",
            message = "The resin catches the flame and glows orange for a moment before settling into a steady ember. A thin column of pale smoke rises, and the air fills with the ancient scent of sandalwood and myrrh. A temple smell -- solemn and sweet.",
            fail_message = "You have nothing to light it with. The resin tip waits, dark and patient.",
        },
        {
            from = "lit", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The last of the incense crumbles into ash. The ember winks out, and the smoke thins to nothing. Only the ghost of sandalwood lingers in the still air.",
            mutate = {
                weight = 0.02,
                size = 0,
                keywords = { add = "spent" },
                categories = { remove = "burnable" },
            },
        },
    },

    mutations = {},
}
