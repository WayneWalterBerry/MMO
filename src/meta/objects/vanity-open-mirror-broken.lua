return {
    id = "vanity-open-mirror-broken",
    name = "an oak vanity (drawer open, mirror broken)",
    keywords = {"vanity", "desk", "table", "broken mirror", "dressing table", "oak vanity", "shattered", "drawer"},
    room_presence = "An oak vanity with a broken mirror and an open drawer sits against the wall, shards of glass glinting on its surface.",
    description = "A solid oak vanity, still sturdy despite the violence visited upon it. Where an ornate mirror once stood, only the gilt frame remains — jagged glass teeth jutting from the backing. The brass-handled drawer hangs open.",

    size = 8,
    weight = 38,
    categories = {"furniture", "wooden"},
    portable = false,

    surfaces = {
        top = { capacity = 6, max_item_size = 4, contents = {} },
        inside = { capacity = 4, max_item_size = 2, contents = {} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.inside.contents == 0 then
            text = text .. "\n\nThe drawer yawns open. It is empty."
        else
            text = text .. "\n\nInside the drawer:"
            for _, id in ipairs(self.surfaces.inside.contents) do
                text = text .. "\n  " .. id
            end
        end
        return text
    end,

    mutations = {
        close = {
            becomes = "vanity-mirror-broken",
        },
    },
}
