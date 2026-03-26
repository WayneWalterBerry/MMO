-- courtyard-kitchen-door.lua — Portal object: courtyard kitchen door (BOUNDARY)
-- One-way boundary portal — no paired object (manor-kitchen does not exist yet)
-- Replaces: courtyard.exits.east (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #208
return {
    guid = "{2c28ab89-693b-4612-b828-b8386f7ad090}",
    template = "portal",

    id = "courtyard-kitchen-door",
    name = "a stout wooden door",
    material = "wood",
    keywords = {"door", "wooden door", "kitchen door", "east door",
                "stout door", "warped door"},
    size = 6,
    weight = 100,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "manor-kitchen",
        bidirectional_id = nil,
        direction_hint = "east",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A stout wooden door, warped with age and damp. The latch is rusted shut. Through the crack beneath it, you smell old cooking fires and grease.",
    room_presence = "A stout wooden door stands in the east wall, warped and rusted shut. The smell of old grease drifts from beneath it.",
    on_examine = "A stout wooden door of heavy planks, swollen and warped by years of rain and damp. The latch is a simple iron bar, seized with rust — the orange crust has welded it shut. The hinges are on the inside. Through the crack beneath the door, warm air carries the smell of old cooking fires, rendered grease, and cold ash. The wood is weathered grey on this side, darkened by exposure.",
    on_feel = "Swollen wood, rough and damp. The latch is a simple iron bar, seized with rust. The hinges are on the inside — you'd have to go through it, not around it. The gap beneath the door lets through a draft that smells of grease and cold ash.",
    on_smell = "Old cooking grease, cold ash, dried herbs. The warm, stale smell of a kitchen unused but not yet empty. From outside: rain, wet cobblestones, the clean smell of night air.",
    on_listen = "The door creaks faintly in the wind. From beyond: the tick of cooling metal, the occasional drip of something — condensation, perhaps, from a cold flue. An empty kitchen.",
    on_taste = "Weathered wood, damp and slightly salty from rain. The grain is rough against your tongue.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a rusted-shut wooden door",
            description = "A stout wooden door, warped with age and damp. The iron latch is seized with rust.",
            room_presence = "A stout wooden door stands in the east wall, its iron latch rusted shut.",
            on_examine = "The iron latch is rusted solid — orange crust has welded it to the bracket. Brute force or a tool might free it.",
            on_feel = "Swollen wood, rusted iron. The latch is seized. The door does not budge.",
            on_smell = "Old grease and cold ash from the kitchen beyond.",
            on_listen = "The door creaks in the wind. The latch is solid.",
        },

        closed = {
            traversable = false,
            name = "an unlatched wooden door",
            description = "The wooden door's latch has been forced aside, though the wood is still swollen in its frame.",
            room_presence = "The kitchen door's rusted latch has been forced aside, but the swollen wood holds the door shut.",
            on_examine = "The rusted latch has been forced open — rust flakes litter the cobblestones. The door is swollen in its frame, but a good shove might open it.",
            on_feel = "The latch is open, rust flaking off. The door is stuck — swollen wood wedged tight in the frame. A hard push might do it.",
            on_smell = "More kitchen air seeps through the loosened frame. Grease, cold ash, herbs.",
            on_listen = "The door rattles in its frame, no longer held by the latch. Wind catches it.",
        },

        open = {
            traversable = true,
            name = "an open wooden door",
            description = "The wooden door stands open, revealing a dim kitchen passage beyond.",
            room_presence = "The kitchen door stands open. The smell of old cooking drifts into the courtyard.",
            on_examine = "The door stands open, scraped against the flagstones inside. Beyond: a dim kitchen passage, the shapes of shelves and pots visible in the darkness.",
            on_feel = "The open door edge, rough and swollen. Warmer air drifts from the kitchen beyond.",
            on_smell = "Old cooking grease, cold ash, dried herbs — the full smell of the kitchen pours through the open door.",
            on_listen = "From the kitchen: the tick of cooling metal, the drip of condensation, the settling of an empty house.",
        },

        broken = {
            traversable = true,
            name = "a splintered doorway",
            description = "Where the wooden door once stood, only splintered planks and a twisted latch remain. The smell of old cooking grease drifts through the gap.",
            room_presence = "The kitchen doorway is splintered open. Broken planks and a twisted latch are all that remain.",
            on_examine = "The door is destroyed — warped planks splintered, the rusted latch torn free. The kitchen beyond is visible through the gap.",
            on_feel = "Jagged splinters and bent iron. The door has been smashed through.",
            on_smell = "Old grease, cold ash, and the sharper smell of freshly splintered wood.",
            on_listen = "Wind blows freely through the shattered doorway into the kitchen.",
        },
    },

    transitions = {
        {
            from = "locked", to = "closed", verb = "unlock",
            aliases = {"force latch", "free latch"},
            message = "With effort, you work the rusted latch free. It scrapes open with a grinding protest, shedding flakes of orange rust.",
            mutate = {
                keywords = { add = "unlatched", remove = {"rusted", "locked"} },
            },
        },
        {
            from = "closed", to = "open", verb = "open",
            aliases = {"push", "shove"},
            message = "You put your shoulder to the swollen door and shove. It scrapes open, grudging every inch, leaving a gouge in the flagstones inside.",
            mutate = {
                keywords = { add = "open" },
            },
        },
        {
            from = "open", to = "closed", verb = "close",
            aliases = {"shut"},
            message = "You force the swollen door shut. It sticks in its frame with a wet thud.",
            mutate = {
                keywords = { remove = "open" },
            },
        },
        {
            from = "locked", to = "broken", verb = "break",
            aliases = {"smash", "kick"},
            requires_strength = 3,
            message = "The warped door gives way with a crack of splintering wood! The rusted latch tears free and clatters across the cobblestones.",
            spawns = {"wood-splinters"},
            mutate = {
                keywords = { add = {"broken", "splintered"}, remove = {"rusted", "locked"} },
            },
        },
        {
            from = "closed", to = "broken", verb = "break",
            aliases = {"smash", "kick"},
            requires_strength = 2,
            message = "You slam into the unlatched door. The swollen wood cracks and splits, collapsing inward in a shower of splinters!",
            spawns = {"wood-splinters"},
            mutate = {
                keywords = { add = {"broken", "splintered"}, remove = "unlatched" },
            },
        },
    },

    on_traverse = {},

    mutations = {},
}
