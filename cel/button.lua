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

local _pressed = {} 
local _holding = {} 
local metacel, metatable = cel.newmetacel('button')

function metatable.ispressed(button)
  return button[_pressed] and true or false
end

function metacel:__describe(button, t)
  t.pressed = button[_pressed]
end

function metacel:onmouseout(button)
  if button[_pressed] == 1 then
    button[_pressed] = nil
  end
end

local function ontrapfailed(button)
  if button[_pressed] == 2 then
    button[_pressed] = 1
  end
  button:refresh()
end

function metacel:onmousedown(button, mousebutton, x, y, intercepted)
  if intercepted then return end

  button[_pressed] = 2

  if button.onpress then button:onpress(mousebutton, x, y) end

  button:trapmouse(ontrapfailed)
  if button.onhold then
    button[_holding] = cel.timer()
  end

  button:refresh()
  return true
end

function metacel:onmouseup(button, mousebutton, x, y, intercepted)
  --if intercepted then return end

  button:freemouse()
  if button[_pressed] and button.mouse:incel(button) and 1 == button:hasfocus(cel.mouse) then
    button[_pressed] = nil 
    button:refresh()
    if button.onclick then button:onclick(mousebutton, x, y) end
  else
    button[_pressed] = nil 
    button:refresh()
  end

  
  return true
end

function metacel:ontimer(button, ms)
  if button[_holding] then
    if not button[_pressed] then
      button[_holding] = nil
      return
    end

    local duration = ms - button[_holding]

    if duration < 500 then
      return
    else
      button[_holding] = ms - duration + 20 --wait 20 ms to fire again
    end

    if button.onhold and button.mouse:incel(button) then
      button:onhold()
    end
  end
end

do
  local _new = metacel.new
  function metacel:new(w, h, face, minw, maxw, minh, maxh)
    face = self:getface(face)
    return _new(self, w, h, face, minw, maxw, minh, maxh)
  end

  local _compile = metacel.compile
  function metacel:compile(t, button)
    button = button or metacel:new(t.w, t.h, t.face)
    button.onclick = t.onclick
    button.onpress = t.onpress
    button.onhold = t.onhold
    return _compile(self, t, button)
  end
end

return metacel:newfactory()

