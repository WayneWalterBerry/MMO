return {
    guid = "f973058d-5410-4c02-b643-b7cab713aaf4",
    id = "pillow",
    name = "a goose-down pillow",
    keywords = {"pillow", "cushion", "down pillow", "goose down"},
    description = "A plump pillow stuffed with goose down, its linen case yellowed with age but still soft. It carries the faint scent of lavender -- someone once cared about sleeping well in this room.",

    on_feel = "Soft and lumpy, stuffed with down that shifts under your fingers. Something sharp pricks you if you squeeze too hard.",
    on_smell = "Faint lavender, old linen.",

    size = 2,
    weight = 1,
    categories = {"soft", "fabric"},
    portable = true,
    material = "linen",

    surfaces = {
        inside = { capacity = 1, max_item_size = 1, contents = {"pin"}, accessible = false },
    },

    location = nil,

    on_look = function(self)
        local text = self.description
        if #self.surfaces.inside.contents > 0 then
            text = text .. "\n\nSomething sharp pricks your hand when you press the pillow. There seems to be a pin stuck in it."
        end
        return text
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth"},
        },
    },
}
