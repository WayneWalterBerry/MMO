return {
    id = "blanket",
    name = "a heavy wool blanket",
    keywords = {"blanket", "wool blanket", "wool", "throw", "covering"},
    description = "A heavy blanket woven from coarse grey wool, the kind shepherds make in the high country. It smells of lanolin and woodsmoke. Several moth holes pepper one corner, but its warmth is undeniable.",

    size = 3,
    weight = 3,
    categories = {"fabric", "soft", "warm"},
    portable = true,

    location = nil,

    on_look = function(self)
        return self.description
    end,

    mutations = {
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth"},
        },
    },
}
