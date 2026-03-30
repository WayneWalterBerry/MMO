-- test/worlds/test-wyatt-reading.lua
-- WAVE-2b: Reading level audit for Wyatt's World.
-- Checks sentence length, vocabulary complexity, and active voice.

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")

local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

local WYATT_ROOT  = "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "wyatt-world"
local OBJECTS_DIR = WYATT_ROOT .. SEP .. "objects"
local ROOMS_DIR   = WYATT_ROOT .. SEP .. "rooms"

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function load_lua(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local src = f:read("*a")
    f:close()
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loadstring(src)
    else
        chunk, err = load(src)
    end
    if not chunk then return nil end
    local ok, result = pcall(chunk)
    if not ok then return nil end
    return result
end

local function list_lua_files(dir)
    local files = {}
    local cmd
    if is_windows then
        cmd = 'dir /b "' .. dir .. '\\*.lua" 2>nul'
    else
        cmd = 'ls "' .. dir .. '"/*.lua 2>/dev/null'
    end
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            local fname = line:match("^%s*(.-)%s*$")
            if fname and fname ~= "" then
                files[#files + 1] = fname
            end
        end
        handle:close()
    end
    return files
end

-- Split text into sentences (on . ! ? followed by space or end)
local function split_sentences(text)
    if not text then return {} end
    local sentences = {}
    -- Normalize: strip leading/trailing whitespace
    text = text:match("^%s*(.-)%s*$") or text
    -- Split on sentence-ending punctuation followed by space or end
    for sentence in text:gmatch("[^%.!?]+[%.!?]*") do
        sentence = sentence:match("^%s*(.-)%s*$")
        if sentence and #sentence > 0 then
            sentences[#sentences + 1] = sentence
        end
    end
    return sentences
end

-- Count words in a string
local function word_count(text)
    if not text then return 0 end
    local count = 0
    for _ in text:gmatch("%S+") do
        count = count + 1
    end
    return count
end

-- Words typically above 3rd grade level (not exhaustive, but catches common
-- offenders in game text). Excludes proper nouns and game terms.
local complex_words = {
    "subsequently", "nevertheless", "approximately", "circumstances",
    "consequently", "extraordinary", "unfortunately", "simultaneously",
    "predominantly", "sophisticated", "comprehensive", "miscellaneous",
    "indistinguishable", "metamorphosis", "claustrophobic", "catastrophe",
    "conundrum", "labyrinthine", "inexplicable", "juxtaposition",
    "nomenclature", "quintessential", "surreptitious", "ubiquitous",
    "discombobulated", "perpendicular", "circumference",
    "onomatopoeia", "antidisestablishmentarianism",
    "uncharacteristically", "disproportionate",
}

-- Passive voice indicators (simplified: "was/were/is/are + past participle")
local passive_indicators = {
    "was %w+ed ", "were %w+ed ", "is %w+ed ", "are %w+ed ",
    "was %w+en ", "were %w+en ", "is %w+en ", "are %w+en ",
    "was being ", "were being ", "has been ", "have been ",
}

-- Stative/adjectival uses that are NOT true passive voice
-- (e.g., "shelves are loaded with" = adjective, not process)
local stative_allowlist = {
    "are loaded", "are scattered", "are piled", "is powered",
    "is locked", "is filled", "are filled", "is covered",
    "are covered", "is painted", "are painted",
}

local function has_passive_voice(text)
    if not text then return false end
    local lower = text:lower()
    for _, pattern in ipairs(passive_indicators) do
        if lower:find(pattern) then
            -- Check against stative allowlist
            local allowed = false
            for _, stative in ipairs(stative_allowlist) do
                if lower:find(stative, 1, true) then
                    allowed = true
                    break
                end
            end
            if not allowed then return true end
        end
    end
    return false
end

-----------------------------------------------------------------------
-- Load all descriptions
-----------------------------------------------------------------------

local function collect_descriptions(dir)
    local descs = {}
    local fnames = list_lua_files(dir)
    for _, fname in ipairs(fnames) do
        local o = load_lua(dir .. SEP .. fname)
        if o then
            if o.description then
                descs[#descs + 1] = {
                    file = fname, field = "description", text = o.description
                }
            end
            if o.short_description then
                descs[#descs + 1] = {
                    file = fname, field = "short_description",
                    text = o.short_description,
                }
            end
        end
    end
    return descs
end

local room_descs = collect_descriptions(ROOMS_DIR)
local object_descs = collect_descriptions(OBJECTS_DIR)

-----------------------------------------------------------------------
-- Suite 1: no sentence exceeds 15 words (room descriptions)
-----------------------------------------------------------------------
t.suite("reading — room sentence length")

t.test("room descriptions loaded", function()
    t.assert_truthy(#room_descs > 0,
        "should have room descriptions to check (got " .. #room_descs .. ")")
end)

t.test("no room description sentence exceeds 15 words", function()
    local violations = {}
    for _, d in ipairs(room_descs) do
        local sentences = split_sentences(d.text)
        for _, s in ipairs(sentences) do
            local wc = word_count(s)
            if wc > 15 then
                violations[#violations + 1] = d.file .. " ("
                    .. wc .. " words): " .. s:sub(1, 60) .. "..."
            end
        end
    end
    if #violations > 0 then
        error("sentences exceeding 15 words:\n  "
            .. table.concat(violations, "\n  "))
    end
end)

-----------------------------------------------------------------------
-- Suite 2: no complex vocabulary in descriptions
-----------------------------------------------------------------------
t.suite("reading — vocabulary complexity")

t.test("no room descriptions use complex words", function()
    local bad = nil
    for _, d in ipairs(room_descs) do
        local lower = d.text:lower()
        for _, word in ipairs(complex_words) do
            if lower:find(word, 1, true) then
                bad = d.file .. ": found '" .. word .. "'"
                break
            end
        end
        if bad then break end
    end
    t.assert_nil(bad,
        "room with complex vocabulary: " .. tostring(bad))
end)

t.test("no object descriptions use complex words", function()
    local bad = nil
    for _, d in ipairs(object_descs) do
        local lower = d.text:lower()
        for _, word in ipairs(complex_words) do
            if lower:find(word, 1, true) then
                bad = d.file .. ": found '" .. word .. "'"
                break
            end
        end
        if bad then break end
    end
    t.assert_nil(bad,
        "object with complex vocabulary: " .. tostring(bad))
end)

-----------------------------------------------------------------------
-- Suite 3: active voice in room descriptions
-----------------------------------------------------------------------
t.suite("reading — active voice")

t.test("room descriptions use active voice", function()
    local passive_found = {}
    for _, d in ipairs(room_descs) do
        if has_passive_voice(d.text) then
            passive_found[#passive_found + 1] = d.file
        end
    end
    if #passive_found > 0 then
        error("passive voice detected in room descriptions: "
            .. table.concat(passive_found, ", "))
    end
end)

-----------------------------------------------------------------------
-- Suite 4: object description sentence length (bonus coverage)
-----------------------------------------------------------------------
t.suite("reading — object sentence length")

t.test("object descriptions loaded", function()
    t.assert_truthy(#object_descs > 0,
        "should have object descriptions (got " .. #object_descs .. ")")
end)

t.test("no object description sentence exceeds 25 words", function()
    -- Lenient for objects: they include quoted in-game text that inflates
    -- word count (e.g., scoreboard shows "WYATT" and "Challenges Done: 0/6")
    local violations = {}
    for _, d in ipairs(object_descs) do
        local sentences = split_sentences(d.text)
        for _, s in ipairs(sentences) do
            local wc = word_count(s)
            if wc > 25 then
                violations[#violations + 1] = d.file .. " ("
                    .. wc .. " words): " .. s:sub(1, 60) .. "..."
            end
        end
    end
    if #violations > 0 then
        error("object sentences exceeding 25 words:\n  "
            .. table.concat(violations, "\n  "))
    end
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
