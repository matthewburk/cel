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

--TODO this is broke by depending on a root cel, fix that
local meta, mt = cel.col.newmetacel('menu')
meta['.slot'] = cel.slot.newmetacel('menu.slot')

local layout = {
  showdelay = 200;
  hidedelay = 200;
  slot = {
    margin = {
      l = 40,
      r = 40,
      t = function(w, h) return h*.25 end; 
      b = function(w, h) return h*.25 end;
    };
    link = 'center',
  };
  divider = {
    w = 1; h = 1;
    link = {'width', 2};
  };
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
  local slot = meta.new_menuslot(menu, fork)
  fork:link(slot, menu[_layout].slot.link)
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

  --x = x + root.X
  --y = y + root.Y

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
end

do
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

function mt.hide(menu)
  menu:unlink()
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
  function meta:__link(menu, link, linker, xval, yval, option)
    if option == 'divider' then
      return
    elseif not ismenuslot(link) then
      local slot = self.new_menuslot(menu, link)
      return slot, menu[_layout].slot.link
    end
  end
end

function meta:onmousein(menu)
  local parentmenu = menu[_parentmenu]
  if parentmenu then
    parentmenu[_task] = false
  end
end

function meta:__celfromstring(menu, s)
  return cel.label.new(s, cel.menu)
end

do --meta['.slot']
  local meta_slot = meta['.slot']

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
          menu:onchoose(slot.item)
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
    local normalize = cel.util.normalize_padding
    local _new = meta_slot.new
    function meta_slot:new(menu, item)
      local layout = menu[_layout].slot
      local slot = _new(self, normalize(layout.margin, item.w, item.h))
      slot[_menu] = menu
      slot.item = item
      slot:link(menu, 'width')
      return slot 
    end
  end

end

do
  local _new = meta.new
  function meta:new(face)
    local face = self:getface(face)
    local layout = face.layout or layout
    local menu = _new(self, 0, face)
    menu[_layout] = layout
    return menu
  end

  local _compile = meta.compile
  function meta:compile(t, menu)
    menu = menu or meta:new(t.face)
    menu.onchoose = t.onchoose
    return _compile(self, t, menu)
  end

  local _compileentry = meta.compileentry
  function meta:compileentry(menu, entry, entrytype)
    if 'table' == entrytype and entry.submenu then
      menu:fork(entry.submenu, cel.menu(entry))
    else
      _compileentry(self, menu, entry, entrytype)
    end
  end
end

do
  local slotmeta = meta['.slot']
  meta.new_menuslot = slotmeta:newfactory().new
end

local function divider(menu)
  menu:putdivider()
end

return meta:newfactory({layout = layout, divider=divider})
