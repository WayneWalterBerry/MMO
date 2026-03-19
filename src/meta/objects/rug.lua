return {
    id = "rug",
    name = "a threadbare rug",
    keywords = {"rug", "carpet", "mat", "floor covering"},
    room_presence = "A threadbare rug covers the cold stone floor, its pattern faded to a ghost of crimson and gold.",
    description = "A once-fine rug lies on the stone floor, its pattern faded to a ghost of crimson and gold. The edges are frayed and curling, and the center is worn thin enough to see the flagstones beneath. It looks like it might be hiding something underneath, as rugs in old rooms inevitably do.",

    on_feel = "Rough woven textile underfoot. The edges are frayed and curling. One corner feels slightly raised.",

    size = 5,
    weight = 8,
    categories = {"fabric", "floor covering"},
    room_position = "covers the cold stone floor",
    portable = false,

    surfaces = {
        underneath = { capacity = 3, max_item_size = 2, contents = {"brass-key"} },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.underneath.contents > 0 then
            text = text .. "\n\nOne corner is slightly raised, as if something is beneath it."
        end
        return text
    end,

    mutations = {},
}
