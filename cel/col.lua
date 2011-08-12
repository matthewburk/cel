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

local _flex = {}
local _col = {}
local _minh = {}
local _nslots = {}
local _gap = {}
local _notified = {}
local _layout = {}

local col_items = colmt.ilinks
local col_get = colmt.get

colmt.next = nil
colmt.prev = nil
colmt.indexof = nil

local layout = {
  slot = {
    face = nil
  }
}

function slotmetacel:__fitsubject(slot, w, h)
  return w, slot.fixedheight
end

do
  local memo = setmetatable({}, {__mode = "kv"})
  
  local function filter(iter)
    local filter = memo[iter] 
    if not filter then
      filter = function(...)
        local i, slot = iter(...)
        if slot and slot[_flex] then
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
  if slot and slot[_flex] then
    return slot:get()
  end
  return slot
end

do
  local _setlimits = slotmetacel.setlimits
  function slotmetacel:setlimits(slot, minw, maxw, minh, maxh) 
    --only record changes, initial minh is picked up in __link
    if slot[_minh] then
      local col = slot[_col]
      col[_minh] = col[_minh] - slot[_minh] + minh
      slot[_minh] = minh
    end
    if minh and minh > slot.fixedheight then
      slot.fixedheight = minh
    end
    return _setlimits(self, slot, minw, maxw, minh, maxh)
  end
end

do
  local _setlimits = colmetacel.setlimits
  function colmetacel:setlimits(col, minw, maxw, minh, maxh)
    return _setlimits(self, col, minw, maxw, col[_minh], nil)
  end
end

local function allocateslots(col, h)
  if col[_flex] <= 0 then return end

  local excess = h-(col.minh or 0)

  if excess > 0 then
    local extra = excess % col[_flex]
    local mult = math.floor((excess)/col[_flex])

    for i, slot in col_items(col) do
      local flex = slot[_flex]

      if flex then
        local h = slot.minh + (flex * mult)

        if extra > 0 then
          h = h + math.min(flex, extra)
          extra = extra - flex
        end

        slot.fixedheight = h
        slot:resize(nil, h)
      end
    end
  else
    for i, slot in col_items(col) do
      slot.fixedheight = slot.minh
      slot:resize(nil, slot.minh)
    end
  end
end

local function slotlayout(minh, flex)
  return function()
    return minh, flex
  end
end

function colmetacel:__link(col, link, linker, xval, yval, option)
  if type(option) == 'table' then
    local minh, flex, face = option.minh or 0, option.flex or 0, option.face or col[_layout].slot.face  

    col[_flex] = col[_flex] + flex

    local slot = slotmetacel:new(0, 0, 0, 0, 0, minh, face)
    slot[_flex] = flex
    slot[_col] = col
    slot.fixedheight = minh

    slot:link(col, 'width')

    return slot, linker, xval, yval
  else
    link[_minh] = link.minh
    
    if col[_nslots] > 0 then
      col[_minh] = col[_minh] + link[_minh] + col[_gap]
    else
      col[_minh] = col[_minh] + link[_minh]
    end

    col[_nslots] = col[_nslots] + 1

    if not col[_notified] then
      self:asyncall('reconcile', col)
      col[_notified] = true
    end
  end
end

function colmetacel:reconcile(col)
  col[_notified] = false
  col:flux(allocateslots, col, col.h)
end

function colmetacel:__resize(col, ow, oh)
  if col[_flex] > 0 and col.h ~= oh then
    if not col[_notified] then
      self:asyncall('reconcile', col)
      col[_notified] = true
    end
  end
end

do
  local _new = colmetacel.new
  function colmetacel:new(gap, face) --TODO don't need to define this, just let it pass to slot
    face = self:getface(face)
    local col = _new(self, gap, face)
    col[_flex] = 0
    col[_minh] = 0
    col[_gap] = gap or 0
    col[_nslots] = 0
    col[_layout] = face.layout or layout
    return col
  end

  local _compile = colmetacel.compile
  function colmetacel:compile(t, col)
    return _compile(self, t, col or colmetacel:new(t.gap, t.face))
  end

  function colmetacel:compileentry(col, entry, entrytype)
    if 'table' == entrytype then
      local linker, xval, yval

      if entry.link then
        if type(entry.link) == 'table' then
          linker, xval, yval = unpack(entry.link, 1, 3)
        else
          linker = entry.link
        end
      end

      for i = 1, #entry do
        local link = cel.tocel(entry[i], col)
        if link then
          if not entry.link then
            linker, xval, yval = link:pget('linker', 'xval', 'yval')
          end
          link:link(col, linker, xval, yval, entry)
        end
      end 
    end
  end
end

return colmetacel:newfactory()


