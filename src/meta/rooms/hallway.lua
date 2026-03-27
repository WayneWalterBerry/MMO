return {
    guid = "bb964e65-2233-4624-8757-9ec31d278530",
    template = "room",

    id = "hallway",
    name = "The Manor Hallway",
    level = { number = 1, name = "The Awakening" },
    sky_visible = false,
    keywords = {"hallway", "corridor", "hall", "manor", "passage", "manor hallway"},
    description = "Warmth. After the cellars, the warmth is the first thing you notice. You stand in a wide, wood-paneled corridor lit by torches in iron brackets. The floor is polished oak that gleams in the firelight, and the walls are plastered white above dark wainscoting. Portraits hang at regular intervals — stern faces in heavy frames, watching. Doors lead off to left and right, all of them closed. The air smells of beeswax, old wood, and the faint char of torch smoke. At the far end, a grand staircase ascends into shadow.",
    short_description = "A warm, torchlit corridor lined with portraits and closed doors.",

    on_feel = "Smooth wood underfoot — not stone, not earth, but warm, polished boards that creak beneath your weight. The walls are smooth plaster above and carved wood below — wainscoting, you think, running your fingers along the grooves. The air is warm. You smell beeswax and wood smoke. Ahead and to both sides, your hands find closed doors — smooth oak, latched. The corridor is wide; you can stretch both arms without touching the walls.",

    on_smell = "Beeswax polish on the wooden floor and paneling — the warm, honey-sweet scent of a well-maintained home. Torch smoke, acrid but not unpleasant, curling from the iron brackets. Old wood — oak, seasoned and oiled. And beneath it all, the faintest trace of absence: dust settling on surfaces that were recently clean, the smell of a house where the fires have been tended but the people have gone.",

    on_listen = "The crackle and hiss of the torches in their brackets — living fire, the first you've heard since the bedroom. Your footsteps on the oak floor, loud and hollow after the muffled earth of the cellars. The creak of old timbers above. And silence where there should be people: no voices, no footsteps, no doors opening. The manor is warm and lit, but utterly empty.",

    temperature = 18,
    moisture = 0.15,
    light_level = 3,

    -- BUG-050: These objects are already described in room.description
    embedded_presences = {
        "torch-lit-west", "torch-lit-east",
        "portrait-1", "portrait-2", "portrait-3",
    },

    instances = {
        -- Torches
        { id = "torch-lit-west",          type = "Lit Torch",     type_id = "816862a1-c892-45ba-8d0f-2a72315f8eb2" },
        { id = "torch-lit-east",          type = "Lit Torch",     type_id = "816862a1-c892-45ba-8d0f-2a72315f8eb2" },

        -- Portraits
        { id = "portrait-1",              type = "Portrait",      type_id = "21c70054-ed7f-4873-ac0e-f8c90a2ff18a" },
        { id = "portrait-2",              type = "Portrait",      type_id = "21c70054-ed7f-4873-ac0e-f8c90a2ff18a" },
        { id = "portrait-3",              type = "Portrait",      type_id = "21c70054-ed7f-4873-ac0e-f8c90a2ff18a" },

        -- === Side Table ===
        { id = "side-table",              type = "Side Table",    type_id = "b9c53625-2c37-4a70-988b-0769375705bd",
            on_top = {
                { id = "vase",                    type = "Vase",          type_id = "1ae1f401-2c06-421c-8530-eb339c061a9f" },
            },
        },

        -- === South portal (bedroom-hallway door, hallway side) ===
        { id = "bedroom-hallway-door-south", type_id = "{a47ce304-4425-4bd0-a9e9-224b7c8baa8c}" },
        { id = "hallway-deep-cellar-stairs-down", type_id = "{becc667f-877b-49e7-bee0-32fc49d48af6}" },
        { id = "hallway-level2-stairs-up", type_id = "{13cec4d5-cbff-4d71-a983-63752d7fe99a}" },
        { id = "hallway-west-door", type_id = "{2c11b569-9d5d-481c-bed8-070c55ceba6c}" },
        { id = "hallway-east-door", type_id = "{22f675a7-1827-4cf3-bbde-40ed2c109c3a}" },
        { id = "hallway-wolf", type_id = "{e69fc5e8-ce63-4b26-b5b2-faa2ff85d12c}" },
    },

    exits = {
        south = { portal = "bedroom-hallway-door-south" },
        down = { portal = "hallway-deep-cellar-stairs-down" },
        north = { portal = "hallway-level2-stairs-up" },
        west = { portal = "hallway-west-door" },
        east = { portal = "hallway-east-door" },
    },

    on_enter = function(self)
        return "You emerge from the stairway into warmth and light. Torchlight flickers across polished oak floorboards and whitewashed walls. After the cold darkness below, the hallway feels almost impossibly welcoming — warm air, the crackle of fire, the sweet smell of beeswax. You've made it out."
    end,

    mutations = {},
}
