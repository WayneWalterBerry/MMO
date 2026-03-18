return {
    template = "sheet",

    id = "curtains",
    name = "heavy velvet curtains",
    keywords = {"curtains", "drapes", "curtain", "velvet", "window covering"},
    description = "Heavy curtains of faded burgundy velvet hang before the window, pooling on the floor in dusty folds. They are drawn closed, blocking whatever light tries to enter. Moths have been at them — small holes let through pinpricks of grey light like a constellation of neglect.",

    size = 4,
    weight = 4,
    categories = {"fabric", "soft", "window covering"},
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
