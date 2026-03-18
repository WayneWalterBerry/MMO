return {
    id = "vanity",
    name = "an oak vanity",
    keywords = {"vanity", "desk", "table", "mirror", "dressing table", "looking glass", "oak vanity"},
    description = "A solid oak vanity dominates one wall, its surface darkened by years of candle smoke and spilled cosmetics. An ornate mirror rises from the back, framed in tarnished gilt scrollwork. The glass is old and faintly warped, giving your reflection a dreamlike, wavering quality. A single drawer sits closed at the front, its brass pull green with age.",

    size = 8,
    weight = 40,
    categories = {"furniture", "wooden", "reflective"},
    portable = false,

    surfaces = {
        top = { capacity = 6, max_item_size = 4, contents = {} },
        inside = { capacity = 4, max_item_size = 2, contents = {} },
        mirror_shelf = { capacity = 2, max_item_size = 1, contents = {} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        text = text .. "\n\nYour reflection stares back from the mirror, mimicking your movements with an unsettling half-second delay."
        text = text .. "\nThe drawer is closed."
        return text
    end,

    mutations = {
        open = {
            becomes = "vanity-open",
        },
        break_mirror = {
            becomes = "vanity-mirror-broken",
            spawns = {"glass-shard"},
        },
    },
}
