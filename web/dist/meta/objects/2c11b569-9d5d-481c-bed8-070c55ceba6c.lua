-- hallway-west-door.lua — Portal object: hallway west door (BOUNDARY)
-- One-way boundary portal — no paired object (manor-west does not exist yet)
-- Replaces: hallway.exits.west (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #206
return {
    guid = "{2c11b569-9d5d-481c-bed8-070c55ceba6c}",
    template = "portal",

    id = "hallway-west-door",
    name = "a heavy oak door",
    material = "oak",
    keywords = {"door", "west door", "oak door", "locked door",
                "heavy door", "study door"},
    size = 6,
    weight = 120,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "manor-west",
        bidirectional_id = nil,
        direction_hint = "west",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A heavy oak door, closed and locked. Through the keyhole, you glimpse a darkened room beyond — bookshelves? A study?",
    room_presence = "A heavy oak door stands in the west wall, firmly locked.",
    on_examine = "A heavy oak door, well-fitted in its frame. The lock is a mortise type — the keyhole shows a darkened room beyond. You can just make out the shapes of tall bookshelves and what might be a desk. Dust motes drift in the narrow beam of light that passes through the keyhole. The door is solidly locked — no rattle, no give.",
    on_feel = "Smooth oak, well-maintained. The door is heavy and solid in its frame. The lock mechanism feels substantial — a good mortise lock, no cheap ironwork. The door does not budge. No gap around the frame. Whoever locked this meant it to stay locked.",
    on_smell = "Through the keyhole: the smell of old books, leather, dried ink, and dust. A study or library, sealed and undisturbed.",
    on_listen = "You press your ear to the oak. Silence from beyond — the complete silence of a sealed room. No creaking, no settling. Just dust and stillness.",
    on_taste = "Smooth oak and beeswax polish. Well-maintained wood.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a locked oak door",
            description = "A heavy oak door, firmly locked. Through the keyhole: bookshelves and dust.",
            room_presence = "A heavy oak door stands in the west wall, firmly locked.",
            on_examine = "Solidly locked. No key, no give. The room beyond is sealed.",
            on_feel = "Heavy oak, solid lock. The door does not budge.",
            on_smell = "Old books and dust from beyond the keyhole.",
            on_listen = "Silence from the sealed room beyond.",
            blocked_message = "This door is firmly locked. You have no key that fits, and the lock is too well-made to force.",
        },
    },

    transitions = {},

    on_traverse = {},

    mutations = {},
}
