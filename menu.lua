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

local _setmenu = {}
local _menu = {}
local _submenu = {}
local _parentmenu = {}
local _task = {}
local _layout = {}
local _root = {}

local metacel, mt = cel.col.newmetacel('menu')
metacel['.slot'] = cel.slot.newmetacel('menu.slot')

local layout = {
  showdelay = 200,
  hidedelay = 200,
  menuslot = {
    face = nil,
    link = nil, --how subject is linked in menuslot
  },
  divider = {
    w = 1; h = 1;
    link = {'width', 2};
  };
}

local menuslotlayout = {
  margin = nil,
  --[[
  margin = {
    l = 40,
    r = 40,
    t = function(w, h) return h*.25 end; 
    b = function(w, h) return h*.25 end;
  },
  --]]
}

local function ismenuslot(slot)
  return slot[_menu] ~= nil
end

function mt.putdivider(menu)
  local opt = menu[_layout].divider
  cel.new(opt.w, opt.h, cel.menu.divider):link(menu, opt.link, 'divider')
  return menu
end

function mt.fork(menu, fork, submenu)
  local fork = type(fork) == 'string' and cel.label.new(fork, cel.menu) or fork
  local slot = metacel.new_menuslot(menu, fork)
  fork:link(slot, menu[_layout].menuslot.link)
  slot[_submenu] = submenu
  return menu
end

function mt.addslot(menu, item)
  item:link(menu)
  return menu
end

function mt.showat(menu, x, y, root)
  root = root or menu[_root]
  menu[_root] = root

  local hw, hh = root.w, root.h
  local w, h = menu.w, menu.h

  if x + w > hw then
    x = x - w
    if x < 0 then x = 0 end
  end

  if y + h > hh then
    y = y - h
    if y < 0 then y = 0 end
  end

  menu:link(root, x, y, 'popup')

  if not menu[_parentmenu] then
    cel.trackmouse(function(action, button, x, y)

      if not menu:islinkedtoroot() then
        return false
      end

      if 'down' == action then
        do
          local menu = menu
          while menu do
            if menu:hasfocus(cel.mouse) then
              return true  
            end
            menu = menu[_submenu]
          end
        end

        do
          local menu = menu
          while menu do
            menu:unlink()
            menu = menu[_submenu]
          end
        end

        

        return false
      end

      return true
    end)
  end

  return menu
end

do --TODO do not do this, against the rules
  local _unlink = mt.unlink
  function mt.unlink(menu)
    local ret = menu

    do
      local parentmenu = menu[_parentmenu] 
      if parentmenu and parentmenu[_submenu] == menu then
        parentmenu[_submenu] = nil
      end
    end

    while menu do 
      menu[_task] = false
      _unlink(menu)
      local submenu = menu[_submenu]
      menu[_submenu] = nil
      menu = submenu
    end

    return ret 
  end
end

local function showat(menu, x, y, parent)
  menu[_root] = parent[_root]
  local root = menu[_root]
  menu[_parentmenu] = parent

  if parent[_submenu] and parent[_submenu] ~= menu then
    parent[_submenu]:unlink()
  end

  parent[_submenu] = menu 

  x = parent.x
  local hw, hh = root.w, root.h
  local w, h = menu.w, menu.h
  local pw = parent.w

  if x + w + pw > hw then
    x = x - w + 4
  else
    x = x + pw - 4
  end

  if y + h > hh then
    y = y - (y + h - hh)
  end

  if menu.showat then
    menu:showat(x, y)
  else
    mt.showat(menu, x, y)
  end
end

do
  function metacel:__link(menu, link, linker, xval, yval, option)
    if option == 'divider' then
      return
    elseif not ismenuslot(link) then
      local slot = self.new_menuslot(menu, link)
      local layout = menu.face.layout or layout

      if linker then
        return slot, linker, xval, yval
      else
        return slot, layout.menuslot.link 
      end
    end
  end
end

function metacel:onmousein(menu)
  local parentmenu = menu[_parentmenu]
  if parentmenu then
    parentmenu[_task] = false
  end
end

function metacel:__celfromstring(menu, s)
  return cel.label.new(s, cel.menu)
end

do --metacel['.slot']
  local meta_slot = metacel['.slot']

  function meta_slot:__describe(slot, t)
    local submenu = slot[_submenu]
    if submenu then
      if submenu:islinkedtoroot() then
        t.submenu = 'active'
      else
        t.submenu = 'inactive'
      end
    else
      t.submenu = false
    end
  end

  function meta_slot:onmouseup(slot)
    local menu = slot[_menu]
    if not slot[_submenu] then
      while menu do
        if menu.onchoose then
          menu:onchoose(slot.item, slot[_menu])
          break
        end
        menu = menu[_parentmenu]
      end
    end
    return true
  end

  function meta_slot:onmouseout(slot)
    local menu = slot[_menu]
    local slot_submenu = slot[_submenu]
    local menu_submenu = menu[_submenu]

    if slot_submenu then
      if slot_submenu ~= menu_submenu then
        menu[_task] = false
      else
        menu[_task] = cel.doafter(menu[_layout].hidedelay, function(task)
          if menu[_task] == task then
            slot_submenu:unlink()
            menu[_task] = nil
          end
        end)
      end
    end
  end

  function meta_slot:onmousein(slot)
    local menu = slot[_menu]
    local slot_submenu = slot[_submenu]
    local menu_submenu = menu[_submenu]

    if slot_submenu then
      if slot_submenu ~= menu_submenu then
        menu[_task] = cel.doafter( menu[_layout].showdelay, function(task) 
          if menu[_task] == task then
            showat(slot_submenu, slot.X + slot.w, slot.Y, menu) 
            menu[_task] = nil
          end
        end)
      end
    elseif menu_submenu then
      menu[_task] = cel.doafter(menu[_layout].hidedelay, function(task)
        if menu[_task] == task then
          menu_submenu:unlink()
          menu[_task] = nil
        end
      end)
    end
  end

  do
    --TODO remove this, or implement the same everywere that margin/padding is applied
    local normalize = function(padding, w, h, ...)
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

    local _new = meta_slot.new
    function meta_slot:new(menu, item)
      local layout = menu.face.layout -- or layout
      local face = self:getface(layout.menuslot.face)

      local slot 
      if face.layout and face.layout.margin then
        slot = _new(self, face, normalize(face.layout.margin, item.w, item.h))
      else
        slot = _new(self, face)
      end
      
      slot[_menu] = menu
      slot.item = item
      slot:link(menu, 'width')
      return slot 
    end
  end

end

do
  local _new = metacel.new
  function metacel:new(face)
    local face = self:getface(face)
    local layout = face.layout or layout
    local menu = _new(self, 0, face)
    menu[_layout] = layout
    return menu
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, menu)
    menu = menu or metacel:new(t.face)
    menu.onchoose = t.onchoose
    return _assemble(self, t, menu)
  end

  local _assembleentry = metacel.assembleentry
  function metacel:assembleentry(menu, entry, entrytype)
    if 'table' == entrytype and entry.submenu then
      menu:fork(entry.submenu, cel.menu(entry))
    else
      _assembleentry(self, menu, entry, entrytype)
    end
  end
end

do
  local slotmeta = metacel['.slot']
  metacel.new_menuslot = slotmeta:newfactory().new
end

local function divider(menu)
  menu:putdivider()
end

return metacel:newfactory({layout = layout, divider=divider})
