return {
    id = "pillow",
    name = "a goose-down pillow",
    keywords = {"pillow", "cushion", "down pillow", "goose down"},
    description = "A plump pillow stuffed with goose down, its linen case yellowed with age but still soft. It carries the faint scent of lavender — someone once cared about sleeping well in this room.",

    size = 2,
    weight = 1,
    categories = {"soft", "fabric"},
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth"},
        },
    },
}
