-- courtyard-bedroom-window-in.lua — Portal object: courtyard side of bedroom window
-- Paired with: bedroom-courtyard-window-out.lua (bedroom side)
-- Replaces: courtyard.exits.up (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #199
return {
    guid = "{5d1c820d-679c-4c65-a114-2e921b59b835}",
    template = "portal",

    id = "courtyard-bedroom-window-in",
    name = "the bedroom window high above",
    material = "glass",
    keywords = {"window", "bedroom window", "high window", "upper window"},
    size = 5,
    weight = 80,
    portable = false,
    categories = {"architecture", "glass", "portal"},

    portal = {
        target = "start-room",
        bidirectional_id = "{8c37724d-6b68-4a85-9502-704b8147f99a}",
        direction_hint = "window",
    },

    max_carry_size = 2,
    max_carry_weight = 10,
    requires_hands_free = true,
    player_max_size = 4,

    description = "Far above, the bedroom window is visible — a dark rectangle high on the south wall. The drop was dangerous; climbing back would be harder still.",
    room_presence = "High on the south wall, the bedroom window is a dark rectangle against the stone.",
    on_examine = "The bedroom window is two stories up, set deep in the stone wall. The wall is rough stone with ivy clinging to it — possible handholds, but a treacherous climb. The window frame is barely visible in the moonlight.",
    on_feel = "You reach up toward the wall. Rough stone, cold and damp, with thick ropes of ivy. The window is far above — you'd need to climb the ivy to reach it. The stems feel strong enough, but it's a long way up.",
    on_smell = "Ivy, wet stone, and the cold night air. The smell of rain and chimney smoke fills the courtyard.",
    on_listen = "Wind whispers through the ivy. From far above, the faint rattle of glass panes in their lead frames. The courtyard is open to the sky — sounds carry and die quickly.",
    on_taste = "You chew an ivy leaf. Bitter and waxy, with a faint green bitterness.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "the bedroom window (latched)",
            description = "The bedroom window is high above, dark and shut tight. No way to reach it from down here — and even if you could, the latch is on the inside.",
            room_presence = "High on the south wall, the bedroom window is shut and dark.",
            on_examine = "Two stories up, latched from within. The ivy on the wall might bear your weight, but the window is sealed.",
            on_feel = "Rough stone wall, thick ivy. The window is far out of reach.",
            on_listen = "Wind rattles the distant panes. The latch holds from within.",
        },

        closed = {
            traversable = false,
            name = "the bedroom window (unlatched)",
            description = "The bedroom window is high above. The latch appears to be open, but the window itself is still closed.",
            room_presence = "High on the south wall, the bedroom window is dark but unlatched.",
            on_examine = "The latch has been opened from inside. The window is still shut, but if you could reach it, a push might open it.",
            on_feel = "The wall, the ivy, the distance. The window is too high to reach easily.",
            on_listen = "The window rattles more loosely now — unlatched.",
        },

        open = {
            traversable = true,
            name = "the bedroom window (open)",
            description = "The bedroom window stands open high above. The ivy on the wall provides a treacherous but possible climbing route.",
            room_presence = "The bedroom window stands open high on the south wall. Ivy trails down the stone — a possible climb.",
            on_examine = "The window is open — a dark rectangle two stories up. The wall is covered in thick ivy. It would be a dangerous climb, but the stems look strong enough to hold your weight.",
            on_feel = "Thick ivy stems, rough stone. You could climb this — carefully.",
            on_listen = "Cold air spills from the open window above. You hear the faint sounds of the bedroom — creaking floorboards, settling stone.",
        },

        broken = {
            traversable = true,
            name = "the bedroom window (shattered)",
            description = "Where the bedroom window was, a dark hole gapes in the stone wall two stories up. Glass shards glitter on the cobblestones below.",
            room_presence = "The bedroom window is shattered — a dark hole in the south wall, two stories up. Glass shards litter the cobblestones.",
            on_examine = "The window is destroyed. Jagged glass edges catch the moonlight. Climbing up through the broken frame would be treacherous — the shards could cut you badly.",
            on_feel = "Glass crunches underfoot on the cobblestones. The wall above is the same — ivy and rough stone, but the window frame now bristles with broken glass.",
            on_listen = "Wind moans through the broken window above. Glass shards tinkle faintly.",
        },
    },

    transitions = {
        {
            from = "locked", to = "open", verb = "open",
            aliases = {"push open"},
            message = "The window swings open far above. Cold bedroom air drifts down. The ivy on the wall provides a path up — if you dare.",
            mutate = {
                keywords = { add = {"open", "unlatched"} },
            },
        },
        {
            from = "locked", to = "closed", verb = "unlock",
            message = "You hear a faint click from high above — the latch has been opened from the bedroom side.",
            mutate = {
                keywords = { add = "unlatched" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            message = "The window latches shut from inside. The click carries faintly down to the courtyard.",
            mutate = {
                keywords = { remove = "unlatched" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            message = "The window swings open high above. Cold bedroom air drifts down. The ivy on the wall provides a path up — if you dare.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            message = "The window is pulled shut from above. The courtyard grows quieter.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "locked", to = "broken", verb = "break",
            requires_strength = 2,
            message = "The window shatters! Glass rains down into the courtyard, glittering in the moonlight. Shards skitter across the cobblestones.",
            spawns = {"glass-shard", "glass-shard"},
            mutate = {
                keywords = { add = {"broken", "shattered"} },
            },
        },
        {
            from = "closed", to = "broken", verb = "break",
            requires_strength = 1,
            message = "The unlatched window bursts! Glass showers down into the courtyard.",
            spawns = {"glass-shard", "glass-shard"},
            mutate = {
                keywords = { add = {"broken", "shattered"}, remove = "unlatched" },
            },
        },
    },

    on_traverse = {
        wind_effect = {
            strength = "gust",
            extinguishes = { "candle" },
            spares = { wind_resistant = true },
            message_extinguish = "As you haul yourself up the ivy and through the window, the wind snuffs your candle. You tumble into the dark bedroom.",
            message_spared = "Wind buffets you as you climb the ivy. Your lantern flame shivers but holds as you pull yourself through the window.",
            message_no_light = nil,
        },
    },

    mutations = {},
}
