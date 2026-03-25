return {
    guid = "{a3f8c7d1-e592-4b6a-8d3e-f1c7a4b92e05}",
    template = "furniture",
    id = "trap-door",
    name = "a trap door",
    keywords = {"trap door", "trapdoor", "hatch", "door in floor", "floor door"},
    description = "A heavy wooden trap door set flush with the flagstones, nearly invisible beneath the rug. An iron ring serves as a handle.",

    hidden = true,
    size = 6,
    weight = 100,
    categories = {"architecture", "wooden"},
    portable = false,
    material = "wood",
    room_position = "set into the stone floor",

    discovery_message = "As you pull the rug aside, your foot catches on a wooden edge -- a seam in the flagstones. No... a trap door!",

    on_smell = "Damp earth and old wood rise from the cracks.",

    location = nil,

    -- When opened, unhide the "down" exit in the room
    reveals_exit = "down",

    -- FSM
    initial_state = "hidden",
    _state = "hidden",

    states = {
        hidden = {
            hidden = true,
            name = "a trap door",
            description = "",
            room_presence = "",
        },
        revealed = {
            hidden = false,
            name = "a trap door",
            description = "A heavy wooden trap door set flush with the flagstones, nearly invisible when covered. An iron ring serves as a handle. It is closed.",
            room_presence = "A trap door is set into the stone floor, its iron ring handle glinting dully.",
            on_feel = "Your fingers trace the edges of a heavy wooden door set into the floor. An iron ring handle, cold and rough with rust, is recessed into the wood.",
        },
        open = {
            hidden = false,
            name = "a trap door",
            description = "The trap door yawns open, revealing a narrow stone stairway that spirals down into darkness. Cool, damp air rises from below, carrying the smell of earth and old stone.",
            room_presence = "A trap door stands open in the floor, revealing a dark stairway descending into the earth.",
            on_feel = "The trap door is propped open. Your hand finds the edge of a narrow stone stairway, spiraling down into cool, damp air.",
        },
    },

    transitions = {
        { from = "hidden", to = "revealed", verb = "reveal", trigger = "reveal",
          message = "" },
        { from = "revealed", to = "open", verb = "open",
          message = "You grasp the iron ring and heave. The trap door swings open with a groan of old hinges, revealing a narrow stone stairway spiraling down into darkness.",
          mutate = {
              keywords = { add = "open" },
          },
        },
    },

    mutations = {},
}
