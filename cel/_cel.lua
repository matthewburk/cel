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
return function(_ENV, M)

setfenv(1, _ENV)

stackformation = {}

local stackformation = stackformation 

local _links = _links
local _x, _y, _w, _h = _x, _y, _w, _h
local _host = _host
local _minw, _maxw, _minh, _maxh = _minw, _maxw, _minh, _maxh
local _metacel = _metacel
local _linker = _linker
local _xval = _xval
local _yval = _yval
local _formation = _formation

flows = {} --ENV.flows

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

do --ENV.refresh
  refreshtable = {}

  function refresh(cel)
    while cel and not refreshtable[cel] do
      refreshtable[cel] = true
      cel = rawget(cel, _host)
    end
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
    --print('move', cel, x, y, w, h)
    local host = rawget(cel, _host)

    if host and rawget(host, _formation) then
      return host[_formation]:movelink(host, cel, x, y, w, h)
    else
      local ox, oy, ow, oh = cel[_x], cel[_y], cel[_w], cel[_h]
      local minw, maxw = cel[_minw] or 0, cel[_maxw] or maxdim
      local minh, maxh = cel[_minh] or 0, cel[_maxh] or maxdim

      if w ~= ow or h ~= oh then 
        if w < minw then w = minw end
        if w > maxw then w = maxw end
        if h < minh then h = minh end
        if h > maxh then h = maxh end    
      end

      if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return cel end

      if host and rawget(cel, _linker) then
        x, y, w, h = cel[_linker](host[_w], host[_h], x, y, w, h, cel[_xval], cel[_yval], minw, maxw, minh, maxh)
        if w < minw then w = minw end
        if w > maxw then w = maxw end
        if h < minh then h = minh end
        if h > maxh then h = maxh end    
      end

      if x ~= ox then x = math.modf(x); cel[_x] = x; end
      if y ~= oy then y = math.modf(y); cel[_y] = y; end
      if w ~= ow then w = math.floor(w); cel[_w] = w; end
      if h ~= oh then h = math.floor(h); cel[_h] = h; end

      if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
        event:wait()
        celmoved(host, cel, x, y, w, h, ox, oy, ow, oh)  
        event:signal()
      end

      return cel
    end
  end
end

do --ENV.touch
  function touch(cel, x, y)
    if x < 0 or y < 0 or x >= cel[_w] or y >= cel[_h] then
      return false
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

    local celface = cel[_face] 
    celface = celface or cel[_metacel][_face]

    if celface and celface.touch ~= nil and celface.touch ~= touch then
      if not celface:touch(x, y, cel[_w], cel[_h]) then
        return false
      end
    end
    
    return true
  end
end


do --ENV.linkall
  local linkparams = setmetatable({}, {__mode = 'k'})

  function linkall(host, t)
    linkall = function(host, t)
      event:wait()

      for i=1, #t do
        local link = t[i]
        local linktype = type(link)

        if linktype == 'function' then
          link(host, t)
        elseif linktype == 'string' then
          host[_metacel]:__celfromstring(host, link):link(host)
        elseif linktype == 'table' and link[_metacel] then --if link is a cel
          link:link(host, link[_linker], link[_xval], link[_yval])
        else
          host[_metacel]:compileentry(host, link, linktype)
        end
      end

      event:signal()
    end
   
    return linkall(host, t)
  end
end

do --ENV.describe
  local descriptions = setmetatable({}, {__mode = 'kv'})

  function describe(cel, host, gx, gy, gl, gt, gr, gb)
    gx = gx + cel[_x] --TODO clamp to maxint
    gy = gy + cel[_y] --TODO clamp to maxint

    if gx > gl then gl = gx end
    if gy > gt then gt = gy end

    if gx + cel[_w] < gr then gr = gx + cel[_w] end
    if gy + cel[_h] < gb then gb = gy + cel[_h] end

    if gr <= gl or gb <= gt then return end

    local t = descriptions[cel]

    if t then
      t.id = cel[_celid]
      t.host = host
      t.x = gx
      t.y = gy
      t.w = cel[_w]
      t.h = cel[_h]
      t.mousefocus = false
      t.mousefocusin = false
      t.focus = false
      t.flowcontext = flows[cel] and flows[cel].context
      t.clip.l = gl
      t.clip.r = gr
      t.clip.t = gt
      t.clip.b = gb

      for i = 1, #t do t[i] = nil end
    else
      --print 'loading new description'
      t = {
        id = cel[_celid],
        metacel = cel[_metacel][_name],
        face = cel[_face] or cel[_metacel][_face],
        host = host,
        x = gx,
        y = gy,
        w = cel[_w],
        h = cel[_h],
        mousefocus = false,
        mousefocusin = false,
        focus = false,
        flowcontext = flows[cel] and flows[cel].context,
        clip = {l = gl, r = gr, t = gt, b = gb},
      }
      descriptions[cel] = t
    end

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

    (rawget(cel, _formation) or stackformation):describelinks(cel, t, gx, gy, gl, gt, gr, gb)

    return t
  end
end

do --ENV.celmoved
  --host is the host of the cel that moved, can be nil
  --link is the cel that moved
  function celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
    assert(link)
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
    end

    if host then --and not rawget(host, _formation) then
      if host[_metacel].__linkmove then
        host[_metacel]:__linkmove(host, link, ox, oy, ow, oh)
      end
      if host[_metacel].onlinkmove then
        event:onlinkmove(host, link, ox, oy, ow, oh)
      end
    end
    
    refresh(link)
  end
end

do --ENV.islinkedto
  function islinkedto(cel, host)
    assert(cel)

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
end

do --ENV.testlinker
  local math = math

  --TODO need to support option parameter
  function testlinker(cel, host, linker, xval, yval)
    if linker and type(linker) ~= 'function' then linker = linkers[linker] end
    --linker = linker and linkers[linker] or linker --TODO this is probably quicker than checking the type of the linker do this everywhere
    local x, y, w, h = cel[_x], cel[_y], cel[_w], cel[_h]

    if not linker then return x, y, w, h end

    if rawget(host, _formation) then
      return host[_formation]:testlinker(host, cel, linker, xval, yval)
    else
      local minw, maxw = cel[_minw] or 0, cel[_maxw] or maxdim
      local minh, maxh = cel[_minh] or 0, cel[_maxh] or maxdim

      x, y, w, h = linker(host[_w], host[_h], x, y, w, h, xval, yval, minw, maxw, minh, maxh)

      if w < minw then w = minw end
      if w > maxw then w = maxw end
      if h < minh then h = minh end
      if h > maxh then h = maxh end

      return math.modf(x), math.modf(y), math.floor(w), math.floor(h)
    end
  end
end

do --stackformation.describelinks
  function stackformation:describelinks(cel, host, gx, gy, gl, gt, gr, gb)
    local i = 1
    local link = rawget(cel, _links)
    while link do
      host[i] = describe(link, host, gx, gy, gl, gt, gr, gb)
      i = host[i] and i + 1 or i
      link = link[_next]
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
    local minw, maxw, minh, maxh = link[_minw] or 0, link[_maxw] or maxdim, link[_minh] or 0, link[_maxh] or maxdim
    local x, y, w, h = linker(host[_w], host[_h], ox, oy, ow, oh, xval, yval, minw, maxw, minh, maxh)

    if w ~= ow or h ~= oh then
      if w < minw then w = minw end
      if w > maxw then w = maxw end
      if h < minh then h = minh end
      if h > maxh then h = maxh end
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


do --ENV.metacel
  metacel = {}
  metacel[_name] = 'cel'
  metacel[_face] = M.face[_metafaces]['cel']
end

do --metacel.new
  local floor = math.floor
  local _x, _y, _w, _h = _x, _y, _w, _h
  local _minw, _maxw, _minh, _maxh = _minw, _maxw, _minh, _maxh
  local _metacel = _metacel
  local _face = _face
  local setmetatable = setmetatable
  local celid = 1
  function metacel:new(w, h, face, minw, maxw, minh, maxh)
    local cel = {
      [_x] = 0,
      [_y] = 0,
      [_w] = w and floor(w) or 0,
      [_h] = h and floor(h) or 0,
      [_minw] = minw and floor(minw),
      [_maxw] = maxw and floor(maxw),
      [_minh] = minh and floor(minh),
      [_maxh] = maxh and floor(maxh),
      [_metacel] = self,
      [_face] = self[_face][face],
      [_celid] = celid
    }
    celid = celid + 1
    return setmetatable(cel, self.metatable)
  end
end

do --metacel.compile
  local metacel = metacel

  local unpack = unpack
  function metacel:compile(t, cel)
    assert(type(cel) == 'table' or type(cel) == 'nil')
    cel = cel or metacel:new(t.w, t.h, t.face)
    if cel.beginflux then cel:beginflux(false) end
    event:wait()

    cel.onresize = t.onresize
    cel.onmousein = t.onmousein
    cel.onmouseout = t.onmouseout
    cel.onmousemove = t.onmousemove
    cel.onmousedown = t.onmousedown
    cel.onmouseup = t.onmouseup
    cel.ontimer = t.ontimer
    cel.onfocus = t.onfocus
    cel.onkeydown = t.onkeydown
    cel.onkeyup = t.onkeyup
    if t.link then
      local linker, xval, yval

      if type(t.link) == 'table' then
        linker, xval, yval = t.link[1], t.link[2], t.link[3]
      else
        linker = t.link
      end

      if type(linker) ~= 'function' then
        linker = M.getlinker(linker)
      end

      cel[_linker] = linker
      cel[_xval] = xval
      cel[_yval] = yval
    end
    linkall(cel, t)

    event:signal()
    if cel.endflux then cel:endflux(false) end
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
      event:raise(self, name, t, ...)
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

    assert(not rawget(M, metacel[_name]))

    local factory = {}

    M[metacel[_name]] = factory 

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
      return metacel:compile(t)
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
            if outerfactory.compile then
              return metacel:compile(t, outerfactory.compile(t))
            else 
              return metacel:compile(t)
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

    local getX, getY = getX, getY
    local rawget = rawget
    metatable.__index = function(t, k)
      local result = metatable[k]
      if result then return result
      elseif k == 'x' then return t[_x] 
      elseif k == 'y' then return t[_y]
      elseif k == 'w' then return t[_w]
      elseif k == 'h' then return t[_h]
      elseif k == 'xval' then return rawget(t, _xval)
      elseif k == 'yval' then return rawget(t, _yval)
      elseif k == 'linker' then return rawget(t, _linker)
      elseif k == 'minw' then return rawget(t, _minw) or 0
      elseif k == 'maxw' then return rawget(t, _maxw) or maxdim
      elseif k == 'minh' then return rawget(t, _minh) or 0
      elseif k == 'maxh' then return rawget(t, _maxh) or maxdim 
      elseif k == 'l' then return t[_x]
      elseif k == 'r' then return t[_x] + t[_w]
      elseif k == 't' then return t[_y]
      elseif k == 'b' then return t[_y] + t[_h]
      elseif k == 'X' then return getX(t)
      elseif k == 'Y' then return getY(t)
      elseif k == 'L' then
      elseif k == 'R' then
      elseif k == 'T' then
      elseif k == 'B' then
      --else print('looking for ', t, k)
      end
    end

    for k,v in pairs(self) do
      metacel[k] = v
    end

    metacel[_name] = name
    metacel.metatable = metatable
    
    metacel[_face] = setmetatable(defineface(name), {__index = self[_face]})

    return metacel, metatable
  end
end

do --metacel.getface
  local _face = _face
  function metacel:getface(face)
    if face then
      local rawface = rawget(self[_face], face) or rawget(metacel[_face], face)
      return rawface or self[_face]
    else
      return self[_face]
    end
  end
end

function M.unpacklink(t, i, j)

end
do --metacel.compileentry 
  function metacel:compileentry(host, entry, entrytype)
    if 'table' == entrytype then
      local linker, xval, yval, option

      if entry.link then
        if type(entry.link) == 'table' then
          linker, xval, yval, option = unpack(entry.link, 1, 4)
        else
          linker = entry.link
        end
      end

      for i, v in ipairs(entry) do
        local link = M.tocel(v, host)
        if link then
          link:link(host, linker, xval, yval, option)
        end
      end
    end
  end
end

do --metacel.setlimits
  local floor = math.floor
  local function max(a, b) if a >= b then return a else return b end end

  --TODO implement sending in nw, nh, which is the new size of the cel, since
  --we have to resize in most cases when the limits are changed
  --and a lot of times we have to do it right after calling setlimts
  function metacel:setlimits(cel, minw, maxw, minh, maxh, nw, nh)
    --TODO changing the limits should cause the linker to run if 
    --the current w/h is restrained by the limits, but the linker
    --would grow/shrink it if it could
    if cel[_metacel] ~= self then  --TODO think of a better way to make sure this gets to right metacel
      return cel[_metacel]:setlimits(cel, minw, maxw, minh, maxh, nw, nh)
    end

    minw = max(floor(minw or 0), 0)
    maxw = max(floor(maxw or maxdim), minw)
    minh = max(floor(minh or 0), 0)
    maxh = max(floor(maxh or maxdim), minh)

    if minw == 0 then cel[_minw] = nil else cel[_minw] = minw end
    if minh == 0 then cel[_minh] = nil else cel[_minh] = minh end
    if maxw == maxdim then cel[_maxw] = nil else cel[_maxw] = maxw end
    if maxh == maxdim then cel[_maxh] = nil else cel[_maxh] = maxh end

    local w = nw or cel[_w]
    local h = nh or cel[_h]

    if w < minw then w = minw end
    if h < minh then h = minh end
    if w > maxw then w = maxw end
    if h > maxh then h = maxh end

    event:wait()

    local host = rawget(cel, _host)
    if host then
      local formation = rawget(host, _formation)
      if formation and formation.linklimitschanged then
        formation:linklimitschanged(host, cel, minw, maxw, minh, maxh)
      end
    end

    --this resizes the cel if the limits now constrain it
    --but also need to resize if the limits unconstrain it
    --if i always resize it makes it really slow under certain conditions
    --like a sequence of wrapping text
    --don't do this, the formation should handle it only, so just do it for the stackformation
    --or do it when there is no host
    if w ~= cel[_w] or h ~= cel[_h] or rawget(cel, _linker) then
      cel:resize(w, h)
    end

    event:signal()
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
    mouse = mouse,
    keyboard = keyboard,
  }
end

local metatable = metacel.metatable

do --metatable.__tostring
  function metatable.__tostring(cel)
    return cel[_metacel][_name]
  end
end

do --metatable.addlistener, metatable.removelistener
  local listenertypes = {
    onmousedown = _mousedownlistener,
    onmouseup = _mouseuplistener,
  }

  local function enablelistener(e)
    local t, f = e[2], e[3]
    t[f] = true
  end

  function metatable.addlistener(cel, onevent, f)
    local listenertype = listenertypes[onevent]

    if not listenertype then return cel end

    local t = cel[listenertype]

    if t then
      t[f] = false
    else
      t = {[f]=false}
      cel[listenertype] = t
    end
    --TODO add event for this or something, this seems sloppy
    event:push({enablelistener, t, f})

    return cel
  end

  function metatable.removelistener(cel, onevent, f)
    local listenertype = listenertypes[onevent]

    if not listenertype then return cel end

    local t = cel[listenertype]

    if t then
      t[f] = nil
      if not next(t) then
        cel[listenertype] = nil
      end
    end
    return cel
  end
end

do --metatable.link
  --[[
  --After this function returns cel must be linked to host(or an alternate host via __link), and by default will be the
  --top link (a cel overriding this could change that by linking additional cels after,and should document that it does)
  --unless cel is already linked to host or cel and host are the same cel
  --]]
  function metatable.link(cel, host, linker, xval, yval, option)
    assert(cel)
    assert(host)
    if not host then error('host is nil') end

    if cel == host then return cel end
    if rawget(cel, _host) == host then return cel end

    if linker then
      local typeof = type(linker)
      if typeof == 'number' then
        option = yval
        yval = xval
        xval = linker
        linker = nil
      elseif typeof == 'table' then
        option = xval
        linker, xval, yval = linker[1], linker[2], linker[3]
      end
    end

    event:wait()

    if rawget(cel, _host) then cel:unlink() end

    while host[_metacel].__link do
      if linker and type(linker) ~= 'function' then linker = linkers[linker] end

      local nhost, nlinker, nxval, nyval = host[_metacel]:__link(host, cel, linker, xval, yval, option)
          option = nil

      if nhost then
        if type(nlinker) == 'table' then
          linker, xval, yval = nlinker[1], nlinker[2], nlinker[3]
        else
          linker, xval, yval = nlinker, nxval, nyval
        end

        if host ~= nhost then
          host = nhost
        else
          break
        end
      else
        break
      end
    end

    if linker then
      if type(linker) ~= 'function' then linker = linkers[linker] end
      if not linker then
        xval = type(xval) == 'number' and math.modf(xval) or 0
        yval = type(yval) == 'number' and math.modf(yval) or 0
      end
    else
      xval = type(xval) == 'number' and math.modf(xval) or 0
      yval = type(yval) == 'number' and math.modf(yval) or 0
    end

    cel[_host] = host
    --formation:link must dolinker, assign _x _y _linker _xval _yval generate onlink event 
    local formation = rawget(host, _formation) or stackformation
    formation:link(host, cel, linker, xval, yval, option)

    refresh(host)
    event:signal()
    return cel
  end
end

do --metatable.relink
  --TODO support relinking with no linker 
  function metatable.relink(cel, linker, xval, yval)
    local host = rawget(cel, _host)

    if not host then return cel end

    if host[_metacel].__relink == false then return cel, false end

    local ox, oy, ow, oh = cel[_x], cel[_y], cel[_w], cel[_h]

    if linker and type(linker) ~= 'function' then
      linker = linkers[linker] 
      if not linker then
        return cel, false
      end
    end

    event:wait()

    if host[_metacel].__relink then
      local nlinker, nxval, nyval = host[_metacel]:__relink(host, cel, linker, xval, yval)

      if nlinker then
        linker = nlinker
        xval = nxval
        yval = nyval
        if type(linker) ~= 'function' then linker = linkers[linker] end
      end
    end

    cel[_linker] = nil
    cel[_xval] = nil
    cel[_yval] = nil

    --TODO must have formation:relink like formation:link so it can enforce linker
    --TODO more important to have formation:relink so it can know that the relink is
    --a command and it should accomodate instead of ignoring linker changes to 
    --height like sequence.y does
    if linker then
      cel[_linker] = linker
      cel[_xval] = xval
      cel[_yval] = yval
      dolinker(host, cel, linker, xval, yval)
    end

    event:signal()

    return cel, true
  end
end

do --metatable.unlink
  function metatable.unlink(cel)
    --print('metatable.unlink', cel)
    local host = rawget(cel, _host)
    if host then
      event:wait()

      cel[_host] = nil
      cel[_linker] = nil
      cel[_xval] = nil
      cel[_yval] = nil

      (rawget(host, _formation) or stackformation):unlink(host, cel)

      if mouse[_trap][cel] then
        mouse[_trap].trap:freemouse()
      end
      if mouse[_focus][cel] then
        pick(mouse)
      end
      if keyboard[_focus][cel] then
        host:takefocus(keyboard)
      end

      refresh(host)
      event:signal()
    end
    return cel
  end
end

do --metatable.disable
  function metatable.disable(cel)
    --print('metatable.unlink', cel)
    if cel[_disabled] then return cel end

    cel[_disabled] = true --TODO use bit flags for this
    local host = rawget(cel, _host)
    if host then
      event:wait()

      if mouse[_trap][cel] then
        mouse[_trap].trap:freemouse()
      end
      if mouse[_focus][cel] then
        pick(mouse)
      end
      if keyboard[_focus][cel] then
        --host will not be enabled becuase cel could not have focus if host is disabled
        host:takefocus(keyboard)
      end

      refresh(cel)
      event:signal()
    else
    end
    return cel
  end
end

do --metatable.enable
  function metatable.enable(cel)
    if cel[_disabled] then
      cel[_disabled] = false
      refresh(cel)
    end
    return cel
  end
end

do --metatable.pget
  local map = {
    linker = _linker,
    x = _x,
    y = _y,
    w = _w,
    h = _h,
    xval = _xval,
    yval = _yval,
    name = _name, --TODO change to metacel, and retrun the metacel's name
    face = _face,
    minw = _minw,
    maxw = _maxw,
    minh = _minh,
    maxh = _maxh,
  }

  local resultarrays = {
    {1},
    {1,2},
    {1,2,3},
    {1,2,3,4},
    {1,2,3,4,5},
    {1,2,3,4,5,6},
    {1,2,3,4,5,6,7},
    {1,2,3,4,5,6,7,8},
    {1,2,3,4,5,6,7,8,9},
    {1,2,3,4,5,6,7,8,9,10},
  }

  local select = select
  function metatable.pget(cel, ...)
    local nargs = select('#', ...)
    local result = resultarrays[nargs] or {...}
    local request

    for i = 1, nargs do
      request = select(i, ...) --TODO make this whole function faster, select is quadratic here
      result[i] = cel[map[request]]
    end

    return unpack(result, 1, nargs)
  end
end

do --metatable.getface --TODO remove this, face is mutable, breaks sandbox
  local _face, _metacel = _face, _metacel
  function metatable.getface(cel)
    return cel[_face] or cel[_metacel][_face]
  end
end

do --metatable.flow, metatable.flowvalue, metatable.flowlink
  local addflow
  local addflowvalue
  local flowlinker

  function metatable.flow(cel, flow, x, y, w, h, update, finalize)
    update = update or move

    if type(flow) == 'string' then flow = cel:getflow(flow) end

    local fx, fy, fw, fh = x or cel[_x], y or cel[_y], w or cel[_w], h or cel[_h]

    if flow then
      local context = {
        iteration = 1,
        duration = 0,
        mode = 'rect',
        finalize = -1, --TODO put this everywhere
      }

      local x, y, w, h, reflow = flow(context, cel[_x], fx, cel[_y], fy, cel[_w], fw, cel[_h], fh)

      if reflow then
        addflow(cel, flow, fx, fy, fw, fh, context, update, finalize)
        update(cel, x, y, w, h)
      else
        context.finalize = context.iteration
        update(cel, fx, fy, fw, fh)
        if finalize then finalize(cel) end
      end
    else
      update(cel, fx, fy, fw, fh)
      if finalize then finalize(cel) end
    end

    return cel
  end

  --ov(original value)
  --fv(final value)
  function metatable.flowvalue(cel, flow, ov, fv, update, finalize)
    if type(flow) == 'string' then flow = cel:getflow(flow) end

    if flow then
      local context = {
        iteration = 1,
        duration = 0,
        mode = 'value',
        finalize = -1, --TODO put this everywhere
      }

      local v, reflow = flow(context, ov, fv)

      if reflow then
        addflowvalue(cel, flow, ov, fv, context, update, finalize)
        update(cel, v)
      else
        context.finalize = context.iteration
        update(cel, fv)
        if finalize then finalize(cel) end
      end
    else
      update(cel, fv)
      if finalize then finalize(cel) end
    end

    return cel
  end

  --TODO if cel relinks, losing the flowlinker, then cancel flow or finalize it or something
  --TODO rename to flowrelink
  function metatable.flowlink(cel, flow, linker, xval, yval, update, finalize)
    update = update or move

    if type(flow) == 'string' then flow = cel:getflow(flow) end

    if flow then
      local context = {
        iteration = 1,
        duration = 0,
        mode = 'rect',
      }
      local fx, fy, fw, fh = testlinker(cel, rawget(cel, _host), linker, xval, yval)
      local x, y, w, h, reflow = flow(context, cel[_x], fx, cel[_y], fy, cel[_w], fw, cel[_h], fh)
      
      if reflow then
        addflow(cel, flow, fx, fy, fw, fh, context, update, finalize, xval, yval, linker)
        cel:relink(flowlinker, cel, flows[cel])
        update(cel, x, y, w, h)
      else
        context.finalize = context.iteration
        cel:relink(linker, xval, yval)
        --update(cel, x, y, w, h)
        update(cel, cel[_x], cel[_y], cel[_w], cel[_h])
        if finalize then finalize(cel) end
      end
    else
      cel:relink(linker, xval, yval)
      update(cel, cel[_x], cel[_y], cel[_w], cel[_h])
      if finalize then finalize(cel) end
    end

    return cel
  end

  function addflow(cel, flow, fx, fy, fw, fh, context, update, finalize, xval, yval, linker)
    --TODO as optimization turn this into array instead of hash
    flows[cel] = {
      context = context,
      ox = cel[_x],
      oy = cel[_y],
      ow = cel[_w],
      oh = cel[_h],
      fx = fx,
      fy = fy,
      fw = fw,
      fh = fh,
      flow = flow,
      startmillis = M.timer(),
      update = update, 
      finalize = finalize,
      xval = xval, 
      yval = yval, 
      linker = linker,
    }
  end

  function addflowvalue(cel, flow, ov, fv, context, update, finalize)
    flows[cel] = {
      context = context,
      ox = ov,
      fx = fv,
      flow = flow,
      startmillis = M.timer(),
      update = update, 
      finalize = finalize,
    }
  end

  function flowlinker(hw, hh, x, y, w, h, cel, flow)
    --update fx, fy, fw, fh of flow based on flows linker
    if flow.linker then
      local fx, fy, fw, fh = testlinker(cel, rawget(cel, _host), flow.linker, flow.xval, flow.yval)
      flow.fx = fx
      flow.fy = fy
      flow.fw = fw
      flow.fh = fh
    end
    return x, y, w, h
  end
end

do --metatable.getflow
  function metatable.getflow(cel, flow)
    local celface = cel:getface()
    if celface.flow then
      return celface.flow[flow]
    end
  end
end

do --metatable.isflowing
  function metatable.isflowing(cel, flow)
    if flows[cel] then
      if flow then
        if type(flow) == 'string' then
          flow = cel:getflow(flow)
        end
        return (flows[cel].flow == flow)
      end
      return true
    end
    return false
  end
end

do --metatable.reflow
  function metatable.reflow(cel, flow, fx, fy, fw, fh)
    local v = flows[cel]
    if not v then
      return cel
    end

    if flow then
      if type(flow) == 'string' then
        flow = cel:getflow(flow)
      end
      if v.flow ~= flow then
        return cel
      end
    end

    v.fx = fx or v.fx
    v.fy = fy or v.fy
    v.fw = fw or v.fw
    v.fh = fh or v.fh
    return cel
  end
end

do --metatable.endflow
  function metatable.endflow(cel, flow)
    local t = flows[cel]
    if not t then
      return cel
    end

    if flow then
      if type(flow) == 'string' then
        flow = cel:getflow(flow)
      end
      if t.flow ~= flow then
        return cel
      end
    end

    flows[cel] = nil --TODO may want to keep this until final context is seen in description

    --print('endflow', cel, flow)
    local context = t.context
    local ox, oy, ow, oh = t.ox, t.oy, t.ow, t.oh
    local fx, fy, fw, fh = t.fx, t.fy, t.fw, t.fh 
    local flow = t.flow 
    local update = t.update 
    local finalize = t.finalize 

    context.duration = M.timer() - t.startmillis
    context.iteration = context.iteration + 1
    context.finalize = context.iteration
    flow(context, ox, fx, oy, fy, ow, fw, oh, fh)

    if t.linker then 
      cel:relink(t.linker, t.xval, t.yval) 
      update(cel, cel[_x], cel[_y], cel[_w], cel[_h]) --TODO only have to do this if update ~= move
    else
      update(cel, fx, fy, fw, fh)
    end

    if finalize then finalize(cel) end

    return cel
  end
end

do --metatable.move, metatable.moveby, metatable.resize 
  --cel, x, y, w, h are required

  local move = move

  function metatable.move(cel, x, y, w, h)
    return (move(cel, x or cel[_x], y or cel[_y], w or cel[_w], h or cel[_h])) or cel
  end

  function metatable.resize(cel, w, h)
    return (move(cel, cel[_x], cel[_y], w or cel[_w], h or cel[_h])) or cel
  end

  function metatable.moveby(cel, x, y, w, h)
    return (move(cel, cel[_x] + (x or 0), cel[_y] + (y or 0), cel[_w] + (w or 0), cel[_h] + (h or 0))) or cel
  end
end

do --metatable.hasfocus
  function metatable.hasfocus(cel, source)
    local source = source or keyboard
    if source == keyboard then
      local n = source[_focus][cel]
      if n then
        return source[_focus].n - n + 1, source
      end
    elseif source == mouse then
      local n = source[_focus][cel]
      if n then
        return #source[_focus] - n + 1, source
      end
    end
  end
end

do --metatable.islinkedto
  metatable.islinkedto = islinkedto
  metatable.islinkedtoroot = function(cel)
    return islinkedto(cel, _ENV.root)
  end
end

do --metatable.takefocus
  local pickfocus

  --TODO focus should be for all devices, except mouse type devices
  function metatable.takefocus(cel, source)
    if source == mouse then
      return 
    end

    source = source or keyboard
    event:wait()
    pickfocus(source, cel)
    --TODO only refresh if focus actually changed, should be done in pick focus
    refresh(cel)
    event:signal()

    return cel:hasfocus(source)
  end

  --TODO merge into metatable.takefocus
  pickfocus = function(device, target)
    assert(target)

    --TODO should not have to do seperate code path for root
    --
    local device_focus = device[_focus]

    if target == device_focus[device_focus.n] then
      return
    end

    if target == _ENV.root then
      assert(_ENV.root)
      for i = device_focus.n, 1, -1 do
        event:onfocus(device_focus[i], false)
        device_focus[device_focus[i]] = nil
        device_focus[i] = nil
      end

      device_focus.n = 1
      device_focus[1] = _ENV.root
      device_focus[_ENV.root] = 1
      event:onfocus(_ENV.root, true)
      assert(_ENV.root)
      return
    end

    --TODO don't call out through metatable, give opportunity to fuck it up
    local z = islinkedto(target, _ENV.root)
      assert(_ENV.root)

    if not z then
      return
    else
      z = z + 1 
    end

    local cutoff = 1 --root always has focus, or does it?

    for host in hosts(target) do
      if device_focus[host] then
        cutoff = device_focus[host] + 1
        break
      end
    end

    for i = device_focus.n, cutoff, -1 do
      event:onfocus(device_focus[i], false)
      device_focus[device_focus[i]] = nil
      device_focus[i] = nil
    end

    device_focus.n = z
    device_focus[z] = target
    device_focus[target] = z
    event:onfocus(target, true)

    for host in hosts(target) do
      if device_focus[host] then
        break
      end
      z = z - 1
      device_focus[z] = host
      device_focus[host] = z
      event:onfocus(host, true)
    end
  end
end


do --metatable.hasmousetrapped
  function metatable.hasmousetrapped(cel)
    if mouse[_trap].trap == cel then
      return true
    else
      return false
    end
  end
end

do --metatable.trapmouse
  function metatable.trapmouse(cel, onfail)
    local t = mouse[_trap]

    if t.trap == cel then
      return true
    end

    --fail becuase mouse is already trapped by another cel
    --bad logic mouse is always trapped by root at least
    --if t.trap then
    --  if onfail then onfail(cel, mouse) end
    --  return false
    --end

    --if cel is already trapping mouse, through a descendant, don't let it trap
    if mouse[_trap][cel] then
      if onfail then onfail(cel, mouse, 'already trapped by link') end
      return false
    end
    --can't trap if mouse is not in cel
    if not mouse:incel(cel) then
      if onfail then onfail(cel, mouse, 'mouse not in cel') end
      return false
    end

    t.trap = cel
    t.onfail = onfail

    repeat
      t[cel] = true
      cel = rawget(cel, _host)
    until not cel

    return true
  end
end

do --metatable.freemouse
  function metatable.freemouse(cel, reason)
    local t = mouse[_trap]

    if t.trap == cel then
      local onfail = t.onfail

      for k,v in pairs(t) do
        t[k] = nil
      end

      assert(_ENV.root)

      t[_ENV.root] = true
      t.trap = _ENV.root
      assert(_ENV.root)

      if onfail then onfail(cel, mouse, reason or 'freed') end
    end
    return cel
  end
end

do --metatable.raise
  --TODO change method name to float
  --puts cel at top of hosts link stack
  function metatable.raise(cel)
    local host = rawget(cel, _host)

    if not host then return cel end
    --noop for anything other than stackformation
    if rawget(host, _formation) then return cel end

    if rawget(cel, _next) then
      cel[_next][_prev] = rawget(cel, _prev)
    elseif rawget(host, _links) == cel then
      return cel
    end

    if rawget(cel, _prev) then
      cel[_prev][_next] = rawget(cel, _next)
    else
      host[_links] = rawget(cel, _next)
    end

    cel[_next] = nil
    cel[_prev] = nil

    cel[_next] = rawget(host, _links)
    cel[_prev] = nil
    host[_links] = cel

    if rawget(cel, _next) then cel[_next][_prev] = cel end

    return cel
  end
end

do --metatable.sink
  --puts cel at bottom of hosts link stack
  --TODO change method to a generic name that has meanings for more than stackformation
  function metatable.sink(cel)
    local host = rawget(cel, _host)

    if not host then return cel end

    --noop for anything other than stackformation
    if rawget(host, _formation) then return cel end

    --TODO this prevents execution when host is not stackformation as well, but its not explicit enough
    if not rawget(cel, _next) then return cel end 

    --remove from list
    cel[_next][_prev] = cel[_prev]

    if rawget(cel, _prev) then
      cel[_prev][_next] = rawget(cel, _next)
    else
      host[_links] = rawget(cel, _next)
    end

    local link = rawget(cel, _next)

    while link[_next] do
      link = link[_next]
    end

    link[_next] = cel
    cel[_prev] = link
    cel[_next] = nil

    --TODO force a pick?

    return cel
  end
end

do --metatable.__index
  --local _x, _y, _w, _h = _x, _y, _w, _h
  --local _linker, _xval, _yval = _linker, _xval, _yval
  --local _minw, _maxw, _minh, _maxh = _minw, _maxw, _minh, _maxh
  --local getX, getY = getX, getY

  function metatable.__index(t, k)
    local result = metatable[k]
    if result then return result
    elseif k == 'x' then return t[_x] 
    elseif k == 'y' then return t[_y]
    elseif k == 'w' then return t[_w]
    elseif k == 'h' then return t[_h]
    elseif k == 'xval' then return rawget(t, _xval)
    elseif k == 'yval' then return rawget(t, _yval)
    elseif k == 'linker' then return rawget(t, _linker)
    elseif k == 'minw' then return rawget(t, _minw) or 0
    elseif k == 'maxw' then return rawget(t, _maxw) or maxdim
    elseif k == 'minh' then return rawget(t, _minh) or 0
    elseif k == 'maxh' then return rawget(t, _maxh) or maxdim
    elseif k == 'l' then return t[_x]
    elseif k == 'r' then return t[_x] + t[_w]
    elseif k == 't' then return t[_y]
    elseif k == 'b' then return t[_y] + t[_h]
    elseif k == 'X' then return getX(t)
    elseif k == 'Y' then return getY(t)
    elseif k == 'L' then
    elseif k == 'R' then
    elseif k == 'T' then
    elseif k == 'B' then
    end
  end
end

function metatable:dump()
  local F = string.format
  local name = self[_metacel][_name]

  print(self, name)
  print(self, F('x%d', self.x), F('y%d', self.y), F('w%d', self.w), F('h%d', self.h))
  print(self, F('minw%d', self.minw), F('maxw%d', self.maxw))
  print(self, F('minh%d', self.minh), F('maxh%d', self.maxh))
  if self[_metacel].__dump then
    self[_metacel]:__dump(self)
  end
end

end
