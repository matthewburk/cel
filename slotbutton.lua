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

local metacel, metatable = cel.slot.newmetacel('slotbutton')
local metabutton = cel.button.newmetacel('slotbutton.proxybutton')

metacel.onmouseout = metabutton.onmouseout
metacel.onmousedown = metabutton.onmousedown
metacel.onmouseup = metabutton.onmouseup
metacel.ontimer = metabutton.ontimer

do 
  local __describe = metacel.__describe
  function metacel:__describe(slotbutton, t)
    metabutton:__describe(slotbutton, t)
    return __describe and __describe(self, slotbutton, t)
  end
end

do 
  local _new = metacel.new
  function metacel:new(face, l, t, r, b, minw, minh)
    face = self:getface(face)
    local slotbutton = _new(self, face, l, t, r, b, minw, minh)
    return slotbutton               
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, slotbutton)
    slotbutton = slotbutton or metacel:new(t.face) --TODO margins
    slotbutton.onclick = t.onclick
    slotbutton.onpress = t.onpress
    slotbutton.onhold = t.onhold
    return _assemble(self, t, slotbutton)
  end
end

return metacel:newfactory()

