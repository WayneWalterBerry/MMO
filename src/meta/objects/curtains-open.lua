return {
    template = "sheet",

    id = "curtains-open",
    name = "heavy velvet curtains (open)",
    keywords = {"curtains", "drapes", "curtain", "velvet", "window covering", "open"},
    room_presence = "Heavy burgundy curtains have been pulled aside against the wall, letting pale light spill across the floor.",
    description = "The heavy burgundy curtains have been pulled aside, bunched against the wall in dusty velvet heaps. Pale grey light spills through, illuminating motes of dust that swirl like tiny lost souls.",

    size = 4,
    weight = 4,
    categories = {"fabric", "soft", "window covering"},
    portable = false,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThey could be closed again."
    end,

    mutations = {
        close = {
            becomes = "curtains",
        },
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth", "rag"},
        },
    },
}
