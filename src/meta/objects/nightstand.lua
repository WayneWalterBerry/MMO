return {
    guid = "d40b15e6-7d64-489e-9324-ea00fb915602",
    id = "nightstand",
    name = "a small nightstand",
    keywords = {"nightstand", "night stand", "bedside table", "side table", "small table", "drawer"},
    room_presence = "A small nightstand crusted with candle wax sits against the wall.",
    description = "A squat nightstand of knotted pine, its top crusted with pooled and hardened wax drippings in a frozen cascade. A small drawer sits closed at the front.",

    on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",
    on_smell = "Old pine wood and melted tallow.",

    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    room_position = "stands beside the bed",
    portable = false,

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {"candle", "poison-bottle"} },
        inside = { capacity = 2, max_item_size = 1, contents = {"matchbox"}, accessible = false },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.top.contents > 0 then
            text = text .. "\n\nOn top:"
            for _, id in ipairs(self.surfaces.top.contents) do
                text = text .. "\n  " .. id
            end
        end
        text = text .. "\nThe drawer is closed."
        return text
    end,

    mutations = {
        open = {
            becomes = "nightstand-open",
        },
    },
}
