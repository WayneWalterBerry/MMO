-- bedroom-hallway-door-south.lua — Portal object: hallway side of oak door
-- Paired with: bedroom-hallway-door-north.lua (bedroom side)
-- Replaces: hallway.exits.south (inline exit)
-- See: plans/portal-unification-plan.md (Phase 2), Issue #198
return {
    guid = "{a47ce304-4425-4bd0-a9e9-224b7c8baa8c}",
    template = "portal",

    id = "bedroom-hallway-door-south",
    name = "a heavy oak door",
    material = "oak",
    keywords = {"door", "heavy door", "oak door", "south door",
                "bedroom door", "barred door", "iron bar"},
    size = 6,
    weight = 120,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "start-room",
        bidirectional_id = "{4bb381ad-2c9d-4926-8ebc-e55d8e48f4c4}",
        direction_hint = "south",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    -- Descriptions (hallway perspective — bar is visible, player can interact with it)
    description = "A heavy oak door with iron hinges. A thick iron bar rests in brackets across it, holding it shut.",
    room_presence = "A heavy oak door bars the south end of the corridor, held shut by a thick iron bar in its brackets.",
    on_examine = "A heavy oak door with iron hinges, set in the south wall. A thick iron bar — as long as your arm and heavier — rests in iron brackets bolted to the frame, holding the door shut from this side. The bar is not locked in place; it could be lifted free. Through the gap beneath the door, cold air seeps from the dark room beyond.",
    on_feel = "Rough oak planks under your hand, same as the bedroom side. But here: the iron bar. Your fingers find it in its brackets — cold, heavy, smooth from use. It sits in the brackets by weight alone. You could lift it.",
    on_smell = "Oak and iron, same as the other side. But through the gap at the bottom of the door — cold, stale air. The room beyond is unheated.",
    on_listen = "You press your ear to the oak. Cold silence from the bedroom beyond. No sound, no movement. Just still air and stone.",
    on_taste = "You press your tongue to the oak. Dry, gritty wood grain and the metallic bite of iron. It tastes of age.",
    on_knock = "You rap your knuckles against the oak. A deep, dull thud. The sound carries through to the room beyond. No one answers.",
    on_push = "You push against the door. The iron bar holds it shut from this side. Lift the bar first.",
    on_pull = "The door opens inward, away from you. Push, don't pull — but first, lift the bar.",

    -- FSM — synced with north side via bidirectional_id
    initial_state = "barred",
    _state = "barred",

    states = {
        barred = {
            traversable = false,
            name = "a barred oak door",
            description = "A heavy oak door held shut by a thick iron bar in its brackets.",
            room_presence = "A heavy oak door bars the south end of the corridor, held shut by a thick iron bar in its brackets.",
            on_examine = "The iron bar rests in its brackets, holding the door fast. It could be lifted free — it's held by weight, not a lock.",
            on_feel = "The iron bar: cold, heavy, resting in brackets by its own weight. You could lift it.",
            on_smell = "Oak and iron. Cold air seeps from beneath the door.",
            on_listen = "Cold silence from the room beyond. The bar creaks faintly in its brackets.",
            on_knock = "A deep, dull thud through the oak. No answer from beyond.",
            on_push = "The iron bar holds the door shut. Lift the bar first.",
            on_pull = "The door opens away from you — push, not pull. But first, lift the bar.",
        },

        unbarred = {
            traversable = false,
            name = "an unbarred oak door",
            description = "The heavy oak door stands unbarred. The iron bar leans against the wall beside it.",
            room_presence = "The heavy oak door to the south stands unbarred. The iron bar leans against the wall.",
            on_examine = "The bar has been lifted from its brackets and leans against the wall. The door is free in its frame — a push would open it.",
            on_feel = "The door shifts in its frame. No bar holds it now.",
            on_smell = "Cold air from the bedroom beyond, stronger now without the tight seal.",
            on_listen = "A faint draught whistles through the gap. The bedroom beyond is silent.",
            on_knock = "A hollow thud. The door rattles slightly — no bar to hold it.",
            on_push = "The door is ready to open. Push harder to swing it wide.",
            on_pull = "The door opens away from you. Push, not pull.",
        },

        open = {
            traversable = true,
            name = "an open oak door",
            description = "The heavy oak door stands open, revealing the dim bedchamber beyond.",
            room_presence = "The heavy oak door to the south stands open to the dim bedchamber.",
            on_examine = "The door stands open on heavy iron hinges. Beyond: a dim bedchamber, cold and still. The iron bar leans against the wall.",
            on_feel = "The open door edge. Cool, stale air drifts from the bedroom.",
            on_smell = "Tallow, old wool, and the faintest ghost of lavender from the bedroom beyond.",
            on_listen = "Silence from the bedchamber. Cold, still air. The room feels empty.",
            on_knock = "You knock on the open door. It swings slightly on its hinges.",
            on_push = "The door is already open.",
            on_pull = "The door is already open. You could close it.",
        },

        broken = {
            traversable = true,
            name = "a splintered doorframe",
            description = "Where the oak door once stood, only splintered wood and twisted iron hinges remain.",
            room_presence = "A splintered doorframe gapes in the south wall, opening to the dim bedchamber.",
            on_examine = "Splintered oak and twisted iron. The door has been destroyed — only fragments remain in the frame. The iron bar lies bent among the wreckage.",
            on_feel = "Jagged splinters and bent iron. Mind your fingers.",
            on_smell = "Fresh-split oak and the tang of stressed iron.",
            on_listen = "The bedchamber beyond is fully exposed. Cold air drifts through freely.",
            on_knock = "There's nothing left to knock on.",
            on_push = "The door is gone.",
            on_pull = "The door is gone.",
        },
    },

    transitions = {
        {
            from = "barred", to = "unbarred", verb = "unbar",
            aliases = {"lift bar", "remove bar"},
            message = "You grip the iron bar and heave it from its brackets. It comes free with a groan of metal on metal, heavy in your hands. You lean it against the wall. The door is free.",
            mutate = {
                keywords = { add = "unbarred", remove = {"barred", "iron bar"} },
            },
        },
        {
            from = "unbarred", to = "open", verb = "open",
            aliases = {"push"},
            message = "You push the door. It swings inward on groaning iron hinges, revealing the dim bedchamber beyond. Cold, stale air washes over you.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "unbarred", verb = "close",
            aliases = {"shut"},
            message = "You pull the door shut from the corridor side. It closes with a heavy thud.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "unbarred", to = "barred", verb = "bar",
            aliases = {"lock", "replace bar"},
            message = "You heave the iron bar back into its brackets. The door is barred once more.",
            mutate = {
                keywords = { add = {"barred", "iron bar"}, remove = "unbarred" },
            },
        },
        {
            from = "barred", to = "broken", verb = "break",
            requires_strength = 3,
            message = "You slam into the door from the corridor side. The oak cracks, the iron bar tears free, and the door bursts inward in a shower of splinters!",
            spawns = {"wood-splinters"},
            mutate = {
                keywords = { add = "broken", remove = {"barred", "iron bar"} },
            },
        },
    },

    on_traverse = {
        wind_effect = {
            strength = "draught",
            extinguishes = { "candle" },
            spares = { wind_resistant = true },
            message_extinguish = "As you step through the doorway into the bedroom, a cold draught follows you and snuffs your candle flame. Darkness.",
            message_spared = "A cold draught follows you through the doorway. Your lantern flame shivers but holds.",
            message_no_light = nil,
        },
    },

    mutations = {},
}
