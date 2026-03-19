-- engine/parser/json.lua
-- Minimal JSON decoder for loading the embedding index.
-- Supports: objects, arrays, strings, numbers, booleans, null.
-- Not a general-purpose JSON library -- just enough for our index format.

local json = {}

local function skip_ws(s, i)
  return s:match("^%s*()", i)
end

local function decode_string(s, i)
  -- i points at the opening "
  assert(s:sub(i, i) == '"', "expected '\"' at position " .. i)
  local j = i + 1
  local parts = {}
  while j <= #s do
    local c = s:sub(j, j)
    if c == '"' then
      return table.concat(parts), j + 1
    elseif c == '\\' then
      j = j + 1
      local esc = s:sub(j, j)
      if esc == '"' or esc == '\\' or esc == '/' then
        parts[#parts + 1] = esc
      elseif esc == 'n' then parts[#parts + 1] = '\n'
      elseif esc == 'r' then parts[#parts + 1] = '\r'
      elseif esc == 't' then parts[#parts + 1] = '\t'
      elseif esc == 'b' then parts[#parts + 1] = '\b'
      elseif esc == 'f' then parts[#parts + 1] = '\f'
      elseif esc == 'u' then
        -- Basic \uXXXX -- just pass through as-is for ASCII range
        local hex = s:sub(j + 1, j + 4)
        local cp = tonumber(hex, 16)
        if cp and cp < 128 then
          parts[#parts + 1] = string.char(cp)
        else
          parts[#parts + 1] = "?" -- non-ASCII placeholder
        end
        j = j + 4
      end
    else
      parts[#parts + 1] = c
    end
    j = j + 1
  end
  error("unterminated string at position " .. i)
end

local decode_value -- forward declaration

local function decode_array(s, i)
  -- i points at [
  i = skip_ws(s, i + 1)
  local arr = {}
  if s:sub(i, i) == ']' then return arr, i + 1 end
  while true do
    local val
    val, i = decode_value(s, i)
    arr[#arr + 1] = val
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == ']' then return arr, i + 1 end
    assert(c == ',', "expected ',' or ']' at position " .. i)
    i = skip_ws(s, i + 1)
  end
end

local function decode_object(s, i)
  -- i points at {
  i = skip_ws(s, i + 1)
  local obj = {}
  if s:sub(i, i) == '}' then return obj, i + 1 end
  while true do
    local key
    key, i = decode_string(s, i)
    i = skip_ws(s, i)
    assert(s:sub(i, i) == ':', "expected ':' at position " .. i)
    i = skip_ws(s, i + 1)
    local val
    val, i = decode_value(s, i)
    obj[key] = val
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == '}' then return obj, i + 1 end
    assert(c == ',', "expected ',' or '}' at position " .. i)
    i = skip_ws(s, i + 1)
  end
end

decode_value = function(s, i)
  i = skip_ws(s, i)
  local c = s:sub(i, i)
  if c == '"' then return decode_string(s, i)
  elseif c == '{' then return decode_object(s, i)
  elseif c == '[' then return decode_array(s, i)
  elseif c == 't' then
    assert(s:sub(i, i + 3) == 'true')
    return true, i + 4
  elseif c == 'f' then
    assert(s:sub(i, i + 4) == 'false')
    return false, i + 5
  elseif c == 'n' then
    assert(s:sub(i, i + 3) == 'null')
    return nil, i + 4
  else
    -- number
    local num_str = s:match("^-?%d+%.?%d*[eE]?[%+%-]?%d*", i)
    assert(num_str, "unexpected character at position " .. i .. ": '" .. c .. "'")
    return tonumber(num_str), i + #num_str
  end
end

function json.decode(s)
  local val, _ = decode_value(s, 1)
  return val
end

return json
