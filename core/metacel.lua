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
--
local M = require 'cel.core.module'
local _ENV = require 'cel.core.env'
setfenv(1, _ENV)

local _host = _host
local _links = _links
local _x, _y, _w, _h = _x, _y, _w, _h
local _minw, _maxw, _minh, _maxh = _minw, _maxw, _minh, _maxh
local _metacel = _metacel
local _linker, _xval, _yval = _linker, _xval, _yval
local _formation = _formation
local stackformation = stackformation 
local mouse = require('cel.core.mouse')
local keyboard = require('cel.core.keyboard')

do --ENV.joinlinker
  function joinlinker(hw, hh, x, y, w, h, joinparams1, joinparams2, ...)
    local joinedcel = joinparams1.joinedcel
    local anchor = joinparams1.anchor
    local rx, ry, rw, rh

    if joinedcel[_host] ~= anchor[_host] then
      local ax, ay = M.translate(anchor[_host], anchor[_x], anchor[_y], joinedcel[_host])
      rx, ry, rw, rh = joinparams1.joiner(ax, ay, anchor[_w], anchor[_h], x, y, w, h, joinparams1.xval, joinparams1.yval, ...)
    else
      rx, ry, rw, rh = joinparams1.joiner(anchor[_x], anchor[_y], anchor[_w], anchor[_h], x, y, w, h, joinparams1.xval, joinparams1.yval, ...)
    end

    if joinparams2 then
      --assert(joinedcel == joinparams2.joinedcel)
      anchor = joinparams2.anchor

      if joinedcel[_host] ~= anchor[_host] then
        local ax, ay = M.translate(anchor[_host], anchor[_x], anchor[_y], joinedcel[_host])
        rx, ry, rw, rh = joinparams2.joiner(ax, ay, anchor[_w], anchor[_h], rx, ry, rw, rh, joinparams2.xval, joinparams2.yval, ...)
      else
        rx, ry, rw, rh = joinparams2.joiner(anchor[_x], anchor[_y], anchor[_w], anchor[_h], rx, ry, rw, rh, joinparams2.xval, joinparams2.yval, ...)
      end
    end

    return rx, ry, rw, rh
  end
end

do --ENV.joinanchormoved
  local joinlinker = joinlinker
  function joinanchormoved(joinedcel, anchor)
    local joinparams1 = rawget(joinedcel, _xval)
    local joinparams2 = rawget(joinedcel, _yval)

    if joinparams1.anchor == anchor or (joinparams2 and joinparams2.anchor == anchor) then

      local x, y, w, h = joinlinker(0, 0, joinedcel[_x], joinedcel[_y], joinedcel[_w], joinedcel[_h],
                                    joinparams1, joinparams2,
                                    joinedcel[_minw], joinedcel[_maxw], joinedcel[_minh], joinedcel[_maxh])
      move(joinedcel, x, y, w, h)
    end
  end
end


do --ENV.links
  function links(host)
    local formation = rawget(host, _formation) or stackformation
    return formation:links(host)
  end
end

do --ENV.hosts iterates over all hosts of a cel 
  local _host = _host
  local function nexthost(_, link)
    return rawget(link, _host)
  end
  function hosts(link)
    return nexthost, nil, link 
  end
end

--TODO use a refresh bit on a cel, don't use the refreshtable
do --ENV.refresh
  local _refresh = _refresh
  function refresh(cel)
    local _cel = cel 
    cel[_refresh] = 'full'
    cel = rawget(cel, _host)

    while cel and not cel[_refresh] do
      cel[_refresh] = true 
      cel = rawget(cel, _host)
    end
    return _cel
  end

  function refreshmove(cel, ox, oy, ow, oh)
    cel[_refresh] = 'full'
    cel = rawget(cel, _host)

    if cel then
      refresh(cel)
    end
  end

  function refreshlink(cel, link)
    return refresh(cel)
  end

  function refreshunlink(cel, link)
    return refresh(cel)
  end
end

do --ENV.dolinker
  function dolinker(host, cel, linker, xval, yval)
    return (rawget(host, _formation) or stackformation):dolinker(host, cel, linker, xval, yval)
  end
end


do --ENV.move
  local math = math
  function move(cel, x, y, w, h)
    x, y, w, h = math.modf(x), math.modf(y), math.floor(w), math.floor(h)
    local ox, oy, ow, oh = cel[_x], cel[_y], cel[_w], cel[_h]
    local minw, maxw = cel[_minw], cel[_maxw]
    local minh, maxh = cel[_minh], cel[_maxh]

    --assert(minw)
    --assert(maxw)
    --assert(minh)
    --assert(maxh)
    if w ~= ow or h ~= oh then 
      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end    
      if h < minh then h = minh end
    end

    if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return cel end

    local host = rawget(cel, _host)
    local formation = host and rawget(host, _formation) or stackformation

    --assert(minw)
    local ok = formation:movelink(host, cel, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)

    return cel
  end
end

do --ENV.touch
  function touch(cel, x, y)
    if x < 0 
    or y < 0 
    or x >= cel[_w] 
    or y >= cel[_h] 
    or cel.touch == false 
    or cel[_metacel].touch == false then
      return false
    end

    if cel.touch == true or cel[_metacel].touch == true then
      return true
    end

    if cel.touch ~= touch then
      if not cel:touch(x, y) then
        return false
      end
    elseif cel[_metacel].touch ~= nil and cel[_metacel].touch ~= touch then
      if not cel[_metacel]:touch(cel, x, y) then
        return false
      end
    end

    --cel face can only restrict touch not add to area
    local celface = cel[_face] 
    celface = celface or cel[_metacel][_face]

    if celface.touch ~= nil and celface.touch ~= touch then
      if not celface:touch(x, y, cel[_w], cel[_h]) then
        return false
      end
    end
    
    return true
  end
end

do --ENV.linkall
  function linkall(host, t)
    event:wait()

    local linker = t.link
    local xval, yval, option

    if linker then
      if type(linker) == 'table' then
        linker, xval, yval, option = unpack(linker, 1, 4)
      elseif type(linker) ~= 'function' then
        linker = linkers[linker]
      end
    end

    for i=1, #t do
      local link = t[i]
      local linktype = type(link)

      if linktype == 'function' then
        link(host, t, linker, xval, yval, option)
      elseif linktype == 'string' then
        --TODO __celfromstring should merge with assemble entry
        host[_metacel]:__celfromstring(host, link):link(host, linker, xval, yval, option)
      elseif linktype == 'table' and link[_metacel] then --if link is a cel
        link:link(host, linker, xval, yval, option)
      else
        host[_metacel]:assembleentry(host, link, linktype, linker, xval, yval, option)
      end
    end

    event:signal()
  end
end

do --ENV.describe

  local previous
  local current

  local cache = setmetatable({}, {__mode='kv'})

  local function getdescription(cel)
    local t = cache[cel]
    t = t or {
      host = false,
      id = 0,
      metacel = cel[_metacel][_name],
      face = false,
      x = 0,
      y = 0,
      w = 0,
      h = 0,
      mousefocus = false,
      mousefocusin = false,
      focus = false,
      flowcontext = false,
      refresh = 'full',
      clip = {l=0,t=0,r=0,b=0},
      disabled = false,
    }

    cache[cel]=t
    return t
  end

  local _appstatus = _appstatus

  --describe for all cels
  local function __describe(cel, host, gx, gy, gl, gt, gr, gb, t, fullrefresh)
    t.host = host
    t.id = cel[_celid]
    t.face = cel[_face] or cel[_metacel][_face]
    t.x = cel[_x]
    t.y = cel[_y] 
    t.w = cel[_w]
    t.h = cel[_h]
    t.mousefocus = false
    t.mousefocusin = false
    t.focus = false
    t.flowcontext = flows[cel] and flows[cel].context
    t.refresh = cel[_refresh]
    t.clip.l = gl
    t.clip.t = gt
    t.clip.r = gr
    t.clip.b = gb
    t.appstatus = cel[_appstatus]
    t.disabled = cel[_disabled] or (host and host.disabled and 'host')

    if mouse[_focus][cel] then
      t.mousefocusin = true
      if mouse[_focus].focus == cel then 
        t.mousefocus = true 
      end
    end

    if keyboard[_focus][cel] then
      t.focus = true
      --TODO use number instead of boolean for focus 1 is top n is root 
    end

    if cel[_metacel].__describe then cel[_metacel]:__describe(cel, t) end
  end

  local _hidden = _hidden
  local updaterect = _ENV.updaterect
  function describe(cel, host, gx, gy, gl, gt, gr, gb, fullrefresh)

    gx = gx + cel[_x] --TODO clamp to maxint
    gy = gy + cel[_y] --TODO clamp to maxint

    if gx > gl then gl = gx end
    if gy > gt then gt = gy end

    if gx + cel[_w] < gr then gr = gx + cel[_w] end
    if gy + cel[_h] < gb then gb = gy + cel[_h] end

    if gr <= gl or gb <= gt then return end

    local t = getdescription(cel)

    if fullrefresh or cel[_refresh] or t.refresh then 
      __describe(cel, host, gx, gy, gl, gt, gr, gb, t, fullrefresh)

      fullrefresh = fullrefresh or (t.refresh == 'full' and 'full')

      local formation =  rawget(cel, _formation) or stackformation
      if not cel[_hidden] then
        formation:describelinks(cel, t, gx, gy, gl, gt, gr, gb, fullrefresh)
      end
      if t.refresh == 'full' then
        if gl < updaterect.l then updaterect.l = gl end
        if gt < updaterect.t then updaterect.t = gt end
        if gr > updaterect.r then updaterect.r = gr end
        if gb > updaterect.b then updaterect.b = gb end
      end
    end

    cel[_refresh] = false
    if cel[_hidden] then --TODO this is done so late to allow updaterect to updated, optimize further
      return 
    else 
      return t
    end
  end

  do --stackformation.describelinks
    function stackformation:describelinks(cel, host, gx, gy, gl, gt, gr, gb, fullrefresh)
      local i = 1
      local n = #host
      local link = rawget(cel, _links)
      while link do
        host[i] = describe(link, host, gx, gy, gl, gt, gr, gb, fullrefresh)
        i = host[i] and i + 1 or i
        link = link[_next]
      end
      for i = i, n do
        host[i]=nil
      end
    end
  end
end

do --ENV.celmoved
  --host is the host of the cel that moved, can be nil
  --link is the cel that moved
  local joinlinker = joinlinker
  function celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
    local _link = link
    --assert(link)
    if rawget(link, _formation) and link[_formation].moved then
      link[_formation]:moved(link, x, y, w, h, ox, oy, ow, oh)
    else
      if w ~= ow or h ~= oh then
        event:onresize(link, ow, oh)
        local host = link
        for link in links(host) do
          if rawget(link, _linker) then
            dolinker(host, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
          end
        end
        if link[_metacel].__resize then
          link[_metacel]:__resize(link, ow, oh)
        end
      end

      if joins[link] then  --if this cel is an anchor is a join
        for joinedcel in pairs(joins[link]) do
          if rawget(joinedcel, _linker) == joinlinker then
            --if rawget(joinedcel, _yval) == link then
              joinanchormoved(joinedcel, link) --only if joinedcel is joined to the target, relinking will unjoin but allow the join to reestablish if relinked with 
              --linker, xval and yval that were assigned when it was joined
            --end
          end
        end
      end
    end

    if host then --and not rawget(host, _formation) then
      if host[_metacel].__linkmove then
        host[_metacel]:__linkmove(host, link, ox, oy, ow, oh)
      end
      if host[_metacel].onlinkmove then
        event:onlinkmove(host, link, ox, oy, ow, oh)
      end
    end
    refreshmove(link, ox, oy, ow, oh)
  end
end

do --ENV.islinkedto
  function islinkedto(cel, host)
    --assert(cel)

    if cel == host then
      return nil
    end

    local z = 1
    repeat
      cel = rawget(cel, _host)
      if cel == host then
        return cel and z
      end
      z = z + 1
    until not cel
  end
end

do --
  local _x, _y, _host = _x, _y, _host
  function getX(cel)
    local root = _ENV.root
    local x = 0

    while cel do
      x = x + cel[_x]
      if root == rawget(cel, _host) then
        return x
      end
      cel = rawget(cel, _host)
    end
  end

  function getR(cel)
    local X = getX(cel)
    return X and X + cel[_w] 
  end

  function getY(cel)
    local root = _ENV.root
    local y = 0

    while cel do
      y = y + cel[_y]
      if root == rawget(cel, _host) then
        return y
      end
      cel = rawget(cel, _host)
    end
  end

  function getB(cel)
    local Y = getY(cel)
    return Y and Y + cel[_h] 
  end
end

do --ENV.testlinker
  local math = math

  --TODO need to support option parameter
  function testlinker(cel, host, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
    if linker and type(linker) ~= 'function' then linker = linkers[linker] end

    --TODO this needs to be done in the formation row and col apply rules that limit x and y
    if not linker then return nx or cel[_x], ny or cel[_y], nw or cel[_w], nh or cel[_h] end 

    if host and rawget(host, _formation) then
      return host[_formation]:testlinker(host, cel, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
    else
      local x, y, w, h = nx or cel[_x], ny or cel[_y], nw or cel[_w], nh or cel[_h]
      minw, maxw = minw or cel[_minw], maxw or cel[_maxw]
      minh, maxh = minh or cel[_minh], maxh or cel[_maxh]

      x, y, w, h = linker(host[_w], host[_h], x, y, w, h, xval, yval, minw, maxw, minh, maxh)

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end
      if h < minh then h = minh end

      return math.modf(x), math.modf(y), math.floor(w), math.floor(h)
    end
  end
end

do --stackformation.links
  local function nextlink(host, link)
    if link then
      return link[_next]
    end
    return rawget(host, _links)
  end
  function stackformation:links(host)
    return nextlink, host, nil
  end
end

do --stackformation.dolinker
  function stackformation:dolinker(host, link, linker, xval, yval)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]
    local x, y, w, h = linker(host[_w], host[_h], ox, oy, ow, oh, xval, yval, minw, maxw, minh, maxh)

    --assert(minw)
    --assert(maxw)
    --assert(minh)
    --assert(maxh)

    if w ~= ow or h ~= oh then
      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end
      if h < minh then h = minh end
    end

    if x ~= ox then x = math.modf(x); link[_x] = x; end
    if y ~= oy then y = math.modf(y); link[_y] = y; end
    if w ~= ow then w = math.floor(w); link[_w] = w; end
    if h ~= oh then h = math.floor(h); link[_h] = h; end

    if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
      celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
    end
  end
end

do --stackformation.link
  function stackformation:link(host, link, linker, xval, yval, option)
    link[_next] = rawget(host, _links)
    link[_prev] = nil
    host[_links] = link

    if link[_next] then 
      link[_next][_prev] = link 
    end

    event:onlink(host, link)

    if linker then
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      dolinker(host, link, linker, xval, yval) --assigns _x and _y
    else
      link[_x] = xval
      link[_y] = yval
    end
  end
end

do --stackformation.unlink
  function stackformation:unlink(host, link)
    if link[_next] then
      link[_next][_prev] = link[_prev]
    end

    if rawget(link, _prev) then
      link[_prev][_next] = rawget(link, _next)
    else
      host[_links] = rawget(link, _next)
    end

    link[_next] = nil
    link[_prev] = nil

    if host[_metacel].__unlink then
      host[_metacel]:__unlink(host, link)
    end
  end
end

do --stackformation.movelink
  function stackformation:movelink(host, cel, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)
    if host and rawget(cel, _linker) then
      x, y, w, h = cel[_linker](host[_w], host[_h], x, y, w, h, rawget(cel, _xval), rawget(cel, _yval), minw, maxw, minh, maxh)
      x = math.modf(x)
      y = math.modf(y)
      w = math.floor(w)
      h = math.floor(h)

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end    
      if h < minh then h = minh end
    end

    if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
      cel[_x] = x
      cel[_y] = y
      cel[_w] = w
      cel[_h] = h

      event:wait()
      celmoved(host, cel, x, y, w, h, ox, oy, ow, oh)  
      event:signal()
    end

    return cel
  end
end

do --ENV.metacel
  metacel = {}
  metacel[_name] = 'cel'
  metacel[_face] = M.getface('cel')
  metacel[_variations] = metacel[_face][_variations]
end

do --metacel.new
  local floor = math.floor
  local celid = 1

  local _x, _y, _w, _h = _x, _y, _w, _h

  function metacel:new(w, h, face, minw, maxw, minh, maxh) --TODO do not accept limits in new, too much overhead for rare usage
    local cel = {
      [_x] = 0,
      [_y] = 0,
      [_w] = w and floor(w) or 0,
      [_h] = h and floor(h) or 0,
      [_minw] = minw and floor(minw) or 0, --TODO put defaults for minw/maxw in metatable
      [_maxw] = maxw and floor(maxw) or 2147483647,
      [_minh] = minh and floor(minh) or 0,
      [_maxh] = maxh and floor(maxh) or 2147483647,
      [_metacel] = self,
      [_face] = self[_variations][face] or metacel[_variations][face] or (face and self:getface(face)),
      [_celid] = celid,
    }
    celid = celid + 1
    return setmetatable(cel, self.metatable)
  end
end

do --metacel.assemble
  local metacel = metacel
  function metacel:assemble(t, cel)
    --assert(type(cel) == 'table' or type(cel) == 'nil')
    cel = cel or metacel:new(t.w, t.h, t.face)
    cel._ = t._ or cel._
    event:wait()

    cel.onresize = t.onresize
    cel.onmousein = t.onmousein
    cel.onmouseout = t.onmouseout
    cel.onmousemove = t.onmousemove
    cel.onmousedown = t.onmousedown
    cel.onmouseup = t.onmouseup
    cel.ontimer = t.ontimer
    cel.onfocus = t.onfocus
    cel.onblur = t.onblur
    cel.onkeydown = t.onkeydown
    cel.onkeypress = t.onkeypress
    cel.onkeyup = t.onkeyup
    cel.onchar = t.onchar
    cel.oncommand = t.oncommand
    cel.touch = t.touch
    linkall(cel, t)

    event:signal()
    return cel
  end
end

do --metacel.__celfromstring
  function metacel:__celfromstring(host, s)
    return M.label.new(s) 
  end
end

do --metacel.asyncall
  function metacel:asyncall(name, ...)
    if self[name] then
      local t = {} --WTF is this for???
      event:asyncall(self, name, t, ...)
      return t
    end
  end
end

do --metacel.newfactory
  local factories = {}

  function M.isfactory(v)
    return factories[v] == true
  end
  function metacel:newfactory(metatable)
    local metacel = self

    --assert(not rawget(M, metacel[_name]))

    local factory = {}

    --M[metacel[_name]] = factory 

    if metatable then
      for k, v in pairs(metatable) do
        factory[k] = v
      end
    end

    factory.new = function(...)
      return metacel:new(...)
    end

    factory.newmetacel = function(name) 
      return metacel:newmetacel(name) 
    end

    metatable = {__call = function (factory, t)
      return metacel:assemble(t)
      --TODO protect metatable
    end}

    setmetatable(factory, metatable)

    factory.newfactory = function()
      return setmetatable(
        {
          type = metacel[_name]
        },
        {
          __call = function(outerfactory, t)
            if outerfactory.assemble then
              return metacel:assemble(t, outerfactory.assemble(t))
            else 
              return metacel:assemble(t)
            end
          end,

          __index = factory,
        }
      )
    end

    factories[factory] = true
    return factory
  end
end

do --metacel.newmetacel
  function metacel:newmetacel(name)
    local metacel = {}
    local metatable = {}

    for k,v in pairs(self.metatable) do
      metatable[k] = v
    end

    metatable[_name] = name --TODO don't put name in metatable, are we useing name at all???


    local rawsub = {
      x = _x, 
      y = _y,
      w = _w,
      h = _h,
      xval = _xval,
      yval = _yval,
      linker = _linker,
      minw = _minw,
      maxw = _maxw,
      minh = _minh,
      maxh = _maxh,
      id = _celid,
      l = _x,
      t = _y,
    }

    local type = type
    local getX, getY = getX, getY
    local rawget = rawget

    metatable.__index = function(t, k)
      local result = metatable[k]; if result then return result end
      local raw = rawsub[k]; if raw then return rawget(t, raw) end

      if type(k) ~= 'string' then return
      elseif k == 'r' then return t[_x] + t[_w]
      elseif k == 'b' then return t[_y] + t[_h]
      elseif k == 'X' then return getX(t)
      elseif k == 'Y' then return getY(t)
      elseif k == 'L' then return getX(t)
      elseif k == 'R' then return getR(t)
      elseif k == 'T' then return getY(t)
      elseif k == 'B' then return getB(t)
      elseif k == 'face' then return rawget(t, _face) or t[_metacel][_face]
      elseif k == 'metacel' then return name
      --else print('looking for ', t, k)
      end
    end

    for k,v in pairs(self) do
      metacel[k] = v
    end

    metacel[_name] = name
    metacel.metatable = metatable
   
    metacel[_face] = newmetaface(name, self[_face])
    metacel[_variations] = metacel[_face][_variations]

    return metacel, metatable
  end
end

do --metacel.getface
  local _face = _face
  function metacel:getface(face)
    --TODO add _variations to metacel
    --local result = face and (self[_face][_variations][face] or metacel[_face][_variations][face])
    local result = face and (self[_variations][face] or metacel[_variations][face])

    --TODO remove this from here, it slows down everything, not worth the convenience
    if not result 
    and type(face) == 'string'
    and #face == 7 
    and face:sub(1,1)=="#" then
      result = M.getface('cel', face)
    end

    return result or self[_face]
  end
end

do --metacel.setface
  function metacel:setface(cel, face)
    return cel:refresh()
  end
end

do --metacel.assembleentry
  local unpack = unpack
  local type = type
  function metacel:assembleentry(host, entry, entrytype, linker, xval, yval, option)
    if 'table' == entrytype then
      if entry.link then
        if type(entry.link) == 'table' then
          linker, xval, yval, option = unpack(entry.link, 1, 4)
        else
          linker, xval, yval, option = entry.link, nil, nil, nil
        end
      end

      for i, v in ipairs(entry) do
        local link = M.tocel(v, host)
        if link then
          link._ = entry._ or link._
          link:link(host, linker, xval, yval, option)
        end
      end
    end
  end
end

do --metacel.metatable
    --[[
    --TODO can't put refresh in cel becuase it can be intercepted during meta processing 
    --put it in cel module instead, maybe it can stay just document not to call it in metaprocessing
    --]]
  metacel.metatable = {
    touch = touch,
    refresh = refresh, 
  }
end

