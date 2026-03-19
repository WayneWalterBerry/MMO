return {
    id = "vanity-open",
    name = "an oak vanity (drawer open)",
    keywords = {"vanity", "desk", "table", "mirror", "dressing table", "looking glass", "oak vanity", "drawer"},
    room_presence = "An oak vanity with a drawer hanging open sits against one wall, its mirror reflecting the room.",
    description = "A solid oak vanity, its surface darkened by years of candle smoke and spilled cosmetics. An ornate mirror rises from the back, framed in tarnished gilt scrollwork. The brass-handled drawer hangs open, its dark interior exposed.",

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
        text = text .. "\n\nYour reflection stares back from the mirror."
        if #self.surfaces.inside.contents == 0 then
            text = text .. "\nThe drawer yawns open. It is empty."
        else
            text = text .. "\nInside the drawer:"
            for _, id in ipairs(self.surfaces.inside.contents) do
                text = text .. "\n  " .. id
            end
        end
        return text
    end,

    mutations = {
        close = {
            becomes = "vanity",
        },
        break_mirror = {
            becomes = "vanity-open-mirror-broken",
            spawns = {"glass-shard"},
        },
    },
}
