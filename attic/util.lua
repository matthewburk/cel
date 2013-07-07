--[[
cel is licensed under the terms of the MIT license

Copyright (C) 2011 by Matthew W. Burk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]
local M = {} 

function M.readonly(t, proxy)
  local mt = {
    __index = t,
    __newindex = function(t, k, v)
      error('attempt to update a read-only table', 2)
    end
  }
  setmetatable(proxy, mt)
  return proxy
end

function M.memo__index(source, onhit, onmiss)
  return function(t, key)
    local v = source[key]
    if v then
      t[key] = v
      if onhit then onhit(key, v) end
    else
      if onmiss then onmiss(key, v) end
    end
    return v
  end
end
  
do --match
  local t = {
    function(v, a)
      if v == a then return 1, a end
    end,
    function(v, a, b)
      if v == a then return 1, a end
      if v == b then return 2, b end
    end,
    function(v, a, b, c)
      if v == a then return 1, a end
      if v == b then return 2, b end
      if v == c then return 3, c end
    end,
    function(v, a, b, c, d)
      if v == a then return 1, a end
      if v == b then return 2, b end
      if v == c then return 3, c end
      if v == d then return 4, d end
    end,
  }

  local function matchmany(checks, count, v, a, b, c, d, ...)
    if count <= 4 then
      local i, match = t[count](v, a, b, c, d)
      i = i and i + checks
    end

    if v == a then return checks + 1, a end
    if v == b then return checks + 2, b end
    if v == c then return checks + 3, c end
    if v == d then return checks + 4, d end
    return matchmany(checks + 4, count - 4, v, ...) 
  end 

  function M.match(v, ...)
    local argc = select('#', ...)
    if argc > 4 then 
      return matchmany(0, argc, v, ...) 
    else
      return t[argc](v, ...)
    end
  end
end

function M.clamp(v, a, b)
  a = a or v
  b = b or v
  if v <= a then return a end
  if v >= b then return b end
  return v
end

M.string = {}

-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function M.string.trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- remove leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function M.string.ltrim(s)
  return (s:gsub("^%s*", ""))
end

-- remove trailing whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function M.string.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

function M.string.split(self, sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

function M.string.mergewhitespace(s)
  local lines = M.string.split(s, '\n')
  local trim = M.string.trim
  for i = 1, #lines do
    lines[i] = trim(lines[i])
  end
  
  return table.concat(lines, '\n')
end

--from compat-5.1 source
--path used to find file it package.path
function M.findfile(name)
	name = string.gsub(name, '%.', '/')
	local path = package.path

	for c in string.gmatch(path, "[^;]+") do
		c = string.gsub(c, '%?', name)
		local f = io.open (c)
		if f then
			f:close ()
			return c
		end
	end

	return nil
end

function M.loadfilein(_ENV, name)
  local filename = M.findfile(name)
	if not filename then
		return false
	end
	local f, err = loadfile(filename)
	if not f then
		error (string.format("error loading file `%s' (%s)", name, err))
	end
  return setfenv(f, _ENV)
end

function M.normalize_padding(padding, w, h, ...)
  if not padding then
    return 0, 0, 0, 0, ...
  end

  w = w or 0
  h = h or 0

  local l = padding.l or 0
  local t = padding.t or 0
  if type(l) == 'function' then l = math.floor(l(w, h) + .5) end
  if type(t) == 'function' then t = math.floor(t(w, h) + .5) end
  local r = padding.r or l
  local b = padding.b or t
  if type(r) == 'function' then r = math.floor(r(w, h) + .5) end
  if type(b) == 'function' then b = math.floor(b(w, h) + .5) end
  return l, t, r, b, ...
end

return M

