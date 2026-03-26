-- incense-burner.lua — Ritual container for incense sticks (Deep Cellar puzzle 017)
-- States: empty → holding → burning (incense lit inside burner)
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

            on_look = function(self)
                return self.description .. "\n\nSmoke rises through the star and hexagon cutouts in a mesmerizing pattern."
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
    },

    mutations = {},
}
