return {
    template = "sheet",

    id = "curtains",
    name = "heavy velvet curtains",
    keywords = {"curtains", "drapes", "curtain", "velvet", "window covering"},
    room_presence = "Heavy velvet curtains of faded burgundy hang across the far wall, pooling on the floor in dusty folds.",
    description = "Heavy curtains of faded burgundy velvet, drawn closed and pooling on the floor in dusty folds. They block whatever light tries to enter. Moths have been at them — small holes let through pinpricks of grey light like a constellation of neglect.",

    size = 4,
    weight = 4,
    categories = {"fabric", "soft", "window covering"},
    room_position = "hang across the window in the far wall",
    portable = false,

    location = nil,

    on_look = function(self)
        return self.description .. "\n\nThey could be opened."
    end,

    mutations = {
        open = {
            becomes = "curtains-open",
        },
        tear = {
            becomes = nil,
            spawns = {"cloth", "cloth", "rag"},
        },
    },
}
