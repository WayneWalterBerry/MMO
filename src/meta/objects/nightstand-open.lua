return {
    guid = "26484e21-5033-4531-b30c-13d8cb72696f",
    id = "nightstand-open",
    name = "a small nightstand (drawer open)",
    keywords = {"nightstand", "night stand", "bedside table", "side table", "small table", "drawer"},
    room_presence = "A small nightstand with an open drawer sits against the wall, its top crusted with wax.",
    description = "A squat nightstand of knotted pine. Wax drippings cascade down its side in frozen rivulets. The small drawer is pulled open.",

    on_feel = "Smooth wooden surface, crusted with hardened wax drippings. The drawer slides open under your fingers.",
    on_smell = "Old pine wood and melted tallow.",

    size = 4,
    weight = 15,
    categories = {"furniture", "wooden"},
    portable = false,

    surfaces = {
        top = { capacity = 3, max_item_size = 2, contents = {"candle", "poison-bottle"} },
        inside = { capacity = 2, max_item_size = 1, contents = {"matchbox"} },
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
        if #self.surfaces.inside.contents == 0 then
            text = text .. "\nThe drawer is open. It is empty."
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
            becomes = "nightstand",
        },
    },
}
