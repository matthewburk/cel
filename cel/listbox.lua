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
metacel['.itemlist'] = cel.col.newmetacel('listbox.itemlist')

local _listbox = {}
local _items = {}
local _selected = {}
local _current = {}
local _changes = {}
local _boxface = {}
local boxface = cel.face { metacel='listbox.itembox' }

cel.face { metacel = 'listbox.itemlist' }

local layout = {
  itemlist = {
    face = nil,
    gap = 0,
    
  },
  itembox = {
    --note that itembox is a virtual cel
    face = boxface,  
  };
}

function metatable:flux(...)
  self[_items]:flux(...)
  return self 
end

function metatable:len()
  return self[_items]:len()
end

function metatable:insert(item, index)
  if type(item) == 'string' then
    item = cel.tocel(item, self)
  end

  item:link(self, nil, nil, nil, index)
  return self
end

--returns item, index
function metatable:pick(x, y)
  local list = self[_items]
  local px, py, pw, ph = self:getportalrect()
  if x >= px and x < px + pw and y >= py and y < py + ph then
    return list:pick(x - list.x, y - list.y)
  end
end

do
  local function insertall(listbox, index, t)
    for i=1, #t do
      t[i]:link(listbox, nil, nil, nil, index)
    end
  end
  function metatable:insertlist(t, index)
    return self:flux(insertall, self, index, t)
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

--TODO implement mode, for 'top', 'bottom', 'center', 'current postion of cursor'
function metatable:scrolltoitem(item, mode)
  if type(item) == 'number' then
    item = self:get(item)
  end

  if not item then
    return self
  end

  local x, y, w, h = self:getportalrect()
  x, y = self:getvalues();

  if y + h < item.y + item.h then
    self:scrollto(nil, item.y + item.h - h)
  elseif item.y < y then
    self:scrollto(nil, item.y)
  else
  end
  return self
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

do
  local function map(listbox, value)
    local items = listbox[_items]
    local cel = items:pick(0, value)
    if cel and value ~= cel.y then
      cel = items:next(cel)
      if cel then
        return cel.y
      else
        return items.h
      end
    end
    return value
  end

  local _scrollto = metatable.scrollto
  function metatable.scrollto(listbox, x,  y)
    listbox[_items]:endflow()
    y = y and map(listbox, y)
    return _scrollto(listbox, x, y)
  end

  function metatable.step(listbox, xstep, ystep, mode)
    local items = listbox[_items]

    items:endflow()

    local x, y = listbox:getvalues()
    if ystep and ystep ~= 0 then
      local item = items:pick(0, y)

      if item then
        if ystep > 0 then
          item = items:next(item)
        else 
          if y <= item.y then --to keep step to the top of a cel if we are in the middle of it
            item = items:prev(item)
          end
        end
      end

      if item then
        y = item.y
      elseif ystep > 0 then
        y = items.h
      else
        y = 0
      end
    else
      y = nil
    end

    if xstep then
      x = x + (xstep * listbox.stepsize)
    else
      x = nil
    end

    return _scrollto(listbox, x, y)
  end
end

do
  local __link = metacel.__link
  function metacel:__link(listbox, link, linker, xval, yval, option)
    if not option or type(option) == 'number' then
      --TODO link must accept an option
      return listbox[_items], linker, xval, yval, option
    else
      return __link(self, listbox, link, linker, xval, yval, option)
    end
  end
end

--TODO why does listbox.big test take twice as long as col.big test
--
--
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
  local metacel = metacel['.itemlist'] 

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

  do --metacel.__qchange
    function metacel:__qchange(listbox, link, index, value, sink)
      local changes = listbox[_changes]
      if changes then
        changes[#changes+1] = {link, index, value, sink}
      else
        listbox[_changes] = {{link, index, value, sink}}
        self:asyncall('dispatchevents', listbox)
      end
    end
  end

  do --metacel.__link
    function metacel:__link(items, item, linker, xval, yval, index)
      local listbox = items[_listbox]
      if listbox.onchange then
        self:__qchange(listbox, item, index or items:len(), true, listbox.onchange)
      end
    end
  end

  do --metacel.__unlink
    function metacel:__unlink(items, item, index)
      local listbox = items[_listbox]
      if listbox.onchange then
        self:__qchange(listbox, item, index, false, listbox.onchange)
      else
        if listbox[_selected] and listbox[_selected][item] then
          self:__qchange(listbox, item, index, false, nil)
        elseif listbox[_current] == item then
          self:__qchange(listbox, item, index, false, nil)
        end
      end
    end
  end

  do --metacel.__describeslot
    function metacel:__describeslot(items, item, index, t)
      local listbox = items[_listbox]

      t.face = listbox[_boxface]

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

  do --metacel.onmousedown
    function metacel:onmousedown(items, button, x, y, intercepted)
      local listbox = items[_listbox]
      if listbox.rowevent and listbox.rowevent.onmousedown then
        local item, row = items[_listbox], items:pick(x, y)
        if item then
          return listbox.rowevent.onmousedown(listbox, row, item, button, x, y, intercepted)
        end
      end
    end
  end

  do --metacel.onmouseup
    function metacel:onmouseup(items, button, x, y, intercepted)
      local listbox = items[_listbox]
      if listbox.rowevent and listbox.rowevent.onmouseup then
        local item, row = items[_listbox], items:pick(x, y)
        if item then
          return listbox.rowevent.onmouseup(listbox, row, item, button, x, y, intercepted)
        end
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
    listbox[_boxface] = layout.itembox.face or boxface

    local items = metacel['.itemlist']:new(layout.itemlist.gap, layout.itemlist.face)

    items[_listbox] = listbox
    listbox[_items] = items

    _setsubject(listbox, items, true)

    return listbox
  end

  local _compile = metacel.compile
  function metacel:compile(t, listbox)
    listbox = listbox or metacel:new(t.w, t.h, t.face)
    listbox.onchange = t.onchange
    _compile(self, t, listbox)
    return listbox
  end
end

return metacel:newfactory({layout = layout})

