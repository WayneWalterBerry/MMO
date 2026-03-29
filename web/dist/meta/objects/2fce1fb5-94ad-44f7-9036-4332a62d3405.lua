-- incense-burner.lua — Ritual container for incense sticks (Deep Cellar puzzle 017)
-- States: empty → holding → burning → spent (full burn lifecycle)
-- Acts as a holder for incense-stick, like candle-holder for candles
return {
    guid = "{2fce1fb5-94ad-44f7-9036-4332a62d3405}",
    template = "container",

    id = "incense-burner",
    material = "brass",
    keywords = {"incense burner", "burner", "censer", "brass burner", "brazier", "thurible"},
    size = 2,
    weight = 1.5,
    categories = {"container", "metal", "small"},
    portable = true,

    name = "a brass incense burner",
    description = "A small brass incense burner, its bowl dark with carbon and half-filled with grey ash. The lid is perforated with geometric patterns -- stars and hexagons -- that once let fragrant smoke spiral upward. The brass is tarnished to a dull greenish-brown. A small hole in the center of the lid is sized to hold an incense stick upright. Whatever ceremony last used this was a long time ago.",
    on_feel = "Ornate brass, cold. The pierced lid has sharp geometric cutouts -- stars and hexagons. A small hole in the center is sized for an incense stick. Inside: fine, silky ash. Weightless between your fingers.",
    on_smell = "Old incense -- the ghost of sandalwood and myrrh. The ash itself smells of nothing, but the brass retains the memory.",
    on_listen = "The ash whispers when disturbed -- a soft sifting sound.",
    on_taste = "Cold brass. Metallic and bitter, with a faint residue of old ash.",

    location = nil,

    -- Container accepts incense sticks (size 1, light weight)
    surfaces = {
        inside = {
            capacity = 1, max_item_size = 1, weight_capacity = 0.5,
            contents = {},
            accessible = true,
            accepts = {"incense-stick"},
        },
    },

    -- FSM
    initial_state = "empty",
    _state = "empty",

    states = {
        empty = {
            name = "a brass incense burner",
            description = "A small brass incense burner, its bowl dark with carbon and half-filled with grey ash. The lid is perforated with geometric patterns -- stars and hexagons -- that once let fragrant smoke spiral upward. The brass is tarnished to a dull greenish-brown. A small hole in the center of the lid is sized to hold an incense stick upright. The burner is empty.",
            on_feel = "Ornate brass, cold. The pierced lid has sharp geometric cutouts -- stars and hexagons. A small hole in the center is sized for an incense stick. Inside: fine, silky ash.",
            on_smell = "Old incense -- the ghost of sandalwood and myrrh. Fading.",
            on_listen = "The ash whispers when disturbed -- a soft sifting sound.",

            on_look = function(self)
                return self.description .. "\n\nThe hole in the lid could hold an incense stick."
            end,
        },

        holding = {
            name = "a brass incense burner with incense",
            description = "A small brass incense burner with a stick of incense standing upright in the center hole of its perforated lid. The incense is unlit, its resin-coated tip dark against the tarnished brass.",
            room_presence = "A brass incense burner sits nearby, an unlit stick of incense standing in its lid.",
            on_feel = "Ornate brass, cold. An incense stick protrudes from the center hole, firm and upright. The resin tip is dry and rough.",
            on_smell = "Dry sandalwood and myrrh from the unlit incense. Old ash from the burner. A promise of fragrance.",
            on_listen = "Silent.",
            contents = {"incense-stick"},

            on_look = function(self)
                return self.description .. "\n\nThe incense could be lit."
            end,
        },

        burning = {
            name = "a brass incense burner (burning)",
            description = "Fragrant smoke spirals upward through the geometric perforations in the brass lid -- stars and hexagons framing thin columns of pale smoke. The incense stick burns with a patient ember, its ash accumulating in the bowl below. The brass has warmed, and the tarnished surface catches the glow. The air is thick with sandalwood and myrrh.",
            room_presence = "Fragrant smoke spirals through the perforated lid of a brass incense burner, filling the chamber with sandalwood and myrrh.",
            on_feel = "Warm brass now -- the burner has absorbed the heat of the burning incense. Smoke curls between your fingers as you touch the perforated lid.",
            on_smell = "Sandalwood and myrrh, amplified and focused by the brass chamber. The geometric perforations direct the smoke upward in thin, elegant columns. The scent is dense and ceremonial.",
            on_listen = "A faint crackling from the burning resin. The smoke hisses softly through the perforations.",
            provides_tool = "fragrant_smoke",
            contents = {"incense-stick"},

            timed_events = {
                { event = "transition", delay = 5400, to_state = "spent" },
            },

            on_look = function(self, registry)
                local text = self.description
                local stick = registry and registry:get("incense-stick")
                if stick and stick._state == "spent" then
                    text = text .. "\n\nThe incense has burned down to a finger of pale ash."
                else
                    text = text .. "\n\nSmoke rises through the star and hexagon cutouts in a mesmerizing pattern."
                end
                return text
            end,
        },

        spent = {
            name = "a brass incense burner (spent)",
            description = "The brass incense burner sits quiet and warm. A thin finger of pale grey ash -- all that remains of the incense stick -- stands in the center hole of the perforated lid. No smoke rises. The geometric perforations frame only stillness now. The ghost of sandalwood lingers in the warm brass.",
            room_presence = "A brass incense burner sits nearby, its incense spent. A faint sweetness hangs in the air.",
            on_feel = "Warm brass, slowly cooling. The ash in the center hole crumbles at a touch, dissolving into powder. The perforated lid retains the heat of the burning.",
            on_smell = "The memory of sandalwood and myrrh, fading. Warm brass and fine ash. The ceremony is over.",
            on_listen = "Silent. The crackling has stopped.",
            contents = {"incense-stick"},

            on_look = function(self)
                return self.description .. "\n\nThe spent incense could be removed to make room for a fresh stick."
            end,
        },
    },

    transitions = {
        {
            from = "empty", to = "holding", verb = "put",
            aliases = {"place", "insert", "set"},
            requires_item = "incense-stick",
            message = "You slide the incense stick into the hole in the burner's lid. It stands upright, held firmly by the brass ring. The fit is precise -- this burner was made for exactly this.",
        },
        {
            from = "holding", to = "burning", verb = "light",
            aliases = {"ignite", "burn"},
            requires_tool = "fire_source",
            message = "The resin tip catches the flame and glows. Pale smoke begins to rise, threading through the star and hexagon perforations in the brass lid. The ancient burner fulfills its purpose once more. Sandalwood and myrrh fill the chamber.",
            fail_message = "You have nothing to light it with.",
        },
        {
            from = "holding", to = "empty", verb = "take",
            aliases = {"remove", "pull", "extract"},
            part_id = "incense-stick",
            message = "You pull the incense stick free from the burner's lid. It comes loose with a soft scrape of resin against brass.",
        },
        {
            from = "burning", to = "spent", trigger = "auto",
            condition = "timer_expired",
            message = "The last ember winks out. The smoke thins to nothing, leaving only a pale finger of ash standing in the burner's lid. The brass begins to cool. The ghost of sandalwood lingers.",
            mutate = {
                keywords = { add = "spent" },
            },
        },
        {
            from = "spent", to = "empty", verb = "take",
            aliases = {"remove", "clean", "empty", "clear"},
            part_id = "incense-stick",
            message = "You pull the spent incense from the burner's lid. The ash crumbles as it comes free, dusting the brass with grey powder. The burner is empty again, ready for a fresh stick.",
        },
    },

    mutations = {},
}
