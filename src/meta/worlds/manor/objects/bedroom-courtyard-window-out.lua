-- bedroom-courtyard-window-out.lua — Portal object: bedroom side of leaded glass window
-- Paired with: courtyard-bedroom-window-in.lua (courtyard side)
-- Replaces: start-room.exits.window (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #199
return {
    guid = "{5a9a6d9f-f112-499e-8f1e-dae571675015}",
    template = "portal",

    id = "bedroom-courtyard-window-out",
    name = "a leaded glass window",
    material = "glass",
    keywords = {"window", "glass", "leaded window", "pane", "leaded glass",
                "glass window", "leaded glass window"},
    size = 5,
    weight = 80,
    portable = false,
    categories = {"architecture", "glass", "portal"},

    portal = {
        target = "courtyard",
        bidirectional_id = "{8c37724d-6b68-4a85-9502-704b8147f99a}",
        direction_hint = "window",
    },

    max_carry_size = 2,
    max_carry_weight = 10,
    requires_hands_free = true,
    player_max_size = 4,

    description = "A tall window of diamond-paned leaded glass, set deep in the stone wall. Through the warped glass you glimpse rooftops and a moonlit courtyard far below.",
    room_presence = "A tall leaded glass window is set deep in the south wall, its diamond panes dark against the night sky.",
    on_examine = "Diamond-shaped panes of thick, warped glass are held in a lattice of dark lead came. An iron latch secures the window shut. Through the glass, distorted by age, you glimpse moonlit rooftops and a cobblestone courtyard far below — a dangerous drop.",
    on_feel = "Cold glass under your fingers, the raised ridges of lead came between the diamond panes. An iron latch — stiff with age and rust, but it could be moved. The stone sill is deep enough to sit in, worn smooth by years.",
    on_smell = "Cold air seeps around the edges of the frame — the smell of night, rain, and chimney smoke from outside.",
    on_listen = "Wind presses against the glass, making the panes rattle faintly in their lead frames. From beyond: the distant creak of a sign or shutter, and the hush of a courtyard open to the sky.",
    on_taste = "You press your tongue to the glass. Cold, gritty, with a faint metallic tang from the lead.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a latched leaded glass window",
            description = "A tall window of diamond-paned leaded glass, latched shut with an iron latch. Through the warped glass you glimpse rooftops and a moonlit courtyard far below.",
            room_presence = "A tall leaded glass window is set in the south wall, its iron latch shut tight.",
            on_examine = "The iron latch holds the window firmly shut. The glass is thick and warped with age. Beyond: moonlit rooftops and a courtyard far below.",
            on_feel = "Cold glass, lead came ridges, and the iron latch — stiff with rust. The window doesn't budge.",
            on_smell = "Faint night air seeps around the frame. Rain and chimney smoke.",
            on_listen = "Wind rattles the panes faintly. The latch holds firm.",
        },

        closed = {
            traversable = false,
            name = "an unlatched leaded glass window",
            description = "The leaded glass window stands unlatched. The iron latch has been slid aside, shedding flakes of rust.",
            room_presence = "The leaded glass window in the south wall is unlatched, its iron latch pushed aside.",
            on_examine = "The iron latch is open. The window could be pushed outward. Beyond the glass: moonlight, rooftops, the courtyard below.",
            on_feel = "The window shifts slightly in its frame. No longer latched. A push would open it.",
            on_smell = "Cold air seeps more freely now that the seal is broken. Rain and chimney smoke.",
            on_listen = "The unlatched window rattles in its frame. Wind whistles through the gap.",
        },

        open = {
            traversable = true,
            name = "an open leaded glass window",
            description = "The leaded glass window stands open. Cold night air drifts in, carrying the scent of rain and chimney smoke from the courtyard below.",
            room_presence = "The leaded glass window in the south wall stands open to the night. Cold air streams in.",
            on_examine = "The window swings outward on iron hinges. Below: a cobblestone courtyard bathed in moonlight. The drop is significant — two stories at least.",
            on_feel = "Cold night air rushes through the opening. The stone sill is wet with condensation. The drop below is dizzying.",
            on_smell = "Night air floods in — rain on cobblestones, chimney smoke, the green smell of ivy from the walls below.",
            on_listen = "Wind howls through the opening. The distant creak of the well's winch. An owl hoots somewhere in the darkness.",
        },

        broken = {
            traversable = true,
            name = "a shattered window frame",
            description = "Jagged shards of leaded glass cling to the stone frame like broken teeth. Cold air howls through the gap. The courtyard is visible far below — a dangerous drop.",
            room_presence = "A shattered window frame gapes in the south wall. Glass shards cling to the stone like broken teeth.",
            on_examine = "The glass is destroyed. Jagged shards of lead-framed glass jut from the stone frame. Wind keens through the gap. The courtyard below is visible — two stories down, cobblestones and moonlight.",
            on_feel = "Jagged glass edges and bent lead came. Mind your fingers — sharp enough to cut. Wind howls through the gap.",
            on_smell = "The full smell of the night pours through — rain, stone, ivy, chimney smoke, and the mineral tang of shattered glass.",
            on_listen = "Wind sings through the broken frame. Glass shards tinkle against stone when the gusts are strong.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            aliases = {"unlatch", "open latch", "slide latch"},
            message = "You slide the iron latch aside. It moves reluctantly, shedding flakes of rust.",
            mutate = {
                keywords = { add = "unlatched", remove = "latched" },
            },
        },
        {
            from = "locked", to = "open", verb = "open",
            aliases = {"push open"},
            message = "You unlatch the iron catch and push the window open. Cold air rushes in, guttering the candle flame. Below, the courtyard stretches out in the moonlight — a long way down.",
            mutate = {
                keywords = { add = {"open", "unlatched"}, remove = "latched" },
            },
        },
        {
            from = "closed", to = "locked", verb = "lock",
            aliases = {"latch", "close latch"},
            message = "You push the iron latch back into place. It catches with a gritty click.",
            mutate = {
                keywords = { add = "latched", remove = "unlatched" },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push"},
            message = "You push the window open. Cold air rushes in, guttering the candle flame. Below, the courtyard stretches out in the moonlight — a long way down.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut", "pull"},
            message = "You pull the window shut. The sounds of the night are muffled once more.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "locked", to = "broken", verb = "break",
            aliases = {"smash", "shatter"},
            requires_strength = 2,
            message = "The window explodes inward in a shower of glass! Shards skitter across the stone floor. Cold air howls through the gap.",
            spawns = {"glass-shard", "glass-shard"},
            mutate = {
                keywords = { add = {"broken", "shattered"}, remove = "latched" },
            },
        },
        {
            from = "closed", to = "broken", verb = "break",
            aliases = {"smash", "shatter"},
            requires_strength = 1,
            message = "You smash through the unlatched window! Glass sprays outward into the night. Shards rain down on the cobblestones far below.",
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
            message_extinguish = "As you climb through the window, a gust of night wind snuffs your candle flame. You cling to the sill in sudden darkness.",
            message_spared = "Wind gusts through the window as you climb through. Your lantern flame dances but holds.",
            message_no_light = nil,
        },
    },

    mutations = {},
}
