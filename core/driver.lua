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

local type = type
local pairs = pairs

local CEL = require 'cel.core.env'

local _host = CEL._host
local _trap = CEL._trap
local _focus = CEL._focus
local _x = CEL._x
local _y = CEL._y
local _w = CEL._w
local _h = CEL._h
local _vectorx = CEL._vectorx
local _vectory = CEL._vectory
local _keys = CEL._keys
local _states = CEL._states
local _disabled = CEL._disabled
local _refresh = CEL._refresh

CEL.mouse = {
  [_x] = 0,
  [_y] = 0,
  [_vectorx] = 0,
  [_vectory] = 0,
  [_focus] = {},
  [_states] = {},
  scrolllines = 1,
  buttons = {},
  states = {},
  wheel = {},
}

CEL.keyboard = { 
  [_focus] = {n = 0},
  [_keys] = {},
  keys = {},
  states = {},
}

local mouse = CEL.mouse
local keyboard = CEL.keyboard
local event = CEL.event
local driver = CEL.driver
local flows = CEL.flows
local timer = CEL.timer

local tasks = {} 

function CEL.doafter(ms, f)
  if not f then
    error('expected a function', 2)
  end

  local task = {
    func = f;
    due = timer.millis + ms,
    next = nil,
  }

  local prev = tasks
  local next = tasks.next

  while next do
    if task.due < next.due then
      task.next = next
      break
    end
    prev = next
    next = next.next
  end

  prev.next = task

  return f
end

local function doflows()
  event:wait()
  for cel, t in pairs(flows) do
    local context = t.context
    local ox, oy, ow, oh = t.ox, t.oy, t.ow, t.oh
    local fx, fy, fw, fh = t.fx, t.fy, t.fw, t.fh 
    local flow = t.flow 
    local update = t.update 
    local finalize = t.finalize 

    context.duration = timer.millis - t.startmillis 
    context.iteration = context.iteration + 1
    --TODO add value flow logic
    local x, y, w, h, reflow 
    if context.mode == 'rect' then
      x, y, w, h, reflow = flow(context, ox, fx, oy, fy, ow, fw, oh, fh)
    else
      x, reflow = flow(context, ox, fx)
    end

    if reflow then        
      update(cel, x, y, w, h)
    else
      context.finalize = context.iteration
      if t.linker then
        cel:relink(t.linker, t.xval, t.yval)
        update(cel, cel[_x], cel[_y], cel[_w], cel[_h]) --TODO only have to do this if update ~= move
      else
        update(cel, fx, fy, fw, fh)
      end
      flows[cel] = nil
      if finalize then finalize(cel) end
    end
  end
  event:signal()
end

local function dotasks()
  local time = timer.millis
  local task

  while tasks.next do
    task = tasks.next
    if time >= task.due then
      tasks.next = task.next
      task.next = nil
      event:task(task)
    else
      break
    end
  end
end

do --driver.tick
  local mark = 0
  local accumulator = 0
  function driver.tick(ms, max)
    if ms - mark > 1 then
      mark = ms
    elseif ms - mark < 0 then
      accumulator = accumulator + max
    else
      return
    end

    timer.millis = accumulator + ms

    event:wait()

    doflows()
    dotasks()

    local target = mouse[_focus].focus or mouse[_trap].trap

    --TODO pass lx, and ly like in mousepressed
    while target do
      event:ontimer(target, ms, mouse)
      target = target[_host]
    end

    local device_focus = keyboard[_focus]
    local focus = device_focus[device_focus.n]

    if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
      if focus then
        while focus do
          event:ontimer(focus, ms, keyboard)
          focus = focus[_host]
        end
      else
        --event:ontimer( the current modal cel, key)
      end
    end

    event:signal()
  end
end

function driver.mousemove(x, y)
  if x == mouse[_x] and y == mouse[_y] then
    return
  end

  event:wait()

  mouse[_vectorx] = x - mouse[_x]
  mouse[_vectory] = y - mouse[_y]
  mouse[_x] = x
  mouse[_y] = y

  --lx and ly are x and y translated into mouse[_focus] coordinates
  local lx, ly = CEL.pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap

  event:ontrackmouse('move', lx, ly)

  while target do
    if not target[_disabled] then event:onmousemove(target, lx, ly) end
    lx = lx + target[_x]
    ly = ly + target[_y]
    target = target[_host]
  end

  event:signal()
end

--TODO state is implied do not let it be passed in
function driver.mousedown(x, y, button, alt, ctrl, shift)
  if button == nil then return end --protect against bad input

  driver.mousemove(x,y)
  event:wait()

  local states = mouse[_states]
  states[button] = mouse.states.down
  states.alt = alt
  states.ctrl = ctrl
  states.shift = shift

  local lx, ly = CEL.pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap
  local trigger = {false}

  event:ontrackmouse('down', button, lx, ly, trigger)

  while target do
    if not target[_disabled] then event:onmousedown(target, button, lx, ly, trigger) end
    lx = lx + target[_x]
    ly = ly + target[_y]
    target = target[_host]
  end
  event:signal()

end

function driver.mouseup(x, y, button, alt, ctrl, shift)
  if button == nil then return end --protect against bad input

  driver.mousemove(x,y)
  event:wait()

  local states = mouse[_states]
  states[button] = mouse.states.normal 
  states.alt = alt
  states.ctrl = ctrl
  states.shift = shift

  local lx, ly = CEL.pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap
  local trigger = {false}

  event:ontrackmouse('up', button, lx, ly, trigger)

  while target do
    if not target[_disabled] then event:onmouseup(target, button, lx, ly, trigger) end
    lx = lx + target[_x]
    ly = ly + target[_y]
    target = target[_host]
  end
  event:signal()

end

--direction is 'up' or 'down'
function driver.mousewheel(x, y, direction, lines)
  driver.mousemove(x,y)
  event:wait()
  local lx, ly = CEL.pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap
  local trigger = {false}

  event:ontrackmouse('wheel', direction, lx, ly, trigger)

  while target do
    if not target[_disabled] then event:onmousewheel(target, direction, lx, ly, trigger) end
       
    lx = lx + target[_x]
    ly = ly + target[_y]
    target = target[_host]
  end

  event:signal()
end

function driver.keydown(key, alt, ctrl, shift)
  if key == nil then return end --protect against bad input

  event:wait()

  keyboard[_keys][key] = key

  local device_focus = keyboard[_focus]
  local focus = device_focus[device_focus.n]
  local trigger = {false}

  if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
    if focus then
      while focus do
        --TODO don't use same trigger for keydown and keypress, or maybe it is good to do that
        event:onkeydown(focus, key, trigger)
        focus = focus[_host]
      end
    else
      --event:onkeydown( the current modal cel, key)
    end
  end

  event:signal()
end

function driver.keypress(key, alt, ctrl, shift)
  if key == nil then return end --protect against bad input

  event:wait()

  keyboard[_keys][key] = key

  local device_focus = keyboard[_focus]
  local focus = device_focus[device_focus.n]
  local trigger = {false}

  if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
    if focus then
      while focus do
        event:onkeypress(focus, key, trigger)
        focus = focus[_host]
      end
    else
      --event:onkeydown( the current modal cel, key)
    end
  end

  event:signal()
end

function driver.keyup(key, alt, ctrl, shift)
  if key == nil then return end --protect against bad input

  event:wait()

  keyboard[_keys][key] = nil

  local device_focus = keyboard[_focus]
  local focus = device_focus[device_focus.n]
  local trigger = {false}

  if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
    if focus then
      while focus do
        event:onkeyup(focus, key, trigger)
        focus = focus[_host]
      end
    else
      --event:onkeyup( the current modal cel, key)
    end
  end

  event:signal()
end

function driver.char(char)
  if char == nil then return end --protect against bad input

  event:wait()

  local device_focus = keyboard[_focus]
  local focus = device_focus[device_focus.n]
  local trigger = {false}

  if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
    if focus then
      while focus do
        event:onchar(focus, char, trigger)
        focus = focus[_host]
      end
    else
      --  event:onchar(the current modal cel, char, trigger)
    end
  end

  event:signal()
end

function driver.command(command, data)
  event:wait()

  local device_focus = keyboard[_focus]
  local focus = device_focus[device_focus.n]
  local trigger = {false}

  if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
    if focus then
      while focus do
        event:oncommand(focus, command, data, trigger)
        focus = focus[_host]
      end
    else
      --  event:oncommand(the current modal cel, char, trigger)
    end
  end

  event:signal()
end

function driver.descriptionchanged()
  return CEL.root[_refresh] and true or false
end

function driver.changecursor(cursor)
  --noop driver must implement this function and change the systems cursor
end

function driver.option(opt, value)
  if opt == 'cachedescriptions' then
    CEL.usedescriptioncache = value
  end
end
