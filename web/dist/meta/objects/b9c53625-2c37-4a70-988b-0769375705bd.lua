-- side-table.lua — Static furniture with surface (Hallway)
return {
    guid = "{b9c53625-2c37-4a70-988b-0769375705bd}",
    template = "furniture",

    id = "side-table",
    material = "oak",
    keywords = {"table", "side table", "hall table", "oak table", "small table"},
    size = 4,
    weight = 20,
    categories = {"furniture", "wooden"},
    portable = false,

    name = "an oak side table",
    description = "A narrow oak table with turned legs, placed against the wall between two portraits. Its top is polished to a dark gleam. A ceramic vase sits upon it, stuffed with dry flowers. The table is clean -- no dust. Someone maintains this hallway.",
    room_presence = "A polished oak side table stands between the portraits, a vase of dry flowers upon it.",
    on_feel = "Smooth polished oak, warm after the cold stone of the cellars. Turned legs, steady -- good craftsmanship. Not a scratch on it.",
    on_smell = "Beeswax polish and old wood. A faint floral scent from the dry flowers.",

    location = nil,

    surfaces = {
        top = {
            capacity = 3, max_item_size = 2, weight_capacity = 10,
            contents = {"vase-1"},
            accessible = true,
        },
    },

    on_look = function(self)
        return self.description
    end,

    mutations = {},
}
