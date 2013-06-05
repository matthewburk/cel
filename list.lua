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

local metacel = cel.col.newmetacel('list')

local _selected = {}
local _current = {}
local _changes = {}

local layout = {
  gap = 0,
  slotface = nil,
  currentslotface = nil,  
  selectedslotface = nil,
  selectedcurrentslotface = nil,
}

do
  local function it(list, i)
    i = i + 1
    local item = list:get(i)
    if item then return i, item end
  end

  function metacel.metatable:items(subset)
    if subset == 'selected' then
      if not self[_selected] then
        return pairs(dummy)
      end

      return selectedit, self
    end
    return it, self, 0
  end

  local function selectedit(list, prev)
    return (next(list[_selected], prev)) --TODO need an index
  end

  local dummy = {}
  function metacel.metatable:selecteditems(subset)
    if not self[_selected] then
      return pairs(dummy)
    end
    return selectedit, self
  end
end

--returns the item that was most recently picked(by the user)
function metacel.metatable:getcurrent()
  return self[_current]
end

local function changecurrent(list, item)
  local layout = list.face.layout or layout

  local current = list[_current]

  if current then
    if list[_selected] and list[_selected][current] then
      list:setslotface(current, layout.selectedslotface)
    else
      list:setslotface(current, layout.slotface)
    end
  end
  list[_current] = item

  if item then
    if list[_selected] and list[_selected][item] then
      list:setslotface(item, layout.selectedcurrentslotface or layout.currentslotface)
    else
      list:setslotface(item, layout.currentslotface)
    end
  end
  return list:refresh()
end

function metacel.metatable:setcurrent(item)
  if type(item) == 'number' then
    item = self:get(item)
  end
  if item then
    changecurrent(self, item)
  end
  return self
end

--TODO optimize this could be done outside the module with same efficiency
function metacel.metatable:selectall(mode)
  for i = 1, self:len() do
    self:select(i, mode)
  end
  return self
end

function metacel.metatable:select(itemorindex, mode)
  local item
  local index 

  if type(itemorindex) == 'number' then
    item = self:get(itemorindex)
    index = itemorindex
  else
    item = itemorindex
    index = self:indexof(item)
  end

  if not item then
    return self
  end

  self[_selected] = self[_selected] or {}

  local selected = self[_selected]

  local op
  if mode == true or mode == nil then
    if selected[item] then return self end
    op = 'select' 
  elseif mode == false then
    if not selected[item] then return self end
    op = 'unselect'  
  elseif mode == 'toggle' then
    if selected[item] then
      op = 'unselect'  
    else
      op = 'select' 
    end 
  end

  if op == 'select' then
    local layout = self.face.layout or layout
    selected[item] = true

    if self[_current] == item then
      self:setslotface(item, layout.selectedcurrentslotface or layout.currentslotface)
    else
      self:setslotface(item, layout.selectedslotface)
    end
  elseif op == 'unselect' then
    selected[item] = nil
    if index then
      if self[_current] == item then
        self:setslotface(item, layout.currentslotface)
      else
        self:setslotface(item, layout.slotface)
      end
    end
  end

  if index and self.onchange then
    return self:onchange(item, index, selected[item] and 'selected' or 'unselected')
  end

  return self:refresh()
end

do --metacel.dispatchevents
  function metacel:dispatchevents(list)
    local changes = list[_changes]
    list[_changes] = nil

    for i=1, #changes do
      local item, index, value, sink = changes[i][1], changes[i][2], changes[i][3], changes[i][4]
      if false == value then
        if list[_selected] and list[_selected][item] then
          list:select(item, false)
        end
        if list[_current] == item then
          changecurrent(list, nil)
        end
      end

      if sink then
        sink(list, item, index, value)
      end
    end
  end
end

do
  local function __qchange(metacel, list, link, index, value, sink)
    local changes = list[_changes]
    if changes then
      changes[#changes+1] = {link, index, value, sink}
    else
      list[_changes] = {{link, index, value, sink}}
      metacel:asyncall('dispatchevents', list)
    end
  end

  do --metacel.__link
    function metacel:__link(list, item, linker, xval, yval)
      if list.onchange then
        __qchange(self, list, item, list:len(), true, list.onchange)
      end
    end
  end

  do --metacel.__unlink
    function metacel:__unlink(list, item, index)
      if list.onchange then
        __qchange(self, list, item, index, false, list.onchange)
      else
        if list[_selected] and list[_selected][item] then
          __qchange(self, list, item, index, false, nil)
        elseif list[_current] == item then
          __qchange(self, list, item, index, false, nil)
        end
      end
    end
  end
end

function metacel:touch(cel, x, y)
  return true
end

do
  local _new = metacel.new

  function metacel:new(face)
    face = self:getface(face)
    local layout = face.layout or layout
    local list = _new(self, layout.gap or 0, face, layout.slotface)
    return list
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, list)
    list = list or metacel:new(t.face)
    list.onchange = t.onchange
    _assemble(self, t, list)
    return list
  end
end

return metacel:newfactory()

