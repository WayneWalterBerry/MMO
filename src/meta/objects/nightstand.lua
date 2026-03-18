return {
    id = "nightstand",
    name = "a small nightstand",
    keywords = {"nightstand", "night stand", "bedside table", "side table", "small table"},
    description = "A squat nightstand of knotted pine, barely reaching the height of the mattress beside it. Wax drippings have pooled and hardened on its top in a frozen cascade. A small drawer sits closed at the front.",

    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    portable = false,

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {"candle"} },
        inside = { capacity = 2, max_item_size = 1, contents = {} },
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
