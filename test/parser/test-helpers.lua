-- test/parser/test-helpers.lua
-- Minimal pure-Lua test framework for MMO parser unit tests.
-- No external dependencies. Pattern: test(name, fn) + assert helpers.

local helpers = {}

local passed = 0
local failed = 0
local errors = {}

function helpers.test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("  PASS " .. name)
        passed = passed + 1
    else
        print("  FAIL " .. name .. ": " .. tostring(err))
        failed = failed + 1
        errors[#errors + 1] = { name = name, err = tostring(err) }
    end
end

function helpers.assert_eq(expected, actual, msg)
    if expected ~= actual then
        error((msg and (msg .. " — ") or "") ..
              "expected: " .. tostring(expected) ..
              " got: " .. tostring(actual))
    end
end

function helpers.assert_truthy(val, msg)
    if not val then
        error((msg or "expected truthy value") .. " — got: " .. tostring(val))
    end
end

function helpers.assert_nil(val, msg)
    if val ~= nil then
        error((msg or "expected nil") .. " — got: " .. tostring(val))
    end
end

function helpers.assert_no_error(fn, msg)
    local ok, err = pcall(fn)
    if not ok then
        error((msg or "expected no error") .. " — got: " .. tostring(err))
    end
end

function helpers.suite(name)
    print("\n=== " .. name .. " ===")
end

function helpers.summary()
    print("\n--- Results ---")
    print("  Passed: " .. passed)
    print("  Failed: " .. failed)
    if #errors > 0 then
        print("\nFailures:")
        for _, e in ipairs(errors) do
            print("  - " .. e.name .. ": " .. e.err)
        end
    end
    return failed
end

function helpers.reset()
    passed = 0
    failed = 0
    errors = {}
end

return helpers
