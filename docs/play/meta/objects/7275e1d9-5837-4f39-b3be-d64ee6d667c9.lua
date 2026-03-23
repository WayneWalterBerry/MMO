return {
    guid = "{7275e1d9-5837-4f39-b3be-d64ee6d667c9}",
    template = "sheet",
    id = "rug",
    material = "wool",
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

    -- Spatial properties
    movable = true,
    moved = false,
    covering = {"trap-door"},
    move_message = "You grab the edge of the threadbare rug and pull it aside, bunching it against the wall.",
    moved_room_presence = "The threadbare rug lies bunched against the wall, its faded crimson and gold pattern crumpled.",
    moved_description = "The threadbare rug has been pulled aside and lies bunched against the wall. Its crimson and gold pattern is crumpled and folded.",
    moved_on_feel = "The rug is bunched against the wall, its rough weave folded over itself.",

    surfaces = {
        underneath = { capacity = 3, max_item_size = 2, contents = {"brass-key"}, accessible = false },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if not self.moved and self.surfaces and self.surfaces.underneath
            and #self.surfaces.underneath.contents > 0 then
            text = text .. "\n\nOne corner is slightly raised, as if something is beneath it."
        end
        return text
    end,

    mutations = {},
}
