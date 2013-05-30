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

local metacel, metatable = cel.scroll.newmetacel('listbox')
metacel['.list'] = cel.col.newmetacel('listbox.list')

local _listbox = {}
local _items = {}
local _selected = {}
local _current = {}
local _changes = {}

local layout = {
  gap = 0,
  list = {
    face = nil,  
    slotface = nil,
  }
}

function metatable:flux(...)
  self[_items]:flux(...)
  return self 
end

function metatable:len()
  return self[_items]:len()
end

function metatable:sort(comp)
  self[_items]:sort(comp)
  return self
end

function metatable:insert(index, item, linker, xval, yval, option)
  if type(item) == 'string' then
    item = cel.tocel(item, self)
  end

  self[_items]:insert(index, item, linker, xval, yval, option)

  return self
end

--returns item, index
function metatable:pick(x, y)
  local list = self[_items]
  local px, py, pw, ph = self:getportalrect()
  if x >= px and x < px + pw and y >= py and y < py + ph then
    return list:pick(x - list.x - px, y - list.y - py)
  end
end

do
  local function insertall(listbox, index, t, linker, xval, yval, option)
    for i=1, #t do
      listbox[_items]:insert(index+i-1, t[i], linker, xval, yval, option)
    end
  end
  function metatable:insertlist(index, t, linker, xval, yval, option)
    return self:flux(insertall, self, index, t, linker, xval, yval, option)
  end
end

function metatable:remove(index)
  self[_items]:remove(index)
  return self
end

function metatable:next(item)
  return self[_items]:next(item)
end

function metatable:prev(item)
  return self[_items]:prev(item)
end

do
  local function it(listbox, i)
    i = i + 1
    local item = self[_items]:get(i)
    if item then return i, item end
  end

  function metatable:items(subset)
    if subset == 'selected' then
      if not self[_selected] then
        return pairs(dummy)
      end

      return selectedit, self
    end
    return it, self, 0
  end

  local function selectedit(listbox, prev)
    return (next(listbox[_selected], prev)) --TODO need an index
  end

  local dummy = {}
  function metatable:selecteditems(subset)
    if not self[_selected] then
      return pairs(dummy)
    end
    return selectedit, self
  end
end

function metatable:first()
  return self[_items]:get(1)
end

function metatable:last()
  return self[_items]:get(self:len())
end

function metatable:get(index)
  return self[_items]:get(index)
end

function metatable:indexof(item)
  return self[_items]:indexof(item)
end

--returns the item that was most recently picked(by the user)
function metatable:getcurrent()
  return self[_current]
end

local function changecurrent(listbox, item)
  local current = listbox[_current]
  listbox[_current] = item
  if item then
    item:takefocus()
  end
  return listbox:refresh()
end

function metatable:setcurrent(item)
  if type(item) == 'number' then
    item = self:get(item)
  end
  if item then
    changecurrent(self, item)
  end
  return self
end

function metatable:clear()
  self[_items]:clear()
  return self
end

--TODO optimize this could be done outside the module with same efficiency
function metatable:selectall(mode)
  for i = 1, self:len() do
    self:select(i, mode)
  end
  return self
end

function metatable:select(v, mode)
  local typev = type(v)
  local item
  local index 

  if typev == 'number' then
    item = self:get(v)
    index = v
  elseif typev == 'table' then
    item = v
    index = self:indexof(item)
  else
    --error
  end

  if not item then
    --error
    return
  end

  self[_selected] = self[_selected] or {}

  local selected = self[_selected]

  local op
  if mode == true then
    if selected[item] then return self end
    op = 'select' 
  elseif mode == false then
    if not selected[item] then return self end
    op = 'unselect'  
  else
    if selected[item] then
      op = 'unselect'  
    else
      op = 'select' 
    end 
  end

  if op == 'select' then
    selected[item] = true
  elseif op == 'unselect' then
    selected[item] = nil
  end

  self:refresh()

  if self.onchange then
    return self:onchange(item, index, selected[item] and 'selected' or 'unselected')
  end

  return self
end

--TODO implement mode, for 'top', 'bottom', 'center', 'current postion of cursor'
function metatable:scrolltoitem(item, mode)
  if type(item) == 'number' then
    item = self:get(item)
  end

  if not item then
    return self
  end

  return self:scrolltocel(item)
end

metatable.step = cel.scroll.colstep

do
  local __link = metacel.__link
  function metacel:__link(listbox, link, linker, xval, yval, option)
    if not option or type(option) == 'table' then
      return listbox[_items], linker, xval, yval, option
    else
      return __link(self, listbox, link, linker, xval, yval, option)
    end
  end
end

function metacel:onkey(listbox, state, key, intercepted)
  --[[do it even if key was already intercepted
  if state > 0 then
    if 'up' == key then
      local current = listbox[_current]
      changecurrent(listbox, listbox[_items]:prev(current) or current)
      listbox:scrolltoitem(listbox[_current])
      return true
    elseif 'down' == key then
      local current = listbox[_current]
      changecurrent(listbox, listbox[_items]:next(current) or current)
      listbox:scrolltoitem(listbox[_current])
      return true
    end
  end
  --]]

end

do -- items metacel
  local metacel = metacel['.list'] 

  do --metacel.touch
    function metacel:touch(cel, x, y)
      return true
    end
  end

  do --metacel.dispatchevents
    function metacel:dispatchevents(listbox)
      local changes = listbox[_changes]
      listbox[_changes] = nil

      for i=1, #changes do
        local item, index, value, sink = changes[i][1], changes[i][2], changes[i][3], changes[i][4]
        if false == value then
          if listbox[_selected] and listbox[_selected][item] then
            listbox:select(item, false)
          end
          if listbox[_current] == item then
            changecurrent(listbox, nil)
          end
        end

        if sink then
          sink(listbox, item, index, value)
        end
      end
    end
  end

  do
    local function __qchange(metacel, listbox, link, index, value, sink)
      local changes = listbox[_changes]
      if changes then
        changes[#changes+1] = {link, index, value, sink}
      else
        listbox[_changes] = {{link, index, value, sink}}
        metacel:asyncall('dispatchevents', listbox)
      end
    end

    do --metacel.__link
      function metacel:__link(items, item, linker, xval, yval)
        local listbox = items[_listbox]
        if listbox.onchange then
          __qchange(self, listbox, item, items:len(), true, listbox.onchange)
        end
      end
    end

    do --metacel.__unlink
      function metacel:__unlink(items, item, index)
        local listbox = items[_listbox]
        if listbox.onchange then
          __qchange(self, listbox, item, index, false, listbox.onchange)
        else
          if listbox[_selected] and listbox[_selected][item] then
            __qchange(self, listbox, item, index, false, nil)
          elseif listbox[_current] == item then
            __qchange(self, listbox, item, index, false, nil)
          end
        end
      end
    end
  end

  do --metacel.__describeslot
    function metacel:__describeslot(items, item, index, t)
      local listbox = items[_listbox]

      if listbox[_selected] and listbox[_selected][item] then
        t.selected = true
      else
        t.selected = false
      end

      if listbox[_current] == item then
        t.current = true
      else
        t.current = false
      end
    end
  end
end

do
  local _setsubject = metatable.setsubject
  metatable.setsubject = nil
  metatable.getsubject = nil

  local _new = metacel.new
  function metacel:new(w, h, face)
    face = self:getface(face)
    local layout = face.layout or layout

    local listbox = _new(self, w, h, face)

    local items = metacel['.list']:new(layout.gap, layout.list.face, layout.list.slotface)

    items[_listbox] = listbox
    listbox[_items] = items

    _setsubject(listbox, items, true)

    return listbox
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, listbox)
    listbox = listbox or metacel:new(t.w, t.h, t.face)
    listbox.onchange = t.onchange
    _assemble(self, t, listbox)
    return listbox
  end
end

return metacel:newfactory({layout = layout})

