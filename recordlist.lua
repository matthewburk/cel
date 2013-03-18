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

local metarecordlist, recordlistmt = cel.listbox.newmetacel('recordlist')

function recordlistmt:setcolheader()
  return self
end

function recordlistmt:setrowheader()
  return self
end

function recordlistmt:setcoloptions(index, minw, maxw, flex)
  return self
end

function recordlistmt:addrecord(record)
  local row = cel.row.new()

  for i=1, #record do
    tocel(record[i], self):link(row, self:getcolprops(i))
  end

  row:link(self, 'width')
  return self
end

do
  local _new = metarecordlist.new
  function metarecordlist:new(coloptions, face) --TODO don't need to define this, just let it pass to slot
    face = self:getface(face)
    local recordlist = _new(self, gap, face)
    recordlist[_rows] = {}
    return recordlist
  end

  local _assemble = metarecordlist.assemble
  function metarecordlist:assemble(t, recordlist)
    return _assemble(self, t, recordlist or metarecordlist:new(t.gap, t.face))
  end

  function metarecordlist:assembleentry(recordlist, entry, entrytype)
    if 'table' == entrytype then
      local linker, xval, yval

      if entry.link then
        if type(entry.link) == 'table' then
          linker, xval, yval = unpack(entry.link, 1, 3)
        else
          linker = entry.link
        end
      end

      for i = 1, #entry do
        local link = cel.tocel(entry[i], recordlist)
        if link then
          if not entry.link then
            linker, xval, yval = link:pget('linker', 'xval', 'yval')
          end
          if not (linker or xval or yval) then
          end
          link:link(recordlist, linker, xval, yval, entry)
        end
      end 
    end
  end
end

return metarecordlist:newfactory()


