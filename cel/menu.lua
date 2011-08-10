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
local _hidetask = {}
local _showtask = {}
local _options = {}
local _root = {}

local metacel, metatable = cel.sequence.y.newmetacel('menu')
metacel['.slot'] = cel.slot.newmetacel('menu.slot')

local options = {
  showdelay = 200;
  hidedelay = 200;
  slot = {
    link = {'width'};
    padding = {
      l = 40,
      r = 40,
      t = function(w, h) return h*.25 end; 
      b = function(w, h) return h*.25 end;
    };
    item = {
      link = {'center'};
    };
  };
  divider = {
    w = 1; h = 1;
    link = {'width', 2};
  };
}

local function ismenuslot(slot)
  return slot[_menu] ~= nil
end

function metatable.putdivider(menu)
  local opt = menu[_options].divider
  cel.new(opt.w, opt.h, cel.menu.divider):link(menu, opt.link, 'divider')
  return menu
end

function metatable.fork(menu, fork, submenu)
  local fork = type(fork) == 'string' and cel.label.new(fork, cel.menu) or fork
  local slot = metacel.new_menuslot(menu, fork)
  fork:link(slot, menu[_options].slot.item.link)
  slot[_submenu] = submenu
  return menu
end

function metatable.addslot(menu, item)
  item:link(menu)
  return menu
end

function metatable.popupdismissed(menu)
  if menu[_hidetask] then
    menu[_hidetask]:cancel()
    menu[_hidetask] = nil
  end
  if menu[_showtask] then
    menu[_showtask]:cancel()
    menu[_showtask] = nil
  end
  if menu[_parentmenu] then
    menu[_parentmenu][_submenu] = nil
    menu[_parentmenu] = nil
  end
  menu[_root] = nil
end

function metatable.showat(menu, x, y, root)
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

  menu:link(root, x, y, root.linkoption.popup(menu[_parentmenu]))
end

function metatable.hide(menu)
  menu:unlink()
end

local function showat(menu, x, y, parent)
  menu[_root] = parent[_root]
  local root = menu[_root]
  --TODO enforce a single showing menu for the parent
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
    metatable.showat(menu, x, y)
  end
end

do
  function metacel:__link(menu, link, linker, xval, yval, option)
    if option == 'divider' then
      return
    elseif not ismenuslot(link) then
      local slot = self.new_menuslot(menu, link)
      return slot, menu[_options].slot.item.link
    end
  end
end

function metacel:onmousein(menu)
  local parentmenu = menu[_parentmenu]
  if parentmenu and parentmenu[_hidetask] then
    parentmenu[_hidetask]:cancel()
    parentmenu[_hidetask] = nil
  end
end

function metacel:__celfromstring(menu, s)
  return cel.label.new(s, cel.menu)
end

do --metacel['.slot']
  local metacel_slot = metacel['.slot']

  function metacel_slot:__describe(slot, t)
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

  function metacel_slot:onmouseup(slot)
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

  function metacel_slot:onmouseout(slot)
    local menu = slot[_menu]
    local slot_submenu = slot[_submenu]
    local menu_submenu = menu[_submenu]

    if slot_submenu then
      if menu[_showtask] then 
        menu[_showtask]:cancel()
        menu[_showtask] = nil
      end

      if slot_submenu == menu_submenu then
        menu[_hidetask] = cel.doafter(menu[_options].hidedelay, function()
          slot_submenu:unlink()
          menu[_hidetask] = nil
        end)
      end
    end
  end

  function metacel_slot:onmousein(slot)
    local menu = slot[_menu]
    local slot_submenu = slot[_submenu]
    local menu_submenu = menu[_submenu]

    if slot_submenu then
      if slot_submenu == menu_submenu then
        if menu[_hidetask] then
          menu[_hidetask]:cancel()
          menu[_hidetask] = nil
        end
      else
        if menu_submenu then
          menu[_hidetask] = cel.doafter(menu[_options].hidedelay, function()
            menu_submenu:unlink()
            menu[_hidetask] = nil
          end)
        end

        menu[_showtask] = cel.doafter(menu[_options].showdelay, function() 
          showat(slot_submenu, slot.X + slot.w, slot.Y, menu) 
          menu[_showtask] = nil
        end)
      end
    else
      if menu_submenu and not menu[_hidetask] then
        menu[_hidetask] = cel.doafter(menu[_options].hidedelay, function()
          menu_submenu:unlink()
          menu[_hidetask] = nil
        end)
      end
    end
  end

  do
    local normalize = cel.util.normalize_padding
    local _new = metacel_slot.new
    function metacel_slot:new(menu, item)
      local options = menu[_options].slot
      local slot = _new(self, normalize(options.padding, item.w, item.h))
      slot[_menu] = menu
      slot.item = item
      slot:link(menu, options.link)
      return slot 
    end
  end

end

local menufork = {}
do
  local _new = metacel.new
  function metacel:new(face)
    local face = self:getface(face)
    local options = face.options or options
    local menu = _new(self, 0, face)
    menu[_options] = options
    return menu
  end

  local _compile = metacel.compile
  function metacel:compile(t, menu)
    menu = menu or metacel:new(t.face)
    menu.onchoose = t.onchoose
    return _compile(self, t, menu)
  end

  local _compileentry = metacel.compileentry
  function metacel:compileentry(menu, entry, entrytype)
    if 'table' == entrytype and entry[menufork] then
      menu:fork(entry[menufork], cel.menu(entry))
    else
      _compileentry(self, menu, entry, entrytype)
    end
  end
end

do
  local slotmetacel = metacel['.slot']
  metacel.new_menuslot = slotmetacel:newfactory().new
end

local function divider(menu)
  menu:putdivider()
end

return metacel:newfactory({options = options, divider=divider, fork=menufork})
