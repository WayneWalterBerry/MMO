-- hallway-east-door.lua — Portal object: hallway east door (BOUNDARY)
-- One-way boundary portal — no paired object (manor-east does not exist yet)
-- Replaces: hallway.exits.east (inline exit)
-- See: plans/portal-unification-plan.md (Phase 3), Issue #207
return {
    guid = "{22f675a7-1827-4cf3-bbde-40ed2c109c3a}",
    template = "portal",

    id = "hallway-east-door",
    name = "a lighter oak door",
    material = "oak",
    keywords = {"door", "east door", "oak door", "kitchen door",
                "locked door", "lighter door"},
    size = 6,
    weight = 100,
    portable = false,
    categories = {"architecture", "wooden", "portal"},

    portal = {
        target = "manor-east",
        bidirectional_id = nil,
        direction_hint = "east",
    },

    max_carry_size = 4,
    max_carry_weight = 50,
    requires_hands_free = false,
    player_max_size = 5,

    description = "A lighter oak door, closed and latched. A warm smell seeps from underneath — old cooking fires, herbs, grease. The kitchen, perhaps.",
    room_presence = "A lighter oak door stands in the east wall, latched shut. The smell of old cooking drifts from beneath it.",
    on_examine = "A lighter oak door than the others in the hallway — thinner, less ornate, the wood darker from years of kitchen smoke seeping through. The latch is a simple iron bar, but it's been locked from the inside. Through the gap beneath the door, warm air drifts out carrying the smell of old cooking fires, dried herbs, and rendered grease. The kitchen, almost certainly.",
    on_feel = "Thinner oak than the west door, the wood slightly warm and greasy to the touch — kitchen smoke has permeated it over years. The latch is a simple iron bar, but locked from within. The door has more give than the west one but still won't open.",
    on_smell = "Old cooking fires — wood smoke and rendered fat. Dried herbs — rosemary, thyme, something sharper. Grease, worked into the wood over years. The warm, heavy smell of a kitchen long unattended but not yet cold.",
    on_listen = "From beyond: the occasional creak of wood. The tick of something cooling — a stove, perhaps, or a pot left on an ember. No voices, no clattering. A kitchen abandoned mid-task.",
    on_taste = "The wood tastes faintly of grease and wood smoke. Kitchen residue.",

    initial_state = "locked",
    _state = "locked",

    states = {
        locked = {
            traversable = false,
            name = "a latched oak door",
            description = "A lighter oak door, latched shut from inside. The smell of old cooking seeps from underneath.",
            room_presence = "A lighter oak door stands in the east wall, latched shut. Old cooking smells drift from beneath it.",
            on_examine = "Latched from the inside — a simple iron bar resting in a bracket. Through the wide gap beneath the door, warm air drifts out. A flat blade might slide under and lift the bar.",
            on_feel = "Thin oak, warm and greasy. The latch holds from within. There's a wide gap at the bottom — enough to slide something flat underneath.",
            on_smell = "Old cooking fires, dried herbs, grease from the kitchen beyond.",
            on_listen = "Creaking wood and the tick of something cooling. An abandoned kitchen.",
            blocked_message = "The latch is on the inside — a simple iron bar in a bracket. But there's a wide gap under the door. A flat blade might slide underneath and lift it.",
        },
        unlatched = {
            traversable = false,
            name = "an unlatched oak door",
            description = "The oak door stands ajar, the iron latch-bar dangling loose. Beyond, a short corridor ends in a wall of collapsed masonry — stone, timber, and plaster heaped floor to ceiling. The kitchen is unreachable.",
            room_presence = "The east door hangs open, but the passage beyond is choked with rubble.",
            on_examine = "You lifted the latch and the door swung open easily — but the corridor beyond has collapsed. Stone blocks, broken timber, and plaster dust fill the passage completely. No way through.",
            on_feel = "The door swings freely now. Beyond it, your hand meets rough stone and splintered wood — a solid wall of debris.",
            on_smell = "Dust and old mortar from the collapse, mixed with the fading scent of kitchen grease.",
            on_listen = "A faint draft whistles through gaps in the rubble. Somewhere beyond, a creak — the kitchen settling.",
            blocked_message = "The door is open, but the passage beyond has collapsed. Stone and timber block the way completely.",
        },
    },

    transitions = {
        { from = "locked", to = "unlatched", verb = "pry",
          requires_tool = "cutting_edge",
          message = "You slide the blade under the door and feel for the iron bar. With careful pressure, you lever it up and out of its bracket. The bar clatters to the floor on the other side. The door swings open — but the corridor beyond is choked with fallen masonry. No way through." },
    },

    on_traverse = {},

    mutations = {},
}
