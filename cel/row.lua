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

local rowmetacel, rowmt = cel.sequence.x.newmetacel('row')
local slotmetacel = cel.slot.newmetacel('row.slot')

local _flex = {}
local _minw = {}
local _row = {}
local _gap = {}
local _nslots = {}
local _notified = {}
local _layout = {}

local row_items = rowmt.ilinks
local row_get = rowmt.get

rowmt.next = nil
rowmt.prev = nil
rowmt.indexof = nil

local layout = {
  slot = {
    face = nil
  }
}

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
  
  function rowmt.items(row)
    local iter, state, i = row_items(row)
    return filter(iter), state, i 
  end
end

function rowmt.get(row, i)
  local slot = row_get(row, i)
  if slot and slot[_flex] then
    return slot:get()
  end
  return slot
end

do
  local _setlimits = slotmetacel.setlimits
  function slotmetacel:setlimits(slot, minw, maxw, minh, maxh) 
    --only record changes, initial minw is picked up in __link
    if slot[_minw] then
      local row = slot[_row]
      row[_minw] = row[_minw] - slot[_minw] + minw
      slot[_minw] = minw
    end
    return _setlimits(self, slot, minw, maxw, minh, maxh)
  end
end

do
  local _setlimits = rowmetacel.setlimits
  function rowmetacel:setlimits(row, minw, maxw, minh, maxh)
    _setlimits(self, row, row[_minw], nil, minh, maxh)
    if minw > row[_minw] then
      row:resize(minw)
    end
  end
end

local function allocateslots(row, w)
  if row[_flex] <= 0 then return end

  local excess = w-(row.minw or 0)

  if excess > 0 then
    local extra = excess % row[_flex]
    local mult = math.floor((excess)/row[_flex])

    for i, slot in row_items(row) do
      local flex = slot[_flex]

      if flex then
        local w = slot.minw + (flex * mult)

        if extra > 0 then
          w = w + math.min(flex, extra)
          extra = extra - flex
        end

        slot:resize(w)
      end
    end
  else
    for i, slot in row_items(row) do
      slot:resize(slot.minw)
    end
  end
end

local function slotoption() end
local defaultoption = {minw=0, flex=0}
function rowmetacel:__link(row, link, linker, xval, yval, option)
  if option == slotoption then
    link[_minw] = link.minw
    
    if row[_nslots] > 0 then
      row[_minw] = row[_minw] + link[_minw] + row[_gap]
    else
      row[_minw] = row[_minw] + link[_minw]
    end

    row[_nslots] = row[_nslots] + 1

    if not row[_notified] then
      self:asyncall('reconcile', row)
      row[_notified] = true
    end
  else
    if type(option) ~= 'table' then
      option = defaultoption
    end

    local minw, flex, face = option.minw or 0, option.flex or 0, option.face or row[_layout].slot.face 
    local minh = option.minh or nil 

    row[_flex] = row[_flex] + flex

    local slot = slotmetacel:new(0, 0, 0, 0, minw, minh, face)
    slot[_flex] = flex
    slot[_row] = row

    slot:link(row, 'height', nil, nil, slotoption)

    if not (linker or xval or yval) then
      return slot--, 'edges'
    end

    return slot, linker, xval, yval
  end
end

function rowmetacel:reconcile(row)
  row[_notified] = false
  row:flux(allocateslots, row, row.w)
end

function rowmetacel:__resize(row, ow, oh)
  if row[_flex] > 0 and row.w ~= ow then
    if not row[_notified] then
      self:asyncall('reconcile', row)
      row[_notified] = true
    end
  end
end

do
  local _new = rowmetacel.new
  function rowmetacel:new(gap, face) --TODO don't need to define this, just let it pass to slot
    face = self:getface(face)
    local row = _new(self, gap, face)
    row[_flex] = 0
    row[_minw] = 0
    row[_gap] = gap or 0
    row[_nslots] = 0
    row[_layout] = face.layout or layout
    return row
  end

  local _compile = rowmetacel.compile
  function rowmetacel:compile(t, row)
    return _compile(self, t, row or rowmetacel:new(t.gap, t.face))
  end

  function rowmetacel:compileentry(row, entry, entrytype)
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
        local link = cel.tocel(entry[i], row)
        if link then
          if not entry.link then
            linker, xval, yval = link:pget('linker', 'xval', 'yval')
          end
          if not (linker or xval or yval) then
           --linker = 'edges'
          end
          link:link(row, linker, xval, yval, entry)
        end
      end 
    end
  end
end

return rowmetacel:newfactory()


