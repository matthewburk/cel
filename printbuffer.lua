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
local metacel, metatable = cel.scroll.newmetacel('printbuffer')
local _buffersize = {}

do
  local textface = cel.getface('text'):new {
    font=cel.loadfont('code')
  }

  local newlabel = cel.text.new
  function metatable.print(self, ...)
    local out = {}
    local runlen = 0
    for k, s in ipairs{...} do
      s = tostring(s)
      s = cel.isutf8(s) and s or string.rep('#', #s)
      local len = s:len()
      runlen = runlen + len

      local adjust = 8 - runlen % 8
      if adjust == 0 then adjust = 8 end
      local pad = string.rep(' ', adjust)

      out[#out + 1] = s
      out[#out + 1] = pad 

      runlen = runlen + adjust
    end
    local text = table.concat(out)

    if self.list:len() > self[_buffersize]  then
      self.list:remove(1)
    end
    newlabel(text, textface):link(self.list, 'width')
    self:scrollto(0, math.huge)
  end

  local function printdescription(self, t, indent)
    if #t > 0 then
      self:print(string.format('%s%d %s[%s] {x:%d y:%d w:%d h:%d id:%s [l:%d t:%d r:%d b:%d]',
                 indent, t.id, t.metacel or 'virtual', tostring(t.face[_name]) or t.metacel or '', t.x, t.y, t.w, t.h, tostring(t.id),
                 t.clip.l, t.clip.t, t.clip.r, t.clip.b)) 
      local subindent = indent .. '  '
      for i = #t,1,-1 do
        printdescription(self, t[i], subindent)  
      end
      self:print(indent .. '}') 
    else
      self:print(string.format('%s%d %s[%s] {x:%d y:%d w:%d h:%d id:%s [l:%d t:%d r:%d b:%d]}',
                 indent, t.id, t.metacel or 'virtual', tostring(t.face[_name]) or t.metacel or '', t.x, t.y, t.w, t.h, tostring(t.id),
                 t.clip.l, t.clip.t, t.clip.r, t.clip.b))
    end
  end

  function metatable.printdescription(self)
    printdescription(self, (cel.describe()), '')
  end
end

function metatable:setbuffersize(size)
  local excess = self:len() - size
  self[_buffersize] = size

  if excess > 0 then
    self.list:flux(function()
      for i = 1, excess do
        self.list:remove(1)    
      end
    end)
  end
end

do
  local _new = metacel.new
  function metacel:new(w, h, face)
    face = self:getface(face)

    local printbuffer = _new(self, w, h, face)
    printbuffer.list = cel.list.new()
      :link(printbuffer, 'fill')

    printbuffer[_buffersize] = 200
    return printbuffer
  end
end

return metacel:newfactory()
