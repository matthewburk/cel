local cel = require 'cel'

local metacel, metatable = cel.scroll.newmetacel('listbox')
metacel['.items'] = cel.sequence.y.newmetacel('listbox.items')

local _listbox = {}
local _items = {}
local _selected = {}
local _current = {}
local _changes = {}
local _slotface = {}
local slotface = cel.face { metacel='listbox.items.item' }

local layout = {
  scroll = nil,
  items = {
    gap = 0,
    face = cel.face { metacel = 'listbox.items' },
    slotface = slotface
  },
}

function metatable.flux(listbox, callback, ...)
  return listbox[_items]:flux(callback, ...)
end

function metatable:len()
  return self[_items]:len()
end

function metatable:insert(index, item)
  if not item then
    item = index
    index = nil
  end

  if type(item) == 'string' then
    item = cel.label.new(item)
  end

  return item:link(self, nil, nil, nil, index)
end

do
  local function insertall(listbox, index, t)
    for i=1, #t do
      t[i]:link(listbox, nil, nil, nil, index)
    end
  end
  function metatable:insertlist(index, t)
    if not t then
      t = index
      index = nil
    end
    return self:flux(insertall, self, index, t)
  end
end

function metatable:trim(size)
  if size <= 0 then
    return self:clear()
  end

  local len = self[_items]:len()
  while len > size do
    self[_items]:remove(len)
    len = len - 1
  end

end

function metatable:remove(index, endindex)

  if endindex and endindex ~= index then
    for i=endindex, index, -1 do 
      self[_items]:remove(i)
    end
  else
    self[_items]:remove(index)
  end
end


function metatable:next(item)
  return self[_items]:next(item)
end

function metatable:prev(item)
  return self[_items]:prev(item)
end

do
  local dummy = {}
  function metatable:items(subset)
    if subset == 'selected' then
      if not self[_selected] then
        return pairs(dummy)
      end

      return pairs(self[_selected])
    end
    return self[_items]:links()
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
function metatable.scrolltoitem(listbox, item, mode)
  local x, y, w, h = listbox:getportal()

  if y + h < item.y + item.h then
    listbox:scrollto(nil, item.y + item.h - h)
  elseif item.y < y then
    listbox:scrollto(nil, item.y)
  else
  end
end

function metatable:setcurrent(index)
  local item = self:get(index)

  if item then
    changecurrent(self, item)
  end
end

function metatable:clear()
  return self[_items]:clear()
end

function metatable:selectall(mode)
  --TODO optimize this could be done outside the module with same efficiency
  for i = 1, self:len() do
    self:select(i, mode)
  end
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
    if selected[item] then return end
    op = 'select' 
  elseif mode == false then
    if not selected[item] then return end
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

    local x, y = listbox:getvalue()
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

function metacel:__link(listbox, link, linker, xval, yval, option)
  if option ~= 'raw' then
    --TODO link must accept an option
    return listbox[_items], linker, xval, yval, option
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
local metacel = metacel['.items'] 

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
          changecurrent(listbox, listbox[_items]:get(index - 1) or listbox[_items]:get(1))
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

    t.face = listbox[_slotface]

    if listbox[_selected] and listbox[_selected][item] then
      t.selected = true
    end

    if listbox[_current] == item then
      t.current = true
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

  local _new = metacel.new
  function metacel:new(w, h, face)
    face = self:getface(face)
    local layout = face.layout or layout

    local listbox = _new(self, w, h, face)
    listbox[_slotface] = layout.slotface or slotface

    local items = metacel['.items']:new(layout.items.gap, layout.items.face)

    items[_listbox] = listbox
    listbox[_items] = items

    _setsubject(listbox, items, true)

    return listbox
  end

  local _compile = metacel.compile
  function metacel:compile(t, listbox)
    listbox = listbox or metacel:new(t.w, t.h, t.face)
    listbox.onchange = t.onchange
    --listbox[_items]:flux( function()
        _compile(self, t, listbox)
    --  end)
    return listbox
  end
end

return metacel:newfactory()
