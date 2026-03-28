return {
    guid = "b7d2e3f4-a891-4c56-9e38-d7f1b2c4a605",
    template = "room",

    id = "cellar",
    name = "The Cellar",
    level = { number = 1, name = "The Awakening" },
    sky_visible = false,
    keywords = {"cellar", "basement", "underground", "cellar room"},
    description = "You stand at the foot of a narrow stone stairway in a low-ceilinged cellar. The walls are rough-hewn granite, slick with moisture that catches what little light there is. An iron brazier squats against the far wall, its basin blackened with old ash. Water drips somewhere in the darkness, a slow and patient rhythm. The air is cold and heavy, thick with the smell of damp earth, old stone, and something faintly metallic. Cobwebs hang in thick curtains from the ceiling, swaying in a draft you cannot feel.",
    short_description = "A cold, damp cellar of rough stone and dripping water.",

    on_smell = "Damp earth, cold stone, and something faintly metallic -- iron, perhaps, or old blood. The air is thick and stale, as if it has not moved in a very long time.",

    instances = {
        { id = "barrel",         type = "Barrel",         type_id = "c3e8f1a2-b4d7-4596-8e23-f9a1b6c5d402" },
        { id = "torch-bracket",  type = "Torch Bracket",  type_id = "d9f4a2b3-c5e8-4167-9d34-e8b2c7d6f513" },
        { id = "cellar-bedroom-trapdoor-up", type_id = "{c915adfa-df5c-40bb-987f-751be2cc7525}" },
        { id = "cellar-storage-door-north", type_id = "{cd7f2d60-8528-4a7f-9236-0bfaad8c399d}" },
        { id = "cellar-rat", type_id = "{071e73f6-535e-42cb-b981-ebf85c27356f}" },
        { id = "cellar-spider", type_id = "{f67e3d8b-ecab-41a4-9f3e-79da4c5374ae}",
            placement = {
                position = "floor",
                wall = "south",
                near = "barrel",
                web_zones = {"barrel-side-corner", "torch-bracket-corner"},
                blocked_zones = {"near-brazier", "exits"},
                max_webs = 2,
                avoids = { brazier = "if_lit" },
                prefers = "dark_corners",
            },
        },
        { id = "cellar-brazier", type_id = "{22b77e90-8407-427a-a272-6b88277ba1fc}" },
    },

    exits = {
        up = { portal = "cellar-bedroom-trapdoor-up" },
        north = { portal = "cellar-storage-door-north" },
    },

    on_enter = function(self)
        return "You descend the narrow stone stairway, each step taking you deeper into cold, damp air. The smell of earth and old stone grows stronger with every step."
    end,

    mutations = {},
}
