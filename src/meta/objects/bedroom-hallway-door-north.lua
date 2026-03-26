-- bedroom-hallway-door-north.lua — Portal object: bedroom side of oak door
-- Paired with: bedroom-hallway-door-south.lua (hallway side)
-- Replaces: bedroom-door.lua (furniture) + start-room.exits.north (inline exit)
-- See: plans/portal-unification-plan.md (Phase 2), Issue #198
return {
    guid = "{25852832-6f19-48af-a118-20350ac8d243}",
    template = "portal",

    id = "bedroom-hallway-door-north",
    name = "a heavy oak door",
    material = "oak",
    keywords = {"door", "heavy door", "bedroom door", "oak door",
                "heavy oak door", "north door", "iron bands", "barred door"},
    size = 6,
    weight = 120,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "hallway",
        bidirectional_id = "{4bb381ad-2c9d-4926-8ebc-e55d8e48f4c4}",
        direction_hint = "north",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    -- Descriptions (bedroom perspective — no keyhole, no handle, bar on other side)
    description = "A heavy oak door with iron bands. It appears to be barred from the other side.",
    room_presence = "A heavy oak door with iron bands stands in the north wall, barred from the corridor beyond.",
    on_examine = "Thick oak planks, darkened with age, bound together by three horizontal iron bands. The hinges are heavy iron, bolted deep into the stone frame. There is no keyhole on this side — no handle either, just smooth oak and cold iron. The door sits tight in its frame. From beyond comes the faint creak of something heavy resting in iron brackets — a bar, laid across the other side.",
    on_feel = "Rough oak grain under your fingers, cold iron bands riveted flat against the wood. The door is solid — no give when you push. You trace the edge where wood meets stone: sealed tight, not even a draught slips through.",
    on_smell = "Old oak and iron. A faint staleness from the corridor beyond, like dust and cold stone.",
    on_listen = "You press your ear to the oak. Silence at first — then the faint creak of the iron bar shifting in its brackets as the building settles. No footsteps. No voices. Just the bar, and the weight of the door.",
    on_taste = "You press your tongue to the oak. Dry, gritty wood grain and the metallic bite of iron. It tastes of age.",
    on_knock = "You rap your knuckles against the oak. A deep, dull thud — the door is thick and heavy. The sound dies quickly, swallowed by the corridor beyond. No one answers.",
    on_push = "You set your shoulder against the oak and push. The door doesn't budge. Something heavy holds it from the other side — the iron bar in its brackets.",
    on_pull = "You grip the edge of the door and pull. It doesn't move. The hinges open inward, and whatever bars it from the hallway holds fast.",

    -- FSM — barred → unbarred → open (and barred → broken)
    initial_state = "barred",
    _state = "barred",

    states = {
        barred = {
            traversable = false,
            name = "a heavy oak door",
            description = "A heavy oak door with iron bands. It appears to be barred from the other side.",
            room_presence = "A heavy oak door with iron bands stands in the north wall, barred from the corridor beyond.",
            on_examine = "Thick oak planks bound by iron bands. No keyhole on this side. From beyond: the creak of a heavy bar in its brackets.",
            on_feel = "Rough oak grain, cold iron bands. Solid — no give when you push.",
            on_smell = "Old oak and iron. Staleness from the corridor beyond.",
            on_listen = "The faint creak of the iron bar shifting in its brackets. No footsteps.",
            on_knock = "A deep, dull thud. No one answers.",
            on_push = "The door doesn't budge. The iron bar holds from the other side.",
            on_pull = "It doesn't move. The hinges open inward, and the bar holds fast.",
        },

        unbarred = {
            traversable = false,
            name = "an unbarred oak door",
            description = "The heavy oak door stands unbarred, closed but no longer held fast.",
            room_presence = "The heavy oak door to the north stands unbarred.",
            on_examine = "The door is free in its frame — the bar has been removed from the other side. It could be pushed open.",
            on_feel = "The door shifts slightly in its frame. No longer held.",
            on_smell = "Corridor air seeps through the gap — dust, cold stone, a hint of torch smoke.",
            on_listen = "A faint draught whistles through the gap between door and frame.",
            on_knock = "A hollow thud. The door rattles slightly in its frame.",
            on_push = "The door is ready to open. Push harder to swing it wide.",
            on_pull = "The hinges open inward. Try pushing instead.",
        },

        open = {
            traversable = true,
            name = "an open oak door",
            description = "The heavy oak door stands open, revealing a dim corridor beyond.",
            room_presence = "The heavy oak door to the north stands open to the corridor.",
            on_examine = "The door stands open on heavy iron hinges. Beyond: a dim stone corridor stretching into shadow.",
            on_feel = "The open door edge, worn smooth. Cool corridor air drifts through.",
            on_smell = "Cold stone, old dust, and the faintest trace of torch smoke from the corridor.",
            on_listen = "The corridor beyond: distant dripping, the settling of old stone, the whisper of a draught.",
            on_knock = "You knock on the open door. It swings slightly on its hinges.",
            on_push = "The door is already open.",
            on_pull = "The door is already open. You could close it.",
        },

        broken = {
            traversable = true,
            name = "a splintered doorframe",
            description = "Where the oak door once stood, only splintered wood and twisted iron hinges remain.",
            room_presence = "A splintered doorframe gapes in the north wall, opening to the corridor.",
            on_examine = "Splintered oak and twisted iron. The door has been destroyed — only fragments remain in the frame.",
            on_feel = "Jagged splinters and bent iron. Mind your fingers.",
            on_smell = "Fresh-split oak and the tang of stressed iron.",
            on_listen = "The corridor beyond is fully exposed. Every sound carries.",
            on_knock = "There's nothing left to knock on.",
            on_push = "The door is gone.",
            on_pull = "The door is gone.",
        },
    },

    transitions = {
        {
            from = "barred", to = "unbarred", verb = "unbar",
            trigger = "exit_unbarred",
            message = "You hear the scrape of iron on iron as the bar is lifted from the other side. The door is free.",
            mutate = {
                keywords = { add = "unbarred", remove = "barred" },
            },
        },
        {
            from = "unbarred", to = "open", verb = "open",
            aliases = {"push"},
            message = "You push the door open. It swings inward on groaning iron hinges, revealing a dim stone corridor.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "unbarred", verb = "close",
            aliases = {"shut"},
            message = "You push the door shut. It closes with a heavy thud that echoes down the corridor.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "barred", to = "broken", verb = "break",
            requires_strength = 3,
            message = "You slam into the door with everything you have. The oak cracks, splinters fly, and the iron bar beyond tears free of its brackets. The door bursts inward!",
            spawns = {"wood-splinters"},
            mutate = {
                keywords = { add = "broken", remove = "barred" },
            },
        },
    },

    on_traverse = {
        wind_effect = {
            strength = "draught",
            extinguishes = { "candle" },
            spares = { wind_resistant = true },
            message_extinguish = "As you step through the doorway, a cold draught funnels through the corridor and snuffs your candle flame. Darkness.",
            message_spared = "A cold draught funnels through the doorway as you pass. Your lantern flame shivers but holds.",
            message_no_light = nil,
        },
    },

    mutations = {},
}
