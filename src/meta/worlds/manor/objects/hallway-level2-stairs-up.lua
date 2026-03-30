-- hallway-level2-stairs-up.lua — Portal object: hallway side of level 2 staircase (BOUNDARY)
-- One-way boundary portal — no paired object (level 2 does not exist yet)
-- Replaces: hallway.exits.north (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #205
return {
    guid = "{13cec4d5-cbff-4d71-a983-63752d7fe99a}",
    template = "portal",

    id = "hallway-level2-stairs-up",
    name = "a grand staircase",
    material = "oak",
    keywords = {"staircase", "stairs", "grand staircase", "up", "grand stairs",
                "bannister", "stairway", "upper floors"},
    size = 8,
    weight = 500,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "level-2",
        bidirectional_id = nil,
        direction_hint = "up",
    },

    max_carry_size = 5,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A grand staircase of polished oak ascends to the upper floors. The bannister is carved with symbols — familiar now, unsettling. The stairs curve upward out of sight, but rubble blocks the way.",
    room_presence = "A grand staircase of polished oak ascends toward the upper floors, but rubble and fallen beams block the way.",
    on_examine = "A grand staircase of polished oak, wide enough for three abreast, ascends toward the upper floors. The bannister is carved with the same interlocking circles and angular script you saw in the deep cellar — the symbols repeat endlessly up the rail. But halfway up, the staircase is choked with rubble — fallen ceiling beams, chunks of plaster, and broken stone. Something collapsed above. The way is completely blocked.",
    on_feel = "Polished oak under your hand — the bannister is smooth, carved with deep grooves that form repeating symbols. The first few steps are solid and well-maintained. But higher up, your feet find broken stone, splintered wood, dust and debris. The staircase is blocked. You cannot pass.",
    on_smell = "Beeswax polish on the lower stairs, the same warm scent as the hallway floor. Higher up: dust, broken plaster, the sharp smell of recently disturbed masonry. Something collapsed not too long ago.",
    on_listen = "The lower stairs creak under your weight. Higher up: the occasional patter of loose plaster falling. The settling groans of damaged timbers. Beyond the rubble: silence. Whatever is up there, it's sealed off.",
    on_taste = "Polished oak and dust. Higher up, the air tastes of broken plaster and stone dust.",

    initial_state = "blocked",
    _state = "blocked",

    states = {
        blocked = {
            traversable = false,
            name = "a blocked grand staircase",
            description = "The grand staircase is choked with rubble and fallen beams. The way to the upper floors is completely blocked.",
            room_presence = "A grand staircase of polished oak ascends toward the upper floors, but rubble and fallen beams block the way.",
            on_examine = "Fallen ceiling beams, chunks of plaster, and broken stone choke the staircase halfway up. The collapse looks structural — it would take serious effort to clear. The way is impassable.",
            on_feel = "Broken stone, splintered wood, dust. The rubble is heavy and tightly packed. You cannot push through.",
            on_smell = "Dust, broken plaster, the sharp scent of disturbed masonry.",
            on_listen = "Loose plaster patters down occasionally. Damaged timbers groan. The upper floors are sealed.",
            blocked_message = "The stairway leads up but rubble blocks the way. Fallen beams and broken stone choke the staircase halfway up. You cannot pass.",
        },
    },

    transitions = {},

    on_traverse = {},

    mutations = {},
}
