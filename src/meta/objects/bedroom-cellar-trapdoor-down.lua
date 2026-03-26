-- bedroom-cellar-trapdoor-down.lua — Portal object: bedroom side of cellar trapdoor
-- Paired with: cellar-bedroom-trapdoor-up.lua (cellar side)
-- Replaces: start-room.exits.down (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #200
return {
    guid = "{1b6fc3b4-e69e-4c09-aee9-02d718fb3052}",
    template = "portal",

    id = "bedroom-cellar-trapdoor-down",
    name = "a trap door",
    material = "wood",
    keywords = {"trap door", "trapdoor", "hatch", "down", "stairway", "stairs"},
    size = 4,
    weight = 60,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "cellar",
        bidirectional_id = "{f0d22f08-fd7c-4437-a5b5-81f006e81d7f}",
        direction_hint = "down",
    },

    max_carry_size = 3,
    max_carry_weight = 30,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A heavy wooden trap door is set into the floor, framed with iron bands.",
    room_presence = nil,
    on_examine = "A heavy wooden trap door set into the floor, framed with iron bands. An iron ring handle lies flush with the planks.",
    on_feel = "Rough wood planks, cold iron bands around the edges. An iron ring serves as a handle. The wood is thick and heavy — it takes effort to lift.",
    on_smell = "Cold, damp air rises from below — the smell of earth, old stone, and something faintly metallic.",
    on_listen = "From below: the distant drip of water echoing off stone walls. Cold air whispers up through the gap.",
    on_taste = "Old wood and iron. Gritty dust.",

    initial_state = "hidden",
    _state = "hidden",

    states = {
        hidden = {
            traversable = false,
            name = "a trap door",
            description = "The floor is covered by the rug. Nothing visible here.",
            room_presence = nil,
            hidden = true,
            on_examine = "You see nothing unusual about the floor.",
            on_feel = "Just the floor beneath the rug.",
            on_smell = "Nothing unusual.",
            on_listen = "Silence.",
        },

        closed = {
            traversable = false,
            name = "a closed trap door",
            description = "A heavy wooden trap door is set into the floor, its iron ring handle flush with the planks. Iron bands reinforce the edges.",
            room_presence = "A heavy trap door is set into the floor, its iron ring handle visible among the flagstones.",
            on_examine = "A square trap door of heavy oak planks, reinforced with iron bands. An iron ring lies flat against the surface — a handle. The door sits flush with the surrounding flagstones.",
            on_feel = "Heavy oak planks, flush with the stone floor. The iron ring handle is cold. The door feels solid but not locked — it could be pulled open.",
            on_smell = "Faint cold air seeps around the edges. Damp earth from below.",
            on_listen = "Press your ear to the wood: the faint drip of water from far below. Cold cellar air.",
        },

        open = {
            traversable = true,
            name = "an open trap door",
            description = "The trap door stands open, revealing a narrow stone stairway that spirals down into cold darkness.",
            room_presence = "The trap door in the floor stands open. A narrow stone stairway spirals down into darkness below.",
            on_examine = "The heavy trap door has been pulled open, resting on its iron hinges. Below: narrow stone steps, worn smooth, spiraling down into darkness. Cold, damp air rises from the depths.",
            on_feel = "The open edge of the trap door. Below, cold air rises. The first step is stone, worn smooth and slightly damp.",
            on_smell = "Cold, damp air pours up from below — earth, old stone, the metallic tang of deep water.",
            on_listen = "Water drips somewhere far below, echoing off stone walls. The cellar breathes cold air upward.",
        },
    },

    transitions = {
        {
            from = "hidden", to = "closed", verb = "reveal",
            aliases = {"discover", "find", "uncover"},
            message = "You pull the rug aside, revealing a heavy trap door set into the floor. An iron ring handle lies flush with the planks.",
            mutate = {
                keywords = { add = "revealed" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"pull", "lift"},
            message = "You grip the iron ring and heave. The trap door comes up with a groan of old hinges, releasing a breath of cold, damp air from below. Stone steps spiral down into darkness.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut", "drop"},
            message = "You lower the trap door back into place. It settles flush with the floor with a heavy thud.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
