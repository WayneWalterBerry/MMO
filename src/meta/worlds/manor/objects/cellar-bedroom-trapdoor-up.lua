-- cellar-bedroom-trapdoor-up.lua — Portal object: cellar side of bedroom trapdoor
-- Paired with: bedroom-cellar-trapdoor-down.lua (bedroom side)
-- Replaces: cellar.exits.up (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #200
return {
    guid = "{c915adfa-df5c-40bb-987f-751be2cc7525}",
    template = "portal",

    id = "cellar-bedroom-trapdoor-up",
    name = "a narrow stone stairway",
    material = "wood",
    keywords = {"stairs", "stairway", "staircase", "up", "steps", "stone stairs",
                "trap door", "trapdoor", "hatch"},
    size = 4,
    weight = 60,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "start-room",
        bidirectional_id = "{f0d22f08-fd7c-4437-a5b5-81f006e81d7f}",
        direction_hint = "up",
    },

    max_carry_size = 3,
    max_carry_weight = 30,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A narrow stone stairway spirals upward through the open trap door, back to the bedroom above.",
    room_presence = "A narrow stone stairway spirals upward, back to the bedroom above.",
    on_examine = "Narrow stone steps, worn smooth by centuries of passage, spiral upward through a square opening in the ceiling. The trap door above is held open by its own weight on heavy iron hinges. Dim light — or the suggestion of light — filters down from the bedroom above.",
    on_feel = "The stone steps are smooth and slightly damp. The walls of the stairwell are close — rough granite, cold to the touch. You can touch both walls at once. The trap door above is heavy oak with iron bands.",
    on_smell = "Stale tallow, old wool, and the ghost of lavender drift down from the bedroom above. Below, the cellar's damp earth and cold stone.",
    on_listen = "Your footsteps echo in the narrow stairwell. From above: silence, the settling of old stone. The bedroom waits.",
    on_taste = "Dust and damp stone. The air tastes of earth.",

    initial_state = "hidden",
    _state = "hidden",

    states = {
        hidden = {
            traversable = false,
            name = "the ceiling above",
            description = "Rough stone ceiling. You see nothing unusual.",
            room_presence = nil,
            hidden = true,
            on_examine = "Just rough stone overhead. Nothing visible.",
            on_feel = "Cold stone ceiling. Solid, unremarkable.",
            on_listen = "Silence from above.",
        },

        closed = {
            traversable = false,
            name = "a closed trap door in the ceiling",
            description = "A heavy wooden trap door is set into the ceiling above. It appears to be closed.",
            room_presence = "A heavy trap door is visible in the ceiling above, closed tight.",
            on_examine = "A square trap door of heavy oak, reinforced with iron bands, set into the ceiling. It's closed. The hinges are on the far side — it opens upward.",
            on_feel = "Heavy oak planks overhead, cold iron bands. The door is within reach. It could be pushed open from below.",
            on_smell = "Faint smells from above seep around the edges — tallow, old wool.",
            on_listen = "Silence from the bedroom above. The door is solid.",
        },

        open = {
            traversable = true,
            name = "an open trap door and stone stairway",
            description = "The trap door stands open above. A narrow stone stairway spirals upward to the bedroom.",
            room_presence = "A narrow stone stairway spirals upward through the open trap door to the bedroom above.",
            on_examine = "The trap door is open, held by its own weight. Narrow stone steps spiral upward. Dim light and the smell of tallow drift down from the bedroom.",
            on_feel = "Smooth stone steps. The walls are close — rough granite, cold and damp. The trap door above is open.",
            on_smell = "Tallow, old wool, and lavender from the bedroom above.",
            on_listen = "The stairwell amplifies sounds from the bedroom. Settling stone, silence.",
        },
    },

    transitions = {
        {
            from = "hidden", to = "closed", verb = "reveal",
            aliases = {"discover", "find", "uncover"},
            message = "A trap door is now visible in the ceiling above — heavy oak with iron bands, set into the stone.",
            mutate = {
                keywords = { add = "revealed" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push", "lift"},
            message = "You reach up and push the trap door. It swings open with a groan of iron hinges. A stone stairway spirals upward to the bedroom above.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut", "pull"},
            message = "You pull the trap door shut above you. It closes with a heavy thud, cutting off the bedroom.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
