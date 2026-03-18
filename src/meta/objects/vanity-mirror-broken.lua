return {
    id = "vanity-mirror-broken",
    name = "an oak vanity (mirror broken)",
    keywords = {"vanity", "desk", "table", "broken mirror", "dressing table", "oak vanity", "shattered"},
    description = "A solid oak vanity sits against the wall, still sturdy despite the violence visited upon it. Where an ornate mirror once stood, only the gilt frame remains — a jagged crown of broken glass teeth jutting from the backing. Glittering shards dust the vanity's surface. Seven years bad luck, by the old reckoning.",

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
        text = text .. "\n\nThe drawer is closed."
        return text
    end,

    mutations = {
        open = {
            becomes = "vanity-open-mirror-broken",
        },
    },
}
