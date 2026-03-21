-- candle-holder.lua — Composite object with detachable candle
-- States: with_candle <-> empty (candle removed/reattached)
-- The candle is a detachable child — like drawer from nightstand, cork from bottle.
return {
    guid = "0aeaff45-e2d0-4e58-b47c-139874a218df",
    template = "small-item",

    id = "candle-holder",
    keywords = {"candle holder", "holder", "candlestick", "sconce", "brass holder"},
    size = 2,
    weight = 1.5,
    categories = {"furniture", "small", "portable"},
    portable = true,
    material = "brass",

    -- Initial state (with_candle)
    name = "a brass candle holder",
    description = "A tarnished brass candle holder, its base wide and heavy enough to stand steady on any surface. A tallow candle sits firmly in the socket, held upright by a ring of melted wax. Drippings cascade down the stem in frozen rivulets.",
    room_presence = "A brass candle holder sits nearby, a tallow candle fixed in its socket.",
    on_feel = "Cool brass, tarnished and slightly rough. The stem is ridged for grip. Hardened wax drippings cling to the base like frozen tears.",
    on_smell = "Brass polish long faded, and the faint waxy scent of tallow.",

    location = nil,

    -- FSM
    initial_state = "with_candle",
    _state = "with_candle",

    states = {
        with_candle = {
            name = "a brass candle holder",
            description = "A tarnished brass candle holder, its base wide and heavy enough to stand steady on any surface. A tallow candle sits firmly in the socket, held upright by a ring of melted wax. Drippings cascade down the stem in frozen rivulets.",
            room_presence = "A brass candle holder sits nearby, a tallow candle fixed in its socket.",
            on_feel = "Cool brass, tarnished and slightly rough. The stem is ridged for grip. A waxy candle protrudes from the socket, firm and upright.",
            on_smell = "Brass polish long faded, and the faint waxy scent of tallow.",
            contents = {"candle"},

            on_look = function(self, registry)
                local text = self.description
                local candle = registry and registry:get("candle")
                if candle and candle._state == "lit" then
                    text = text .. "\n\nThe candle burns with a steady amber flame, safe in its brass cradle."
                elseif candle and candle._state == "extinguished" then
                    text = text .. "\n\nThe candle wick trails a thin wisp of smoke. It has been recently extinguished."
                elseif candle and candle._state == "spent" then
                    text = text .. "\n\nOnly a blackened nub remains where the candle was."
                end
                return text
            end,
        },

        empty = {
            name = "an empty candle holder",
            description = "A tarnished brass candle holder, its socket empty. Hardened wax lines the inside of the ring where a candle once sat. The base is wide and heavy, the stem ridged -- a thing designed for purpose, now purposeless.",
            room_presence = "An empty brass candle holder sits nearby, its socket bare.",
            on_feel = "Cool brass, tarnished and slightly rough. The socket is empty -- your finger traces the ring of hardened wax where a candle once sat.",
            on_smell = "Old brass and stale wax. A ghost of tallow.",

            on_look = function(self)
                return self.description
            end,
        },
    },

    transitions = {
        {
            from = "with_candle", to = "empty", verb = "detach_part",
            trigger = "detach_part",
            part_id = "candle",
            message = "You twist the candle free from its brass socket. Flakes of old wax crumble away as it comes loose.",
            mutate = {
                weight = function(w) return w - 1 end,
            },
        },
        {
            from = "empty", to = "with_candle", verb = "reattach_part",
            trigger = "reattach_part",
            part_id = "candle",
            message = "You press the candle into the brass socket. It seats firmly in a ring of soft wax.",
            mutate = {
                weight = function(w) return w + 1 end,
            },
        },
    },

    -- === COMPOSITE PARTS ===
    parts = {
        candle = {
            id = "candle",
            detachable = true,
            reversible = true,
            keywords = {"candle", "tallow", "tallow candle"},
            name = "a tallow candle",
            description = "A stubby tallow candle, removed from its brass holder.",
            size = 1,
            weight = 1,
            categories = {"light source", "small"},
            portable = true,
            carries_contents = false,
            detach_verbs = {"remove", "take", "pull", "extract"},
            detach_message = "You twist the candle free from its brass socket. Flakes of old wax crumble away as it comes loose.",
            reattach_verbs = {"put", "place", "insert", "set"},
            reattach_message = "You press the candle into the brass socket. It seats firmly in a ring of soft wax.",

            -- Candle already exists as independent object (candle.lua).
            -- Factory returns identifying info; engine uses existing registry entry.
            factory = function(parent)
                return {
                    id = "candle",
                    reattach_to = "candle-holder",
                    location = parent.location,
                }
            end,
        },
    },

    mutations = {},
}
