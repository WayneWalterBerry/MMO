-- template: sheet
-- Base template for fabric/cloth objects (sheets, curtains, rags, etc.)
-- Instances inherit these defaults and override as needed.

return {
    id = "sheet",
    name = "a sheet",
    keywords = {},
    description = "A plain sheet of fabric.",

    size = 1,
    weight = 0.2,
    portable = true,
    material = "fabric",

    container = false,
    capacity = 0,
    contents = {},
    location = nil,

    categories = {"fabric"},

    mutations = {
        tear = { becomes = nil, spawns = {"cloth"} },
    },
}
