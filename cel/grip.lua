local cel = require 'cel'
local mouse = cel.mouse

local metacel, metatable = cel.newmetacel('grip')
local _grabbedat = {}
local _target = {}
local _mode = {}

function metatable.isgrabbed(grip)
  return grip[_grabbedat] ~= nil
end

local modes = {}

function modes.top(grip, x, y)
  local target = grip[_target]
  local h = target.h
  local minh = target.minh

  if y > 0 and h > minh then
    if h - y < minh then y = h - minh end
  elseif y > 0 then
    y = 0
  end

  target:moveby(0, y, 0, -y)
  mouse:pick()
end

function modes.sync(grip, x, y)
  grip[_target]:moveby(x, y)
  mouse:pick()
end

function modes.bottom(grip, x, y)
  grip[_target]:moveby(0, 0, 0, y)
  mouse:pick()
end

function modes.left(grip, x, y)
  local target = grip[_target]
  local w = target.w
  local minw, maxw = target.minw, target.maxw

  if minw == maxw then return end
  --TODO evaluate all the modes, they don't work well with limits in place
  if w > minw and x > 0 then
    if w - x < minw then x = w - minw end
  elseif x > 0 then
    x = 0
  end

  target:moveby(x, 0, -x, 0)
  mouse:pick()
end

function modes.right(grip, x, y)
  grip[_target]:moveby(0, 0, x, 0)
  mouse:pick()
end

function modes.bottomright(grip, x, y)
  grip[_target]:moveby(0, 0, x, y)
  mouse:pick()
end

function modes.topright(grip, x, y)
  local target = grip[_target]
  local minh = target.minh
  local h = target.h

  if y > 0 and h > minh then
    if h - y < minh then y = h - minh end
  elseif y > 0 then
    y = 0
  end

  target:moveby(0, y, x, -y)
  mouse:pick()
end

function modes.bottomleft(grip, x, y)
  local target = grip[_target]
  local minw = target.minw
  local w = target.w

  if x > 0 and w > minw then
    if w - x < minw then x = w - minw end
  elseif x > 0 then
    x = 0
  end

  target:moveby(x, 0, -x, y)
  mouse:pick()
end

function modes.topleft(grip, x, y)
  local target = grip[_target]
  local w = target.w
  local h = target.h
  local minw, minh = target.minw, target.minh

  if y > 0 and h > minh then
    if h - y < minh then y = h - minh end
  elseif y > 0 then
    y = 0
  end

  if w > minw and x > 0 then
    if w - x < minw then x = w - minw end
  elseif x > 0 then
    x = 0
  end

  target:moveby(x, y, -x, -y)
  mouse:pick()
end

function metatable.grip(grip, cel, mode)
  grip[_target] = cel
  grip[_mode] = modes[mode or 'sync']
  return grip
end

function metatable.getgrip(grip)
  return grip[_target]
end

function metacel:__describe(grip, properties)
  properties.grabbed = grip[_grabbedat] ~= nil
end

local function ontrapfailed(grip, mouse, reason)
  grip[_grabbedat] = nil 
  grip:refresh()
end

function metacel:onmousedown(grip, button, x, y, intercepted)
  if intercepted then return end
  if button ~= mouse.buttons.left then return end

  grip[_grabbedat] = {x,y}
  grip:trapmouse(ontrapfailed)

  if grip.ongrab and grip[_grabbedat] then 
    grip:ongrab(button, x, y) 
  end

  grip:refresh()

  return true
end

function metacel:onmouseup(grip, button, x, y, intercepted)
  if button ~= mouse.buttons.left then return end

  if grip[_grabbedat] and grip.onrelease then 
    grip:onrelease(button, x, y) 
  end

  grip:freemouse()

  return true
end

function metacel:onmousemove(grip, x, y)
  local vec = grip[_grabbedat]

  if vec then
    x = x - vec[1]
    y = y - vec[2]

    if grip[_target] then
      grip[_mode](grip, x, y)
    end

    if grip.ondrag then 
      grip:ondrag(x, y) 
      --TODO only pick if global position of grip actually changes or its width or height
      mouse:pick()
    end
  end
end

do
  local _new = metacel.new
  function metacel:new(w, h, face)
    return _new(self, w, h, self:getface(face))
  end

  local _compile = metacel.compile
  function metacel:compile(t, grip)
    grip = grip or metacel:new(t.w, t.h, t.face)
    grip.ongrab = t.ongrab
    grip.ondrag = t.ondrag

    if t.grip then
      grip:grip(t.grip, t.mode)
    end

    return _compile(self, t, grip)
  end
end

return metacel:newfactory()

