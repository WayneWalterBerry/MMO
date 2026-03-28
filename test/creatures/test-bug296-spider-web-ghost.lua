-- test/creatures/test-bug296-spider-web-ghost.lua
-- Bug #296: Spider web is a ghost object — visible in room description but not interactable.
-- TDD: write failing tests first, then fix.
-- Must be run from repository root: lua test/creatures/test-bug296-spider-web-ghost.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load definitions
---------------------------------------------------------------------------
local cellar_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "rooms" .. SEP .. "cellar.lua"
local ok_cellar, cellar = pcall(dofile, cellar_path)
if not ok_cellar then
    print("WARNING: cellar.lua not loadable — " .. tostring(cellar))
    cellar = nil
end

local web_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. "spider-web.lua"
local ok_web, spider_web = pcall(dofile, web_path)
if not ok_web then
    print("WARNING: spider-web.lua not loadable — " .. tostring(spider_web))
    spider_web = nil
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #296: Spider web must be a real interactable object in cellar")

test("1. cellar room has a spider-web instance", function()
    h.assert_truthy(cellar, "cellar.lua must load")
    h.assert_truthy(cellar.instances, "cellar must have instances")

    local found_web = false
    for _, inst in ipairs(cellar.instances) do
        if inst.id and inst.id:find("spider%-web") then
            found_web = true
            break
        end
        if inst.type and inst.type:find("[Ww]eb") then
            found_web = true
            break
        end
    end
    h.assert_truthy(found_web,
        "cellar instances must include a spider-web object for player interaction")
end)

test("2. spider-web object has full sensory properties", function()
    h.assert_truthy(spider_web, "spider-web.lua must load")
    h.assert_truthy(spider_web.on_feel, "spider-web must have on_feel (primary dark sense)")
    h.assert_truthy(spider_web.on_smell, "spider-web must have on_smell")
    h.assert_truthy(spider_web.on_listen, "spider-web must have on_listen")
    h.assert_truthy(spider_web.on_taste, "spider-web must have on_taste")
    h.assert_truthy(spider_web.keywords, "spider-web must have keywords")

    -- Keywords should include 'web' so player can 'examine web'
    local has_web_kw = false
    for _, kw in ipairs(spider_web.keywords) do
        if kw:find("web") then has_web_kw = true; break end
    end
    h.assert_truthy(has_web_kw, "spider-web keywords must include 'web'")
end)

test("3. spider-web has room_presence for display in room description", function()
    h.assert_truthy(spider_web, "spider-web.lua must load")
    h.assert_truthy(spider_web.room_presence, "spider-web must have room_presence")
    h.assert_truthy(spider_web.room_presence:find("[Ww]eb") or spider_web.room_presence:find("[Ss]ilk"),
        "room_presence must mention web or silk")
end)

test("4. cellar spider-web instance references correct type_id", function()
    h.assert_truthy(cellar, "cellar.lua must load")
    h.assert_truthy(spider_web, "spider-web.lua must load")

    local web_guid = spider_web.guid
    h.assert_truthy(web_guid, "spider-web must have a guid")

    local found = false
    for _, inst in ipairs(cellar.instances) do
        if inst.id and inst.id:find("spider%-web") then
            if inst.type_id then
                -- type_id should reference spider-web guid
                local norm_type = inst.type_id:gsub("[{}]", "")
                local norm_guid = web_guid:gsub("[{}]", "")
                if norm_type == norm_guid then
                    found = true
                end
            end
            break
        end
    end
    h.assert_truthy(found,
        "cellar spider-web instance must reference spider-web.lua guid as type_id")
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
