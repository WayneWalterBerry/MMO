-- engine/parser/preprocess/data.lua
-- Shared data tables for preprocess stages.

local data = {}

data.BODY_PARTS = {
    head = true, face = true, neck = true,
    arm = true, arms = true, leg = true, legs = true,
    hand = true, hands = true, foot = true, feet = true,
    shoulder = true, shoulders = true, waist = true, torso = true,
    stomach = true, belly = true, gut = true, chest = true, side = true,
}

data.GERUND_MAP = {
    examining = "examine", looking = "look", searching = "search",
    opening = "open", closing = "close", taking = "take",
    checking = "check", feeling = "feel", reading = "read",
    smelling = "smell", listening = "listen", breaking = "break",
    tasting = "taste", lighting = "light", dropping = "drop",
    wearing = "wear", climbing = "climb", moving = "move",
    pulling = "pull", pushing = "push", finding = "find",
    lifting = "lift", sliding = "slide", shoving = "shove",
    heaving = "heave", dragging = "drag", nudging = "nudge",
    getting = "get", giving = "give", hiding = "hide",
    picking = "pick", drinking = "drink", eating = "eat",
    using = "use", pouring = "pour", filling = "fill",
    applying = "apply", rubbing = "rub",
    washing = "wash", cleaning = "clean", rinsing = "rinse", scrubbing = "scrub",
}

data.IDIOM_TABLE = {
    { pattern = "^set%s+fire%s+to%s+(.+)$",        replacement = "light %1" },
    { pattern = "^put%s+down%s+(.+)$",              replacement = "drop %1" },
    -- #138: "put X down" → "drop X" (word order variant)
    { pattern = "^put%s+(.+)%s+down$",              replacement = "drop %1" },
    -- #140: "set X down" / "set down X" → "drop X"
    { pattern = "^set%s+down%s+(.+)$",              replacement = "drop %1" },
    { pattern = "^set%s+(.+)%s+down$",              replacement = "drop %1" },
    { pattern = "^blow%s+out%s+(.+)$",              replacement = "extinguish %1" },
    { pattern = "^have%s+a%s+look%s+at%s+(.+)$",    replacement = "examine %1" },
    { pattern = "^take%s+a%s+look%s+at%s+(.+)$",    replacement = "examine %1" },
    { pattern = "^take%s+a%s+peek%s+at%s+(.+)$",    replacement = "examine %1" },
    { pattern = "^have%s+a%s+look%s+around$",        replacement = "look" },
    { pattern = "^take%s+a%s+look%s+around$",        replacement = "look" },
    { pattern = "^have%s+a%s+look$",                replacement = "look" },
    { pattern = "^take%s+a%s+look$",                replacement = "look" },
    { pattern = "^take%s+a%s+peek$",                replacement = "look" },
    { pattern = "^get%s+rid%s+of%s+(.+)$",          replacement = "drop %1" },
    { pattern = "^make%s+use%s+of%s+(.+)$",         replacement = "use %1" },
    { pattern = "^go%s+to%s+sleep$",                replacement = "sleep" },
    { pattern = "^lay%s+down$",                     replacement = "sleep" },
    { pattern = "^lie%s+down$",                     replacement = "sleep" },
    -- #42: "sleep to/til/till dawn" → "sleep until dawn"
    { pattern = "^sleep%s+to%s+(.+)$",             replacement = "sleep until %1" },
    { pattern = "^sleep%s+til%s+(.+)$",            replacement = "sleep until %1" },
    { pattern = "^sleep%s+till%s+(.+)$",           replacement = "sleep until %1" },
}

data.HIT_SYNONYMS = { smack=true, bang=true, slap=true, whack=true }

data.KNOWN_VERBS = {
    -- sensory
    look = true, examine = true, x = true, inspect = true, check = true,
    feel = true, touch = true, grope = true, smell = true, sniff = true,
    taste = true, lick = true, listen = true, hear = true, read = true,
    search = true, find = true,
    -- acquisition
    take = true, get = true, pick = true, grab = true, drop = true,
    pull = true, yank = true, tug = true, extract = true,
    push = true, shove = true, nudge = true,
    move = true, shift = true, drag = true, slide = true,
    lift = true, heave = true, uncork = true, unstop = true, unseal = true,
    -- containers
    open = true, close = true, shut = true, pry = true,
    unlock = true, lock = true,
    -- equipment
    wear = true, don = true, remove = true, doff = true,
    -- crafting
    write = true, inscribe = true, sew = true, stitch = true, mend = true,
    put = true, place = true,
    -- combat
    stab = true, jab = true, pierce = true, stick = true,
    hit = true, punch = true, bash = true, bonk = true, thump = true,
    smack = true, bang = true, slap = true, whack = true, headbutt = true,
    toss = true, throw = true, cut = true, slice = true, nick = true,
    slash = true, carve = true, prick = true,
    -- destruction
    ["break"] = true, smash = true, shatter = true, tear = true, rip = true,
    -- fire
    light = true, ignite = true, relight = true,
    extinguish = true, snuff = true, strike = true, burn = true,
    -- survival
    eat = true, consume = true, devour = true,
    drink = true, quaff = true, sip = true,
    pour = true, spill = true, dump = true, fill = true,
    wash = true, clean = true, rinse = true, scrub = true,
    sleep = true, rest = true, nap = true,
    -- movement
    go = true, walk = true, run = true, head = true, travel = true,
    leave = true, exit = true,
    enter = true, climb = true, ascend = true, descend = true,
    back = true, ["return"] = true,
    north = true, south = true, east = true, west = true,
    up = true, down = true, n = true, s = true, e = true, w = true,
    -- meta
    inventory = true, i = true, time = true, set = true, adjust = true,
    help = true, wait = true, pass = true, use = true, utilize = true,
    apply = true, treat = true, appearance = true, quit = true,
}

return data
