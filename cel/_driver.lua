return function(_ENV, M)
setfenv(1, _ENV)
local mouse = mouse
local keyboard = keyboard

driver = {} --ENV.driver

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
      if task.action then
        task.next = nil
        event:task(task)
      end
    else
      break
    end
  end
end
do --driver.timer
local mark = 0
function driver.timer(ms)
  local elapsed = ms - timer.millis 
  timer.millis = ms

  if ms - mark > 10 then
    mark = ms
  else
    return
  end

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

  mouse.motion = true

  mouse[_vectorx] = x - mouse[_x]
  mouse[_vectory] = y - mouse[_y]
  mouse[_x] = x
  mouse[_y] = y

  --lx and ly are x and y translated into mouse[_focus] coordinates
  local lx, ly = pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap

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
  driver.mousemove(x,y)
  event:wait()

  local buttonstates = mouse[_buttonstates]
  buttonstates[button] = mouse.buttonstates.down
  buttonstates.alt = alt
  buttonstates.ctrl = ctrl
  buttonstates.shift = shift

  local lx, ly = pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap
  local trigger = {false}

  while target do
    if not target[_disabled] then event:onmousedown(target, button, lx, ly, trigger) end
    lx = lx + target[_x]
    ly = ly + target[_y]
    target = target[_host]
  end
  event:signal()

end

function driver.mouseup(x, y, button, alt, ctrl, shift)
  driver.mousemove(x,y)
  event:wait()

  local buttonstates = mouse[_buttonstates]
  buttonstates[button] = mouse.buttonstates.normal 
  buttonstates.alt = alt
  buttonstates.ctrl = ctrl
  buttonstates.shift = shift

  local lx, ly = pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap
  local trigger = {false}

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
  local lx, ly = pick(mouse)
  local target = mouse[_focus].focus or mouse[_trap].trap
  local trigger = {false}

  while target do
    if not target[_disabled] then event:onmousewheel(target, direction, lx, ly, trigger) end
       
    lx = lx + target[_x]
    ly = ly + target[_y]
    target = target[_host]
  end

  event:signal()
end

function driver.keydown(key, alt, ctrl, shift)
  event:wait()

  keyboard[_keystates][key] = keyboard.keystates.down
  keyboard[_keys][key] = key

  local device_focus = keyboard[_focus]
  local focus = device_focus[device_focus.n]
  local trigger = {false}

  if type(focus) == 'table' then --this is a lame hack, shouldn't ahve to do this fix it
    if focus then
      while focus do
        --TODO don't use same trigger for keydown and keypress, or maybe it is good to do that
        event:onkeydown(focus, key, trigger)
        event:onkeypress(focus, key, trigger)
        focus = focus[_host]
      end
    else
      --event:onkeydown( the current modal cel, key)
    end
  end

  event:signal()
end

function driver.keypress(key, alt, ctrl, shift)
  event:wait()

  keyboard[_keystates][key] = keyboard.keystates.down
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
  event:wait()

  keyboard[_keystates][key] = keyboard.keystates.normal
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

function driver.changecursor(cursor)
  --noop driver must implement this function and change the systems cursor
end

return driver
end

