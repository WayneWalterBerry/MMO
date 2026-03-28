return {
    guid = "{f67e3d8b-ecab-41a4-9f3e-79da4c5374ae}",
    template = "creature",
    id = "spider",
    name = "a large brown spider",
    keywords = {"spider", "arachnid", "brown spider", "creature"},
    description = "A palm-sized brown spider with thick, bristled legs and a bulbous abdomen marked with pale chevrons. It sits motionless at the center of a glistening web.",

    -- Physical properties
    size = "tiny",
    weight = 0.05,
    portable = false,
    material = "chitin",

    -- Animate
    animate = true,

    -- Sensory (on_feel is mandatory — primary dark sense)
    on_feel = "You brush sticky silk. Something large moves nearby. Hard, bristled legs scramble across your hand.",
    on_smell = "A faint, musty odor — old silk and dry insect husks.",
    on_listen = "Faint scratching, like tiny claws on stone.",
    on_taste = "Bitter chitin and a sharp, chemical sting on your tongue.",

    -- FSM
    initial_state = "alive-idle",
    _state = "alive-idle",
    states = {
        ["alive-idle"] = {
            description = "A large spider sits perfectly still at the center of its web, front legs raised and poised.",
            room_presence = "A glistening web stretches across the corner. A spider waits at its center.",
            on_listen = "Faint scratching, like tiny claws on stone.",
        },
        ["alive-web-building"] = {
            description = "The spider moves in deliberate circles, drawing silk from its spinnerets and anchoring new strands.",
            room_presence = "A spider works industriously, extending its web strand by strand.",
            on_listen = "A faint, rhythmic ticking — legs pulling silk taut.",
        },
        ["alive-flee"] = {
            description = "The spider drops from its web on a trailing line of silk and scuttles into a crack.",
            room_presence = "A spider scrambles toward the nearest crevice.",
            on_listen = "A frantic skittering across stone.",
        },
        ["alive-wander"] = {
            description = "A spider crawls about.",
            room_presence = "A spider crawls along the wall.",
        },
        ["*"] = {
            description = "A spider in an undefined state.",
        },
        dead = {
            description = "A dead spider lies curled on its back, legs drawn inward. Its web sags, abandoned.",
            room_presence = "A dead spider lies curled beneath a sagging web.",
            portable = true,
            animate = false,
            on_feel = "Dry, brittle legs that crumble at the touch. The body is hollow-light.",
            on_smell = "A faint chemical bitterness. Dry chitin.",
            on_listen = "Nothing. The web vibrates faintly in the air.",
            on_taste = "Dry shell and acrid venom. Your tongue goes numb.",
        },
    },
    transitions = {
        { from = "alive-idle",          to = "alive-web-building", verb = "_tick", condition = "web_build_roll" },
        { from = "alive-web-building",  to = "alive-idle",         verb = "_tick", condition = "web_complete" },
        { from = "alive-idle",          to = "alive-flee",         verb = "_tick", condition = "fear_high" },
        { from = "alive-web-building",  to = "alive-flee",         verb = "_tick", condition = "fear_high" },
        { from = "alive-flee",          to = "alive-idle",         verb = "_tick", condition = "fear_low" },
        { from = "*",                   to = "dead",               verb = "_damage", condition = "health_zero" },
    },

    -- Behavior metadata
    behavior = {
        default = "idle",
        aggression = 10,
        flee_threshold = 60,
        wander_chance = 10,
        settle_chance = 80,
        territorial = false,
        nocturnal = true,
        home_room = nil,
        web_builder = true,

        -- WAVE-4: Creature-created objects (spider spins webs)
        creates_object = {
            template = "spider-web",
            cooldown = 30,
            max_per_room = 2,
            narration = "The spider spins a web in the corner.",
        },

        -- WAVE-4: Ambush behavior near web
        web_ambush = {
            priority = 0.8,
            condition = function(creature, ctx)
                local webs = ctx.room:find_by_template("spider-web")
                for _, web in ipairs(webs) do
                    if web.trapped_creature then return true end
                end
                return false
            end,
        },
    },

    -- Drives
    drives = {
        hunger = {
            value = 20,
            decay_rate = 1,
            max = 100,
            satisfy_action = "eat",
            satisfy_threshold = 80,
        },
        fear = {
            value = 10,
            decay_rate = -5,
            max = 100,
            min = 0,
        },
        curiosity = {
            value = 10,
            decay_rate = 1,
            max = 30,
        },
    },

    -- Reactions
    reactions = {
        player_enters = {
            action = "evaluate",
            fear_delta = 25,
            message = "The spider tenses, front legs raised. The web trembles.",
        },
        player_attacks = {
            action = "flee",
            fear_delta = 80,
            message = "The spider drops from its web and skitters into a crack in the wall!",
        },
        loud_noise = {
            action = "flee",
            fear_delta = 40,
            message = "The web shudders. The spider scrambles toward the wall.",
        },
        light_change = {
            action = "evaluate",
            fear_delta = 15,
            message = "The spider draws its legs inward, shrinking against the web.",
        },
    },

    -- Movement
    movement = {
        speed = 2,
        can_open_doors = false,
        can_climb = true,
        size_limit = 1,
    },

    -- Awareness
    awareness = {
        sight_range = 1,
        sound_range = 1,
        smell_range = 1,
    },

    -- Health
    health = 3,
    max_health = 3,
    alive = true,

    -- Body zones (spider-specific anatomy — no human zones per #369/#337)
    body_tree = {
        cephalothorax = { size = 1, vital = true, tissue = { "chitin", "flesh" },
            names = { "cephalothorax", "head cluster", "fused head" } },
        abdomen       = { size = 1, vital = true, tissue = { "chitin", "flesh", "organ" },
            names = { "abdomen", "bulbous abdomen", "swollen belly" } },
        legs          = { size = 1, vital = false, tissue = { "chitin" }, on_damage = { "reduced_movement" },
            names = { "leg", "bristled leg", "spindly leg", "front leg" } },
    },

    -- Combat metadata
    combat = {
        size = "tiny",
        speed = 5,
        natural_weapons = {
            { id = "bite", type = "pierce", material = "tooth-enamel", zone = "cephalothorax", force = 1, message = "sinks its fangs into",
              on_hit = { inflict = "spider-venom", probability = 0.6 } },
        },
        natural_armor = {
            { material = "chitin", coverage = { "cephalothorax", "abdomen" }, thickness = 1 },
        },
        behavior = {
            aggression = "on_provoke",
            flee_threshold = 0.6,
            attack_pattern = "ambush",
            defense = "flee",
            target_priority = "closest",
            pack_size = 1,
        },
    },

    -- Loot table (WAVE-2)
    loot_table = {
        always = {
            { template = "silk-bundle" },
        },
        on_death = {
            { item = { template = "spider-fang" }, weight = 10 },
            { item = nil, weight = 90 },
        },
    },

    -- Respawn metadata (WAVE-5)
    respawn = {
        timer = 80,
        home_room = "deep-cellar",
        max_population = 2,
    },

    -- Death reshape (WAVE-1)
    death_state = {
        template = "small-item",
        name = "a dead spider",
        description = "A dead spider lies curled on its back, legs drawn inward like a clenched fist. Its web sags, abandoned.",
        keywords = {"dead spider", "spider corpse", "spider carcass", "dead arachnid", "spider"},
        room_presence = "A dead spider lies curled beneath a sagging web.",
        reshape_narration = "The spider's abdomen splits, spilling a tangle of silk.",

        -- Physical
        portable = true,
        size = "small",
        weight = 0.5,

        -- Sensory (on_feel mandatory — primary dark sense)
        on_feel = "Dry, brittle legs that crumble at the touch. A hard chitin shell, hollow-light.",
        on_smell = "A faint chemical bitterness. Dry chitin and musty silk.",
        on_listen = "Nothing. The web vibrates faintly in the air.",
        on_taste = "Dry shell and acrid venom. Your tongue goes numb.",

        -- Butchery products (Phase 4 WAVE-1)
        butchery_products = {
            requires_tool = "butchering",
            duration = "2 minutes",
            products = {
                { id = "spider-meat", quantity = 1 },
                { id = "silk-bundle", quantity = 1 },
            },
            narration = {
                start = "You carefully slice open the spider's abdomen, avoiding the venom sac...",
                complete = "You extract a small lump of pale meat and a wad of silk from the spider's body.",
            },
            removes_corpse = true,
        },
    },
}
