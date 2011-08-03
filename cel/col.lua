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
local cel = require 'cel'

local colmetacel, colmt = cel.sequence.y.newmetacel('col')
local slotmetacel = cel.slot.newmetacel('col.slot')

local _weight = {}
local _minh = {}
local _col = {}

local col_items = colmt.links
local col_get = colmt.get

colmt.next = nil
colmt.prev = nil
colmt.indexof = nil

do
  local memo = setmetatable({}, {__mode = "kv"})
  
  local function filter(iter)
    local filter = memo[iter] 
    if not filter then
      filter = function(...)
        local i, slot = iter(...)
        if slot and slot[_weight] then
          return i, slot:get() 
        else
          return i, slot
        end
      end
      memo[iter] = filter
    end
    return filter
  end
  
  function colmt.items(col)
    local iter, state, i = col_items(col)
    return filter(iter), state, i 
  end
end

function colmt.get(col, i)
  local slot = col_get(col, i)
  if slot and slot[_weight] then
    return slot:get()
  end
  return slot
end

do
  local _setlimits = slotmetacel.setlimits
  function slotmetacel:setlimits(slot, minw, maxw, minh, maxh) 
    slot[_col][_minh] = slot[_col][_minh] - slot.minh + math.max(minh, slot[_minh])
    return _setlimits(self, slot, minw, maxw, math.max(minh, slot[_minh]), maxh)
  end
end

do
  local _setlimits = colmetacel.setlimits
  function colmetacel:setlimits(col, minw, maxw, minh, maxh)
    minh = col[_minh]
    return _setlimits(self, col, minw, maxw, minh, nil)
  end
end

local function allocateslots(col, h)
  if col[_weight] <= 0 then return end

  local excess = h-(col.minh or 0)

  if excess > 0 then
    local extra = excess % col[_weight]
    local mult = math.floor((excess)/col[_weight])

    for i, slot in col_items(col) do
      local weight = slot[_weight]

      if weight then
        local h = slot.minh + (weight * mult)

        if extra > 0 then
          h = h + math.min(weight, extra)
          extra = extra - weight
        end

        slot:resize(nil, h)
      end
    end
  end
end

local function slotlayout(minh, weight)
  return function()
    return minh, weight
  end
end

function colmetacel:__link(col, link, linker, xval, yval, option)
  if type(option) == 'function' then
    local minh, weight = option()

    col[_weight] = col[_weight] + weight

    local slot = slotmetacel:new()
    slot[_minh] = minh
    slot[_weight] = weight
    slot[_col] = col

    slotmetacel:setlimits(slot, slot:pget('minw', 'maxw', 'minh', 'maxh'))

    slot:link(col, 'width')

    return slot, linker, xval, yval
  elseif not link[_weight] then
    col[_minh] = col[_minh] + link.h
  end
end

function colmetacel:__linkmove(col, link, ox, oy, ow, oh)
  if link.h ~= oh and not link[_weight] then
    col[_minh] = col[_minh] - oh + link.h
  end
end

function colmetacel:__resize(col, ow, oh)
  if col[_weight] > 0 and col.h ~= oh then
    col:flux(allocateslots, col, col.h)
  end
end

do
  local _new = colmetacel.new
  function colmetacel:new(face) --TODO don't need to define this, just let it pass to slot
    local col = _new(self, 0, self:getface(face))
    col[_weight] = 0
    col[_minh] = 0
    return col
  end

  local _compile = colmetacel.compile
  function colmetacel:compile(t, col)
    return _compile(self, t, col or colmetacel:new(t.face))
  end

  local _up = colmetacel.compilelistentry
  function colmetacel:compileentry(col, entry, entrytype)
    if 'table' == entrytype then
      local link = cel.tocel(entry[1], col)
      if link then
        local minh = entry.minh or 0
        local weight = entry.weight or 0
        local linker, xval, yval, option

        if entry.link then
          if type(entry.link) == 'table' then
            linker, xval, yval = unpack(entry.link, 1, 3)
          else
            linker = entry.link
          end
        else
          linker, xval, yval = link:pget('linker', 'xval', 'yval')
        end

        link:link(col, linker, xval, yval, slotlayout(minh, weight))
      end
    end
  end
end

return colmetacel:newfactory()


