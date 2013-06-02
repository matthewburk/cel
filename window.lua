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

local metacel, metatable = cel.newmetacel('window')
metacel['.border'] = cel.grip.newmetacel('window.border')
metacel['.corner'] = cel.grip.newmetacel('window.corner')
metacel['.handle'] = cel.grip.newmetacel('window.handle')
metacel['.client'] = cel.newmetacel('window.client')

local _client = {}
local _state = {}
local _activated = {}
local _title = {}
local _bordersize = {}
local _handle = {}
local _grips = {} --border and corners, so we can disable and reenable them, note used yet

local layout = {
  minw = 30 + 30 + 30 + 10 + 10,
  minh = 10 + 31 + 10,
  maxw = nil,
  maxh = nil,

  border = {
    size = 10,
  },
  corner = {
    size = 20,
  },
  handle = {
    w = 31,
    h = 31,    
    link = {'width.top', 10, 10}, --bordersize, bordersize
  },
  client = {    
    w = 0,
    h = 0,
    link = {cel.rcomposelinker('fill.topmargin', 'fill.margin'), {31, 10}},
  }
}

--TODO also allow link {linker, xval, yval} as param
function metatable.addcontrols(window, controls, linker, xval, yval)
  local handle = window[_handle]
  controls:link(handle, linker, xval, yval)
end

function metatable.adddefaultcontrols(window)
  local minbutton = cel.button.new(20, 20)
  local maxbutton = cel.button.new(24, 24)
  local seq = cel.row.new()
  minbutton:link(seq, 'bottom')
  maxbutton:link(seq)
  window:addcontrols(seq, 'right')

  function minbutton.onclick()
    if window:getstate() == 'minimized' then
      window:restore()
    else
      window:minimize()
    end
  end

  function maxbutton.onclick()
    if window:getstate() == 'maximized' then
      window:restore()
    else
      window:maximize()
    end
  end

  return window
end

function metatable.getbordersize(window)
  return window[_bordersize]
end

function metatable.settitle(window, title)
  window[_title] = title
  return window:refresh()
end

function metatable.gettittle(window)
  return window[_title]
end

function metatable.isactivated(window)
  return window[_activated] 
end

function metatable.getstate(window)
  return window[_state] or 'normal'
end

function metatable.getclientrect(window)
  return window[_client]:pget('x', 'y', 'w', 'h')
end

local function onrestored(window)
  local oldstate = window[_state]
  window[_state] = nil
  if window.onchange then
    window:onchange('normal', oldstate)
  end
end

do
  
  local function onmaximized(window)
    local oldstate = window[_state]
    window[_state] = 'maximized'
    if window.onchange then
      window:onchange('maximized', oldstate)
    end
  end

  function metatable.maximize(window)
    if 'maximized' == window[_state] then 
      return window 
    end
    
    if not rawget(window, 'restore') then
      --TODO pget minw, maxw, minh, maxh should return nil for unset values
      --explain this is so the values can be passed back into with forcing a value to be
      --stored for the default value
      local linker, xval, yval, x, y, w, h = window:pget('linker', 'xval', 'yval', 'x', 'y', 'w', 'h')

      function window:restore()
        window.restore = nil
        window[_state] = 'restoring'
        if linker then
          window:relink():flow('restore', x, y, w, h, nil, function(...)
            window:relink(linker, xval, yval)
            onrestored(...) 
          end)
        else
          window:relink():flow('restore', x, y, w, h, nil, onrestored)
        end
      end
    end

    window[_state] = 'maximizing'
    window:flowlink('maximize', 'fill.margin', -window[_bordersize], -window[_bordersize], nil, onmaximized)
    return window
  end
end

function metatable:restore()
  --do nothing, this is only visible when the window.restore has not been defined by minimize or maximize
  return self
end
do
  local function minimizelinker(hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)
    return 0, hh - minh, minw, minh 
  end

  local function onminimized(window)
    local oldstate = window[_state]
    window:resize(0, 0) --hack becuase relink is not honored as a move request by layout formations as it should be
    window[_state] = 'minimized'
    if window.onchange then
      window:onchange('minimized', oldstate)
    end
  end

  function metatable.minimize(window)
    if 'minimized' == window[_state] then 
      return window
    end
      
    if not rawget(window, 'restore') then
      local linker, xval, yval, x, y, w, h = window:pget('linker', 'xval', 'yval', 'x', 'y', 'w', 'h')
      function window:restore()
        window.restore = nil
        window[_state] = 'restoring'
        if linker then
          window:relink():flow('restore', x, y, w, h, nil, function(...)
            window:relink(linker, xval, yval)
            onrestored(...) 
          end)
        else
          window:relink():flow('restore', x, y, w, h, nil, onrestored)
        end
      end
    end

    window[_state] = 'minimizing'
    window:flowlink('minimize', minimizelinker, nil, nil, nil, onminimized)
    return window
  end
end

function metacel:__describe(window, t)
  t.activated = window[_activated] or false
  t.state = window[_state] or 'normal'
  t.title = window[_title]
end

function metacel:__link(window, link, linker, xval, yval, option)
  if option then
    if 'raw' == option then
      return window, linker, xval, yval, nil 
    elseif 'handle' == option then
      return window[_handle], linker, xval, yval
    end
  end

  return window[_client], linker, xval, yval, option
end

function metacel:onfocus(window)
  self:activate(window)
  window:refresh()
end

function metacel:onblur(window)
  window[_activated] = false 
  window:refresh()
end

function metacel:onmousedown(window, mousebutton, x, y)
  if mousebutton == cel.mouse.buttons.left then
    --print(window, 'left mouse down')
    self:activate(window)
  end
end

function metacel:activate(window)
  if not window[_activated] then
    

    if not window:hasfocus() then
      if select(2, window:takefocus()) then
        window[_activated] = true
      end
    end

    window:raise()

    if window.onactivate then window:onactivate() end

    window:refresh()
  end
end

--this should be to handle a dblclick
local function handlemousedown(grip, mousebutton, x, y)
  --[[
  if state == 2 and mousebutton == cel.mouse.buttons.left and state == 2 then
    grip:freemouse()
    local window = grip:getgrip()
    if window[_state] == 'maximized' then
      window:restore()
    else
      window:maximize()
    end
  end
  --]]
end

do 
  local _new = metacel.new
  function metacel:new(w, h, face)
    local face = self:getface(face)
    local layout = face.layout or layout
    local minw, maxw, minh, maxh = layout.minw or 0, layout.maxw, layout.minh or 0, layout.maxh

    w = w or minw
    h = h or minh
    if w < minw then w = minw end
    if h < minh then h = minh end
    if maxw and w > maxw then w = maxw end
    if maxh and h > maxh then h = maxh end

    local window = _new(self, w, h, face)

    window:setlimits(layout.minw, layout.maxw, layout.minh, layout.maxh)

    local bordersize = 0
    
    if layout.border then
      local layout = layout.border
      bordersize = layout.size

      do --top
        local border = self['.border']:new(bordersize, bordersize, layout.face)
        border:grip(window, 'top') 
        border:link(window, 'width.top', bordersize, 0, 'raw')
      end
      do --bottom
        local border = self['.border']:new(bordersize, bordersize, layout.face)
        border:grip(window, 'bottom')
        border:link(window, 'width.bottom', bordersize, 0, 'raw')
      end
      do --left
        local border = self['.border']:new(bordersize, bordersize, layout.face)
        border:grip(window, 'left')
        border:link(window, 'left.height', 0, bordersize, 'raw')
      end
      do --right
        local border = self['.border']:new(bordersize, bordersize, layout.face)
        border:grip(window, 'right')
        border:link(window, 'right.height', 0, bordersize, 'raw')
      end
    end

    if layout.corner then
      local layout = layout.corner
      local cs = layout.size
      do --topleft
        local corner = self['.corner']:new(cs, cs, layout.face)
        corner:grip(window, 'topleft')
        corner:link(window, nil, nil, nil, 'raw')
      end
      do --topright
        local corner = self['.corner']:new(cs, cs, layout.face)
        corner:grip(window, 'topright')
        corner:link(window, 'right.top', nil, nil, 'raw')
      end
      do --bottomleft
        local corner = self['.corner']:new(cs, cs, layout.face)
        corner:grip(window, 'bottomleft')
        corner:link(window, 'left.bottom', nil, nil, 'raw')
      end
      do --bottomright
        local corner = self['.corner']:new(cs, cs, layout.face)
        corner:grip(window, 'bottomright')
        corner:link(window, 'right.bottom', nil, nil, 'raw')
      end
    end

    if layout.handle then 
      local layout = layout.handle
      local handle = self['.handle']:new(layout.w, layout.h, layout.face)
      handle:grip(window)
      handle.onmousedown = handlemousedown
      handle:link(window, layout.link, 'raw')
      window[_handle] = handle
    end

    do
      layout = layout.client
      local client = self['.client']:new(layout.w, layout.h, layout.face)
      client:link(window, layout.link)
      window[_client] = client 
    end

    window[_bordersize] = bordersize

    return window
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, window)
    window = window or metacel:new(t.w, t.h, t.face)

    if t.title then window:settitle(t.title) end

    window.onchange = t.onchange
    return _assemble(self, t, window)
  end

  local _newmetacel = metacel.newmetacel
  function metacel:newmetacel(name)
    local newmetacel, metatable = _newmetacel(self, name)
    newmetacel['.handle'] = metacel['.handle']:newmetacel(name .. '.handle')
    newmetacel['.client'] = metacel['.client']:newmetacel(name .. '.client')
    newmetacel['.border'] = metacel['.border']:newmetacel(name .. '.border')
    newmetacel['.corner'] = metacel['.corner']:newmetacel(name .. '.corner')
    return newmetacel, metatable
  end
end

return metacel:newfactory({layout = layout})
