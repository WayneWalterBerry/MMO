return {
    guid = "bf6cb8ae-f67c-4c54-8c67-d3b10ac21d2c",
    id = "wardrobe-open",
    name = "a heavy wardrobe (open)",
    keywords = {"wardrobe", "armoire", "closet", "cabinet", "clothes", "open"},
    room_presence = "A towering wardrobe stands open in the corner, its carved doors flung wide like wings.",
    description = "The massive wardrobe stands open, its carved doors flung wide like wings. The interior is lined with cedar -- you can smell it, sharp and sweet beneath the must. A few wooden pegs jut from the back wall, most empty.",

    on_feel = "A massive wooden frame, smooth and cold. The doors swing wide on iron hinges. Wooden pegs jut from the back wall.",
    on_smell = "Cedar -- sharp and sweet, now released into the room. Beneath it, the faintest trace of moth-eaten wool.",

    size = 9,
    weight = 60,
    categories = {"furniture", "wooden", "large", "container"},
    portable = false,

    surfaces = {
        inside = { capacity = 8, max_item_size = 4, contents = {"wool-cloak", "sack"} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.inside.contents == 0 then
            text = text .. "\n\nThe wardrobe is empty. Not even a moth."
        else
            text = text .. "\n\nHanging inside:"
            for _, id in ipairs(self.surfaces.inside.contents) do
                text = text .. "\n  " .. id
            end
        end
        return text
    end,

    mutations = {
        close = {
            becomes = "wardrobe",
        },
    },
}
