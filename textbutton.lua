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

local metacel, metatable = cel.text.newmetacel('textbutton')
local metabutton = cel.button.newmetacel('textbutton.proxybutton')

local layout = {
  padding = {
    fit = 'default',
    fitx = 'default',
    fity = 'default',
    l = 2,
    t = 2,
  },
}

metacel.onmouseout = metabutton.onmouseout
metacel.onmousedown = metabutton.onmousedown
metacel.onmouseup = metabutton.onmouseup
metacel.ontimer = metabutton.ontimer

metatable.setstate = metabutton.metatable.setstate
metatable.getstate = metabutton.metatable.getstate
do 
  local __describe = metacel.__describe
  function metacel:__describe(textbutton, t)
    metabutton:__describe(textbutton, t)
    __describe(self, textbutton, t)
  end
end

--maxw/maxh cannot be set because the cel must be grow to accomodate text
function metacel:__setlimits(textbutton, minw, maxw, minh, maxh)
  return minw, nil, minh, nil
end

function metatable.__tostring(textbutton)
  return 'textbutton[' .. textbutton:gettext() .. ']'
end

do 
  local _new = metacel.new
  function metacel:new(text, face)
    face = self:getface(face)
    local textbutton = _new(self, text, face):justify('center')
    return textbutton               
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, textbutton)
    textbutton = textbutton or metacel:new(t.text, t.face)
    textbutton.onclick = t.onclick
    textbutton.onpress = t.onpress
    textbutton.onhold = t.onhold
    return _assemble(self, t, textbutton)
  end
end

return metacel:newfactory({layout = layout})

