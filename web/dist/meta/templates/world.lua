-- template: world
-- Base template for worlds. Provides minimal defaults.
-- Instance worlds override everything meaningful.
-- See: docs/design/worlds.md (full specification)

return {
    guid = "00000000-0000-0000-0000-000000000000",
    id = "world",
    name = "A world",
    description = "",

    starting_room = "",

    levels = {},

    theme = {
        pitch = "",
        era = "",
        aesthetic = {
            materials = {},
            forbidden = {},
            colors = {},
        },
        atmosphere = "",
        mood = "",
        tone = "",
        constraints = {},
        design_notes = "",
    },

    theme_files = {},

    mutations = {},
}
