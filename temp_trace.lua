package.path = "src/?.lua;src/?/init.lua;" .. package.path
local pp = require("engine.parser.preprocess")
pp.debug = true

local cases = {
  "what's this?",
  "what do I do?",
  "what now?",
  "would you mind examining the nightstand",
  "I'd like to know what's in the drawer",
  "have a look around",
  "where is the matchbox?",
  "search for matches",
}

for _, c in ipairs(cases) do
  print("--- INPUT: " .. c .. " ---")
  local v, n = pp.natural_language(c)
  print("  RESULT: verb=" .. tostring(v) .. " noun=" .. tostring(n))
  print()
end
