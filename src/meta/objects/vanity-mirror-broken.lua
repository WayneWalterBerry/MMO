return {
    guid = "eea5c707-2f21-4f34-b084-5ec5ecf135bb",
    id = "vanity-mirror-broken",
    name = "an oak vanity (mirror broken)",
    keywords = {"vanity", "desk", "table", "broken mirror", "dressing table", "oak vanity", "shattered"},
    room_presence = "An oak vanity with a shattered mirror sits against the wall, glittering shards dusting its surface.",
    description = "A solid oak vanity, still sturdy despite the violence visited upon it. Where an ornate mirror once stood, only the gilt frame remains -- a jagged crown of broken glass teeth jutting from the backing. Glittering shards dust the vanity's surface. Seven years bad luck, by the old reckoning.",

    on_feel = "Smooth oak surface -- CAREFUL. Tiny glass shards dust the top. Your fingers find jagged edges where the mirror frame meets broken glass.",
    on_smell = "Faint perfume and the sharp, mineral scent of freshly broken glass.",

    size = 8,
    weight = 38,
    categories = {"furniture", "wooden"},
    portable = false,

    surfaces = {
        top = { capacity = 6, max_item_size = 4, contents = {"paper", "pen"} },
        inside = { capacity = 4, max_item_size = 2, contents = {"pencil"}, accessible = false },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.top.contents > 0 then
            text = text .. "\n\nOn the vanity's surface:"
            for _, id in ipairs(self.surfaces.top.contents) do
                text = text .. "\n  " .. id
            end
        end
        text = text .. "\nThe drawer is closed."
        return text
    end,

    mutations = {
        open = {
            becomes = "vanity-open-mirror-broken",
        },
    },
}
