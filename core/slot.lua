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
local M = require 'cel.core.module'
local _ENV = require 'cel.core.env'
setfenv(1, _ENV)

local mouse = require('cel.core.mouse')
local keyboard = require('cel.core.keyboard')

local _margin = {}
local _slotlink = {}
local _defaultminw = {}
local _defaultminh = {}

local slotformation = {}
local math = math
local table = table
local stackformation = stackformation
local rawget = rawget

local function slotlinker(hw, hh, x, y, w, h)
  return x, y, w, h
end

slotformation.links = stackformation.links

do --slotformation.getbraceedges
  local math = math
  function slotformation:getbraceedges(host, link, linker, xval, yval)
    if not linker then
      return link[_x] + link[_w], link[_y] + link[_h]
    else
      local minw, maxw = link[_minw] or 0, link[_maxw] or maxdim
      local minh, maxh = link[_minh] or 0, link[_maxh] or maxdim
      local x, y, w, h = linker(0, 0, link[_x], link[_y], link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

      if w < minw then w = minw end
      if w > maxw then w = maxw end
      if h < minh then h = minh end
      if h > maxh then h = maxh end

      x = math.modf(x)
      w = math.floor(w)
      y = math.modf(y)
      h = math.floor(h)

      return math.max(x + w, w, -x), math.max(y + h, h, -y)
    end
  end
end

do --slotformation.link
  function slotformation:link(host, link, linker, xval, yval, option)
    if option == 'slot' or not host[_slotlink] then
      host[_slotlink] = link
      option = 'slot'
    else
      return stackformation:link(host, link, linker, xval, yval, option)
    end

    event:onlink(host, link)

    local edgex, edgey = self:getbraceedges(host, link, linker, xval, yval)
    local minw = math.max(edgex + host[_margin].w, host[_defaultminw])
    local minh = math.max(edgey + host[_margin].h, host[_defaultminh])

    if minw ~= host[_minw] or minh ~= host[_minh] then
      host:setlimits(minw, host[_maxw], minh, host[_maxh])
    end

    host:resize(host[_margin].w + link[_w], host[_margin].h + link[_h])

    link[_next] = rawget(host, _links)
    link[_prev] = nil
    host[_links] = link

    if link[_next] then 
      link[_next][_prev] = link 
    end

    if not linker then
      linker = slotlinker
    else
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
    end

    self:dolinker(host, link, linker, xval, yval) --assigns _x and _y
  end
end
--[[
do --slotformation.moved
  --called anytime host is moved by any method
  local _linker, _xval, _yval = _linker, _xval, _yval
  function slotformation:moved(host, x, y, w, h, ox, oy, ow, oh)
    if h ~= oh or w ~= ow then
      event:onresize(host, ow, oh)
      local slotlink = host[_slotlink]
      for link in links(host) do
        if link == slotlink or rawget(link, _linker) then
          self:dolinker(host, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
        end
      end
      if host[_metacel].__resize then
        host[_metacel]:__resize(host, ow, oh)
      end
    end
  end
end
--]]

do --slotformation.testlinker --TODO need to pass option to testlinker and reroute this to stacklinker
  local math = math
  function slotformation:testlinker(host, link, linker, xval, yval)
    if link ~= host[_slotlink] then
      return stackformation:testlinker(host, link, linker, xval, yval)
    end

    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    return self:linker(host, link, ox, oy, ow, oh, linker, xval, yval, 
                       rawget(link, _minw) or 0, rawget(link, _maxw) or maxdim,
                       rawget(link, _minh) or 0, rawget(link, _maxh) or maxdim)
  end
end

do --slotformation.dolinker
  --called anytime the link[_linker] needs to be enforced
  local celmoved = celmoved
  function slotformation:dolinker(host, link, linker, xval, yval)
    if link ~= host[_slotlink] then
      return stackformation:dolinker(host, link, linker, xval, yval)
    end

    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local x, y, w, h = self:linker(host, link, ox, oy, ow, oh, linker, xval, yval, 
                                   rawget(link, _minw) or 0, rawget(link, _maxw) or maxdim,
                                   rawget(link, _minh) or 0, rawget(link, _maxh) or maxdim)

    link[_x] = x
    link[_y] = y
    link[_w] = w
    link[_h] = h

    if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
      celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
    end
  end
end

do --slotformation.linklimitschanged
  function slotformation:linklimitschanged(host, link, ominw, omaxw, ominh, omaxh)
    if link ~= host[_slotlink] then
      return
    end

    local margin = host[_margin]
    local w = margin.w
    local h = margin.h

    local minw = math.max((link[_minw] or 0) + margin.w, host[_defaultminw])
    local minh = math.max((link[_minh] or 0) + margin.h, host[_defaultminh])

    --TODO this will break if adding margin exceeds maxdim
    host:setlimits(minw, host[_maxw], minh, host[_maxh])
  end
end

do --slotformation.linker
  function slotformation:linker(host, link, x, y, w, h, linker, xval, yval, minw, maxw, minh, maxh)
    local margin = host[_margin]
    local hw = host[_w] - margin.w
    local hh = host[_h] - margin.h

    maxw = math.min(hw, maxw)
    maxh = math.min(hh, maxh)

    if linker then
      x, y, w, h = linker(hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)
    end

    x = math.modf(x)
    y = math.modf(y)
    w = math.floor(w)
    h = math.floor(h)

    --enforce min/max
    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end

    if x < 0 then 
      x = 0 
    elseif x + w > hw then
      x = hw - w
    end

    if y < 0 then 
      y = 0 
    elseif y + h > hh then
      y = hh - h
    end

    x = x + margin.l
    y = y + margin.t

    return x, y, w, h 
  end
end

do --slotformation.movelink
  --movelink should only be called becuase move was explicitly called, make sure that is the case
  local math = math
  function slotformation:movelink(host, link, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)
    if link ~= host[_slotlink] then
      return stackformation:movelink(host, link, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)
    end

    local margin = host[_margin]

    if rawget(link, _linker) then
      local linker = link[_linker]
      local xval = rawget(link, _xval)
      local yval = rawget(link, _yval)
      local hw = host[_w] - margin.w
      local hh = host[_h] - margin.h

      x, y, w, h = linker(hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)

      x = math.modf(x)
      y = math.modf(y)
      w = math.floor(w)
      h = math.floor(h)

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end
      if h < minh then h = minh end

    end

    event:wait()

    --TODO do this, like in seuqence
    --local edgex, edgey = self:getbraceedges(host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

    if w ~= ow or h ~= oh then
      --TODO removed becuase it looks like it does nothinglocal linker, xval, yval = rawget(host, _linker), rawget(host, _xval), rawget(host, _yval)
      --TODO removed becuase it looks like it does nothing host:relink() --this is to make slot size to subject even if the slot is constrained by linker, like in a sequence
      host:resize(w + margin.w, h + margin.h) 
      --TODO removed because it looks like it does nothing host:relink(linker, xval, yval)
      --TODO to make a super tight fit force maxw/h to same value as w/h 
    end 

    x, y, w, h = self:linker(host, link, x, y, w, h, rawget(link, _linker), 
                             rawget(link, _xval), rawget(link, _yval), minw, maxw, minh, maxh)

    link[_x] = x
    link[_y] = y
    link[_w] = w
    link[_h] = h
  
    if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
      celmoved(host, link, x, y, w, h, ox, oy, ow, oh)  
    end

    event:signal()

    return link
  end
end

do --slotformation.unlink
  local math = math
  function slotformation:unlink(host, link)
    if link ~= host[_slotlink] then
      return stackformation:unlink(host, link)
    end

    local margin = host[_margin]
    local w = margin.w
    local h = margin.h

    host[_slotlink] = false
    stackformation:unlink(host, link)

    host:setlimits(w, host[_maxw], h, host[_maxh])
    host:resize(0, 0)
  end
end

do --slotformation.describelinks
  slotformation.describelinks = stackformation.describelinks
end

local metacel, metatable = metacel:newmetacel('slot')

do
  function metatable:setmargins(l, t, r, b)
    l = l or 0
    t = t or l
    r = r or l
    b = b or t

    local margin = self[_margin]
    local minw = self[_defaultminw]
    local minh = self[_defaultminh]
    self[_minw] = math.max(l + r, minw or 0) --TODO set in assemble
    self[_minh] = math.max(t + b, minh or 0) --TODO set in assemble
    margin.l = l
    margin.r = r
    margin.t = t
    margin.b = b
    margin.w = l + r
    margin.h = t + b

    local link = rawget(slot, _slotlink)
    if link then
      local edgex, edgey = slotformation:getbraceedges(self, link, link.linker, link.xval, link.yval)
      local minw = math.max(edgex + margin.w, self[_defaultminw])
      local minh = math.max(edgey + margin.h, self[_defaultminh])

      if minw ~= self[_minw] or minh ~= self[_minh] then
        self:setlimits(minw, self[_maxw], minh, self[_maxh])
      end

      return self:resize(margin.w + link[_w], margin.h + link[_h])
    else
      return self:resize(0, 0)
    end
  end
end

do --metatable.get
  function metatable.getsubject(slot)
    return rawget(slot, _slotlink) or nil
  end
end

do --metacel.new, metacel.assemble
  local math = math

  local _new = metacel.new
  function metacel:new(face, l, t, r, b, minw, minh)
    face = self:getface(face)
    l = math.max(0, math.floor(l or 0))
    t = math.max(0, math.floor(t or 0))
    r = math.max(0, math.floor(r or l))
    b = math.max(0, math.floor(b or t))

    local slot = _new(self, 0, 0, face) --add minw, minh
    slot[_defaultminw] = minw or 0
    slot[_defaultminh] = minh or 0
    slot[_minw] = math.max(l + r, minw or 0) --TODO set in assemble
    slot[_minh] = math.max(t + b, minh or 0) --TODO set in assemble
    slot[_margin] = {l = l, t = t, r = r, b = b, w = l + r, h = t + b}
    slot[_formation] = slotformation
    slot[_slotlink] = false 

    return slot
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, slot)
    local margin = t.margin
    if margin then
      slot = slot or metacel:new(t.face, margin.l, margin.t, margin.r, margin.b, t.minw, t.minh)
    else
      slot = slot or metacel:new(t.face, 0, 0, 0, 0, t.minw, t.minh)
    end
    _assemble(self, t, slot)
    return slot
  end
end

return metacel:newfactory() 
