--[[
cel is licensed under the terms of the MIT license

Copyright (C) 2011-2103 by Matthew W. Burk

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

local metacel, mt = cel.slot.newmetacel('accordion')

local _current = {}
local _list = {}

local layout = {
}

do --mt.minimize
  function mt:minimize()
    self[_list]:resize(nil, 0)
    return self
  end
end

do --mt.add
  local linkoption = { minh=0, maxh=0 }

  function mt:add(header, content)
    assert(header)
    assert(content)
    local list = self[_list]

    header:link(list, 'width')
    content:link(list, 'width', nil, nil, linkoption)
    return self
  end
end

do
  local function transition(list, maximize, minimize, p)
    if maximize then
      list:setslotflexandlimits(maximize, 0, maximize.minh*p, maximize.minh*p)
    end
    if minimize then
      list:setslotflexandlimits(minimize, 0, 0, minimize.h - minimize.h*p)
    end
  end

  local function transitionfinal(list, maximize, minimize)
    if maximize then
      list:setslotflexandlimits(maximize, 0, true, true)
    end
    if minimize then
      list:setslotflexandlimits(minimize, 0, 0, 0)
    end
    --list:resize(nil, 0)
  end

  --TODO do not allow selet or toggle select while flowing
  function mt:select(header)
    local list = self[_list]

    if header ~= self[_current] and (list:indexof(header) or 0) % 2 == 1 then      
      local content = list:next(header)

      local maximize = content
      local minimize = self[_current] and list:next(self[_current])

      self[_current] = header

      self:flowvalue(self:getflow('transition'), 0, 1, function(self, p)
        list:flux(transition, list, maximize, minimize, p)
      end, 
      function()
        list:flux(transitionfinal, list, maximize, minimize)
      end)

    end

    return self
  end

  function mt:toggleselect(header)
    if header == self[_current] then
      local list = self[_list]
      local minimize = self[_current] and list:next(self[_current])
      local maximize = nil

      self:flowvalue(self:getflow('transition'), 0, 1, function(self, p)
        list:flux(transition, list, maximize, minimize, p)
      end, 
      function()
        list:flux(transitionfinal, list, maximize, minimize)
      end)

      self[_current] = false
      return self
    else
      return self:select(header)
    end
  end
end

do
  local _new = metacel.new
  function metacel:new(face)
    face = self:getface(face)
    local layout = face.layout or layout
    local accordion = _new(self, face)
    accordion[_list] = cel.col.new(0):link(accordion, 'width')
    return accordion
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, accordion)
    accordion = accordion or metacel:new(t.face)
    return _assemble(self, t, accordion)
  end

  local _assembleentry = metacel.assembleentry
  function metacel:assembleentry(accordion, entry, entrytype)
    if 'table' == entrytype and entry.header and entry.content then
      accordion:add(entry.header, entry.content)
    else
      _assembleentry(self, accordion, entry, entrytype)
    end
  end
end

return metacel:newfactory()
