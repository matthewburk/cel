--[[
cel is licensed under the terms of the MIT license

Copyright (C) 2011-2012 by Matthew W. Burk

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

local metacel, mt = cel.newmetacel('picklist')

function mt.step(picklist, xsteps, ysteps, mode)
  picklist[_subject]:endflow(picklist:getflow('scroll'))      
  local xdim = picklist[_xdim]
  local ydim = picklist[_ydim]
  local x, y = xdim.value, ydim.value

  if mode == nil or mode == 'line' then
    if xsteps and xsteps ~= 0 then x = x + (xsteps * picklist.stepsize) end
    if ysteps and ysteps ~= 0 then y = y + (ysteps * picklist.stepsize) end
  elseif mode == 'page' then
    if xsteps and xsteps ~= 0 then x = x + (xsteps * xdim.size) end
    if ysteps and ysteps ~= 0 then y = y + (ysteps * ydim.size) end
  end

  return picklist:picklist(x, y)
end

function metacel:__link(picklist, link, linker, xval, yval, option)
  if 'raw' ~= option then
    return picklist[_list], linker, xval, yval, option 
  end
end

do
  local _new = metacel.new
  function metacel:new(face)
    face = self:getface(face)
    local picklist = _new(self, 0, 0, face)

    picklist[_list] = cel.col.new()
      :link(picklist, 'scroll', true, false, 'raw') 

    return picklist
  end
end

return metacel:newfactory()
