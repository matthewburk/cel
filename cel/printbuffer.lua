local cel = require 'cel'
local metacel, metatable = cel.listbox.newmetacel('printbuffer')
local _buffer = {}
local _buffersize = {}
local _font = {}
local _labelface = {}

do
  local newlabel = cel.text.new
  function metatable.print(self, ...)
    local out = {}
    local runlen = 0
    for k, s in ipairs{...} do
      s = tostring(s)
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

    if self:len() > 500  then
      self:remove(1)
    end
    newlabel(text, self[_labelface]):link(self, 'width')
    self:scrollto(0, math.huge) --TODO fix this, it should not scroll off teh end of eh subject
  end

  local function printdescription(self, t, indent)
    if #t > 0 then
      self:print(string.format('%s%d %s[%s] {x:%d y:%d w:%d h:%d id:%s [l:%d t:%d r:%d b:%d]',
                 indent, t.id, t.metacel, tostring(t.face[_name]) or t.metacel, t.x, t.y, t.w, t.h, tostring(t.id),
                 t.clip.l, t.clip.t, t.clip.r, t.clip.b)) 
      local subindent = indent .. '  '
      for i = #t,1,-1 do
        printdescription(self, t[i], subindent)  
      end
      self:print(indent .. '}') 
    else
      self:print(string.format('%s%d %s[%s] {x:%d y:%d w:%d h:%d id:%s [l:%d t:%d r:%d b:%d]}',
                 indent, t.id, t.metacel, tostring(t.face[_name]) or t.metacel, t.x, t.y, t.w, t.h, tostring(t.id),
                 t.clip.l, t.clip.t, t.clip.r, t.clip.b))
    end
  end

  function metatable.printdescription(self)
    printdescription(self, cel.getdescription(), '')
  end
end

do
  local _new = metacel.new
  function metacel:new(w, h, face)
    face = self:getface(face)

    local printbuffer = _new(self, w, h, face)
    printbuffer[_font] = face.font
    printbuffer[_labelface] = cel.face {
      metacel = 'text',
      name = printbuffer[_buffer],
      font = printbuffer[_font],
      textcolor = cel.color.rgb(0, 0, 0),
    }
    return printbuffer
  end
end

return metacel:newfactory()
