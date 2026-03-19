return {
    guid = "eda1257d-8240-4c75-9c1b-a7be349a60f5",
    id = "vanity",
    name = "an oak vanity",
    keywords = {"vanity", "desk", "table", "mirror", "dressing table", "looking glass", "oak vanity"},
    room_presence = "An oak vanity with an ornate mirror sits against one wall, its surface darkened by years of smoke.",
    description = "A solid oak vanity, its surface darkened by years of candle smoke and spilled cosmetics. An ornate mirror rises from the back, framed in tarnished gilt scrollwork. The glass is old and faintly warped, giving your reflection a dreamlike, wavering quality. A single drawer sits closed at the front, its brass pull green with age.",

    on_feel = "Smooth oak surface, slightly sticky with old cosmetics. The mirror glass is cold and flat. A brass drawer pull, green with age.",
    on_smell = "Faint perfume — rosewater and something powdery, trapped in the wood grain for years.",

    size = 8,
    weight = 40,
    categories = {"furniture", "wooden", "reflective"},
    room_position = "sits against the east wall",
    portable = false,

    surfaces = {
        top = { capacity = 6, max_item_size = 4, contents = {"paper", "pen"} },
        inside = { capacity = 4, max_item_size = 2, contents = {"pencil"}, accessible = false },
        mirror_shelf = { capacity = 2, max_item_size = 1, contents = {} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        text = text .. "\n\nYour reflection stares back from the mirror, mimicking your movements with an unsettling half-second delay."
        if #self.surfaces.top.contents > 0 then
            text = text .. "\nOn the vanity's surface:"
            for _, id in ipairs(self.surfaces.top.contents) do
                text = text .. "\n  " .. id
            end
        end
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
