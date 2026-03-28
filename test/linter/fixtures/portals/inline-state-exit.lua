-- inline-state-exit.lua — Test fixture: room exit with inline open/locked fields (triggers EXIT-06)
-- This is a ROOM file (not a portal) where the exit uses the old inline format
-- instead of a proper portal reference.
-- Used by: test/linter/test_exit_rules.py
return {
    guid = "{00000000-0000-0000-0000-000000000060}",
    template = "room",

    id = "test-room-inline-exits",
    name = "A Test Chamber",
    description = "A plain stone chamber used for testing. The walls are featureless grey.",

    instances = {},

    exits = {
        north = {
            -- Inline state fields instead of portal reference (EXIT-06)
            target = "some-other-room",
            type = "door",
            name = "a wooden door",
            open = false,
            locked = true,
        },
        south = {
            -- Another inline exit with state fields (EXIT-06)
            target = "another-room",
            type = "door",
            name = "an iron door",
            open = false,
            locked = false,
        },
    },

    mutations = {},
}
