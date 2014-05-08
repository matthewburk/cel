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

local rawget = rawget
local math = math
local type = type
local unpack = unpack
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local floor = math.floor
local max = math.max
local min = math.min
local modf = math.modf
local select = select

local CEL = require 'cel.core.env'

require 'cel.core.event'
require 'cel.core.driver'

local _formation = CEL._formation
local _host = CEL._host
local _links = CEL._links
local _next = CEL._next
local _prev = CEL._prev
local _trap = CEL._trap
local _focus = CEL._focus
local _name = CEL._name
local _x = CEL._x
local _y = CEL._y
local _w = CEL._w
local _h = CEL._h
local _metacel = CEL._metacel
local _linker = CEL._linker
local _xval = CEL._xval
local _yval = CEL._yval
local _face = CEL._face
local _minw = CEL._minw
local _minh = CEL._minh
local _maxw = CEL._maxw
local _maxh = CEL._maxh
local _celid = CEL._celid
local _disabled = CEL._disabled
local _refresh = CEL._refresh
local _appstatus = CEL._appstatus --TODO remove
local _hidden = CEL._hidden

local _variations = CEL.privatekey('_variations')

local maxdim = CEL.maxdim
local event = CEL.event
local stackformation = CEL.stackformation
local mouse = CEL.mouse
local keyboard = CEL.keyboard
local driver = CEL.driver
local flows = CEL.flows

local linkers = require 'cel.core.linkers'

local M = CEL.M --for tocel and label.new

local function getX(cel)
  local root = CEL.root
  local x = 0

  while cel do
    x = x + cel[_x]
    if root == rawget(cel, _host) then
      return x
    end
    cel = rawget(cel, _host)
  end
end

local function getR(cel)
  local X = getX(cel)
  return X and X + cel[_w] 
end

local function getY(cel)
  local root = CEL.root
  local y = 0

  while cel do
    y = y + cel[_y]
    if root == rawget(cel, _host) then
      return y
    end
    cel = rawget(cel, _host)
  end
end

local function getB(cel)
  local Y = getY(cel)
  return Y and Y + cel[_h] 
end

local describe do
  local updaterect = CEL.updaterect
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
      x = 0, y = 0, w = 0, h = 0,
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
end

local function refresh(cel)
  local _cel = cel 
  cel[_refresh] = 'full'
  cel = rawget(cel, _host)

  while cel and not cel[_refresh] do
    cel[_refresh] = true 
    cel = rawget(cel, _host)
  end
  return _cel
end

local function refreshmove(cel, ox, oy, ow, oh)
  cel[_refresh] = 'full'
  cel = rawget(cel, _host)

  if cel then
    refresh(cel)
  end
end

local function refreshlink(cel, link)
  return refresh(cel)
end

local function refreshunlink(cel, link)
  return refresh(cel)
end

local touch do
  local function touchlinksonly(cel, x, y)
    local metacel = cel[_metacel]
    local formation = rawget(cel, _formation)

    if formation and formation.pick then
      local link = formation:pick(cel, x, y)
      if touch(link, x - link[_x], y - link[_y]) then
        return true
      end
      return false
    end

    local link = rawget(cel, _links)
    while link do
      if touch(link, x - link[_x], y - link[_y]) then
        return true
      end
      link = link[_next]
    end
    return false
  end

  function touch(cel, x, y)
    if x < 0 
    or y < 0 
    or x >= cel[_w] 
    or y >= cel[_h] 
    or cel.touch == false --TODO rawget?
    or cel[_metacel].touch == false then --TODO rawget?
      return false
    end

    if cel.touch == true or cel[_metacel].touch == true then --TODO rawget?
      return true
    end

    if cel.touch ~= touch then
      if cel.touch == 'links' then
        return touchlinksonly(cel, x, y)
      end
      if not cel:touch(x, y) then
        return false
      end
    elseif cel[_metacel].touch ~= nil and cel[_metacel].touch ~= touch then
      if cel[_metacel].touch == 'links' then
        return touchlinksonly(cel, x, y)
      end
      if not cel[_metacel]:touch(cel, x, y) then
        return false
      end
    end

    --cel face can only restrict touch not add to area
    local celface = cel[_face] 
    celface = celface or cel[_metacel][_face]

    if celface.touch ~= nil and celface.touch ~= touch then
      if celface.touch == 'links' then
        return touchlinksonly(cel, x, y)
      end
      if not celface:touch(x, y, cel[_w], cel[_h]) then
        return false
      end
    end
    
    return true
  end
end

local pick do
  local function getdepth(cel)
    --root is depth 1
    local depth = 0 
    while cel do
      depth = depth + 1
      cel = cel[_host]
    end
    assert(depth >= 0)
    return depth
  end
  
  --sets mouse[_focus] to cel directly under mouse cursor
  --fires mouseenter/mouseexit events
  --returns x,y in mouse[_focus].focus space
  --put in _cel.lua
  function pick(mouse, debug)
    local mouse_focus = mouse[_focus]
    local mouse_trap = mouse[_trap]
    local x = mouse[_x]
    local y = mouse[_y]
    local z = 1 
    local cel = CEL.root
    local trap = mouse_trap.trap
    assert(trap)
    cel = trap
    assert(cel)

    if cel[_host] then
      x = x - cel[_host].X
      y = y - cel[_host].Y
      z = getdepth(cel)
      --z should be 1 for root, 2 for next one etc
    end
    --x and y are now relative to cel[_host]
    
    mouse_focus.focus = nil

    while cel do
      --make x and y relative to cel
      x = x - cel[_x]
      y = y - cel[_y]

      if touch(cel, x, y) then
        if mouse_focus[z] then
          if mouse_focus[z] ~= cel then
            for i = #mouse_focus, z, -1 do
              event:onmouseout(mouse_focus[i])
              assert(mouse_focus[i])
              refresh(mouse_focus[i])
              mouse_focus[mouse_focus[i]] = nil
              mouse_focus[i] = nil
            end
            mouse_focus[z] = cel
            mouse_focus[cel] = z
            event:onmousein(cel)
            assert(cel)
            refresh(cel)
          end
        else
          mouse_focus[z] = cel
          mouse_focus[cel] = z
          event:onmousein(cel)
          assert(cel)
          refresh(cel)
        end

        mouse_focus.focus = cel

        if not cel[_disabled] then
          local formation = rawget(cel, _formation)
          if formation and formation.pick then
            cel = formation:pick(cel, x, y)

            if cel and not touch(cel, x - cel[_x], y - cel[_y]) then
              cel = nil
            end

            if not cel then
              z = z + 1
              if mouse_focus[z] then
                for i = #mouse_focus, z, -1 do
                  event:onmouseout(mouse_focus[i])
                  assert(mouse_focus[i])
                  refresh(mouse_focus[i])
                  mouse_focus[mouse_focus[i]] = nil
                  mouse_focus[i] = nil
                end
              end
            end
          else
            cel = cel[_links]
          end
        else --cel is disabled
          for i = #mouse_focus, z+1, -1 do
            event:onmouseout(mouse_focus[i])
            assert(mouse_focus[i])
            refresh(mouse_focus[i])
            mouse_focus[mouse_focus[i]] = nil
            mouse_focus[i] = nil
          end
          break
        end
        z = z + 1
      else --cel was not touched
        if mouse_focus[z] == cel then
          for i = #mouse_focus, z, -1 do
            event:onmouseout(mouse_focus[i])
            assert(mouse_focus[i])
            refresh(mouse_focus[i])
            mouse_focus[mouse_focus[i]] = nil
            mouse_focus[i] = nil
          end
        end

        if trap == cel then
          break; 
        else
          x = x + cel[_x]
          y = y + cel[_y]
          cel = cel[_next]
        end
      end
    end

    for i = #mouse_focus, 1, -1 do
      --assert(mouse_focus[i])

      if mouse_focus[i] then
        if mouse_focus.focus then
          if mouse_focus[i] == mouse_focus.focus then break end

          event:onmouseout(mouse_focus[i])
          assert(mouse_focus[i])
          refresh(mouse_focus[i])
          mouse_focus[mouse_focus[i]] = nil
          mouse_focus[i] = nil
        end
      else
        dprint('BAD PICK', mouse_focus[1], mouse_focus.focus, i, #mouse_focus)
        dprint('BAD PICK DATA', unpack(mouse_focus))
        for j, k in pairs(mouse_focus) do
          dprint(j, k)
        end
      end
    end

    return x,y
  end
end

local function dolinker(host, cel, linker, xval, yval)
  return (rawget(host, _formation) or stackformation):dolinker(host, cel, linker, xval, yval)
end

local function move(cel, x, y, w, h)
  x, y, w, h = math.modf(x), math.modf(y), math.floor(w), math.floor(h)
  local ox, oy, ow, oh = cel[_x], cel[_y], cel[_w], cel[_h]
  local minw, maxw = cel[_minw], cel[_maxw]
  local minh, maxh = cel[_minh], cel[_maxh]

  if w ~= ow or h ~= oh then 
    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end    
    if h < minh then h = minh end
  end

  if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return cel end

  local host = rawget(cel, _host)
  local formation = host and rawget(host, _formation) or stackformation

  formation:movelink(host, cel, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)

  return cel
end

local function celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
  if rawget(link, _formation) and link[_formation].moved then
    link[_formation]:moved(link, x, y, w, h, ox, oy, ow, oh)
  else
    if w ~= ow or h ~= oh then
      event:onresize(link, ow, oh)
      do
        local host = link
        local link = rawget(host, _links)
        while link do
          if rawget(link, _linker) then
            dolinker(host, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
          end
          link = link[_next]
        end
      end
      if link[_metacel].__resize then
        link[_metacel]:__resize(link, ow, oh)
      end
    end
  end

  if host then 
    if host[_metacel].__linkmove then
      host[_metacel]:__linkmove(host, link, ox, oy, ow, oh)
    end
    if host[_metacel].onlinkmove then
      event:onlinkmove(host, link, ox, oy, ow, oh)
    end
  end

  refreshmove(link, ox, oy, ow, oh)
end

local function islinkedto(cel, host)
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

--TODO need to support option parameter
local function testlinker(cel, host, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
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

local function linkall(host, t)
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

local getface
local newmetaface
do --face
  local _metacelname = CEL._metacelname
  local _registered = {}
  local weak = {__mode='kv'}

  local celfacemt = {} do
    celfacemt.__index = celfacemt

    function celfacemt:new(t)
      t = t or {}
      t.__index = t
      self[_variations][t] = t 
      return setmetatable(t, self)
    end

    function celfacemt:weakregister(name)
      self[_variations][name] = self 
      return self
    end

    function celfacemt:register(name)
      self[_registered][name] = self
      self[_variations][name] = self 
      return self
    end

    function celfacemt:gettype()
      return self[_metacelname]
    end

    function celfacemt.print(f, t, pre, facename)
      local s = string.format('%s[%d:%s] { x:%d y:%d w:%d h:%d [refresh:%s]',
        t.metacel, t.id, tostring(facename), t.x, t.y, t.w, t.h, tostring(t.refresh))
      io.write(pre, s)
      if t.mousefocusin then io.write('\n>>>>>>>>MOUSEFOCUSIN') end
      if t.font then
        io.write('\n', pre, '  @@', string.format('font[%s:%d]', t.font.name, t.font.size))
      end
    end
  end

  local celface = {
    [_metacelname] = 'cel',
    [_variations] = setmetatable({}, weak),
    [_registered] = {},
  }

  celface.__index = celface

  local metafaces = {
    ['cel'] = setmetatable(celface, celfacemt)
  }

  function getface(metacelname, name)
    local metaface = metafaces[metacelname]

    if not metaface then
      metaface = {
        [_metacelname] = metacelname,
        [_variations]=setmetatable({}, weak),
        [_registered] = {},
        __index = true,
      }
      metaface.__index = metaface

      setmetatable(metaface, celface)
      metafaces[metacelname] = metaface
    end

    local face = metaface

    if name then
      return face[_variations][name] or driver.getface(face, name)
    end

    return face
  end

  function newmetaface(metacelname, proto)
    local metaface = metafaces[metacelname]

    if metaface then
      setmetatable(metaface,  proto)
    else
      metaface = {
        [_metacelname] = metacelname,
        [_variations]=setmetatable({}, weak),
        [_registered] = {},
        __index = true,
      }
      metaface.__index = metaface
      setmetatable(metaface, proto)
      metafaces[metacelname] = metaface
    end

    return metaface
  end
end

local metacel = {}
do
  metacel[_name] = 'cel'
  metacel[_face] = getface('cel')
  metacel[_variations] = metacel[_face][_variations]
  metacel[_variations][metacel[_face]] = metacel[_face]
  metacel.metatable = {
    touch = touch,
    refresh = refresh, 
  }

  local celid = 1

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
      [_face] = face and (self[_variations][face] or metacel[_variations][face] or getface(self[_name], face)),
      [_celid] = celid,
    }
    celid = celid + 1
    return setmetatable(cel, self.metatable)
  end

  function metacel:assemble(t, cel)
    cel = cel or metacel:new(t.w, t.h, t.face)
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
          link:link(host, linker, xval, yval, option)
        end
      end
    end
  end

  function metacel:newfactory(t)
    local metacel = self
    local factory = {}

    if t then
      for k, v in pairs(t) do
        factory[k] = v
      end
    end

    factory.new = function(...)
      return metacel:new(...)
    end

    factory.newmetacel = function(name) 
      return metacel:newmetacel(name) 
    end

    local metatable = {__call = function (factory, t)
      return metacel:assemble(t)
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

    CEL.factories[factory] = true
    return factory
  end

  function metacel:getface(face)
    face = face and (self[_variations][face] or metacel[_variations][face] or getface(self[_name], face))
    return face or self[_face]
  end

  function metacel:setface(cel, face)
    return cel:refresh()
  end

  function metacel:__celfromstring(host, s)
    return M.label.new(s) 
  end

  function metacel:asyncall(name, ...)
    if self[name] then
      local t = {} --TODO WTF is this for???
      event:asyncall(self, name, t, ...)
      return t
    end
  end

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

    metatable.__index = function(t, k)
      local result = metatable[k]

      if result then 
        return result 
      end

      local raw = rawsub[k]

      if raw then 
        return rawget(t, raw) 
      end

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

    for k, v in pairs(self) do
      metacel[k] = v
    end

    metacel[_name] = name
    metacel.metatable = metatable
   
    metacel[_face] = newmetaface(name, self[_face])
    metacel[_variations] = metacel[_face][_variations]
    metacel[_variations][metacel[_face]] = metacel[_face]

    return metacel, metatable
  end
end

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

function stackformation:dolinker(host, link, linker, xval, yval)
  local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
  local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]
  local x, y, w, h = linker(host[_w], host[_h], ox, oy, ow, oh, xval, yval, minw, maxw, minh, maxh)

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

function stackformation:movelink(host, cel, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)
  if host and rawget(cel, _linker) then
    x, y, w, h = cel[_linker](host[_w], host[_h], x, y, w, h, rawget(cel, _xval), rawget(cel, _yval), minw, maxw, minh, maxh)
    x = modf(x)
    y = modf(y)
    w = floor(w)
    h = floor(h)

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

local metatable = metacel.metatable

do --metatable.__index
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

  function metatable.__index(t, k)
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
    elseif k == 'metacel' then return 'cel'
    --else print('looking for ', t, k)
    end
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
    id = _celid,
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

  --TODO remove
  function metatable.pget(cel, ...)
    local nargs = select('#', ...)
    local result = resultarrays[nargs] or {...}
    local request

    for i = 1, nargs do
      request = select(i, ...)
      result[i] = cel[map[request]]
    end

    return unpack(result, 1, nargs)
  end
end

do
  local cel_metacel = metacel
  --TODO doc
  function metatable:setface(face)
    local metacel = self[_metacel]
    local actual = face and (metacel[_variations][face] or cel_metacel[_variations][face] or getface(metacel[_name], face))
    --TODO this should be in driver
    if not actual and type(face) == 'table' then
      actual = self.face:new(face)
    end

    self[_face] = actual or metacel[_face]
    return metacel:setface(self, self[_face])
  end
end

--After this function returns cel must be linked to host(or an alternate host via __link), and by default will be the
--top link (a cel overriding this could change that by linking additional cels after,and should document that it does)
--unless cel is already linked to host or cel and host are the same cel
function metatable.link(cel, host, linker, xval, yval, option)
  if not host then error('host is nil') end
  if cel == host then error('attempt to link cel to self') end

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

    local nhost, nlinker, nxval, nyval, noption = host[_metacel]:__link(host, cel, linker, xval, yval, option)

    if nhost then
      if type(nlinker) == 'table' then
        linker, xval, yval = nlinker[1], nlinker[2], nlinker[3]
      else
        linker, xval, yval = nlinker, nxval, nyval
      end

      if host ~= nhost then
        host = nhost
        option = noption 
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

  refreshlink(host, cel)
  event:signal()

  return cel
end

--TODO support relinking with no linker 
function metatable.relink(cel, linker, xval, yval)
  local host = rawget(cel, _host)

  if not host then return cel end

  if host[_metacel].__relink == false then return cel, false end

  local ox, oy, ow, oh = cel[_x], cel[_y], cel[_w], cel[_h]

  if type(linker) == 'table' then
    linker, xval, yval = linker[1], linker[2], linker[3]
  end

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
      if type(nlinker) == 'table' then
        linker, xval, yval = nlinker[1], nlinker[2], nlinker[3]
      else
        linker, xval, yval = nlinker, nxval, nyval
      end
      if type(linker) ~= 'function' then linker = linkers[linker] end
    end
  end

  cel[_linker] = nil
  cel[_xval] = nil
  cel[_yval] = nil

  if host[_formation] and host[_formation].relink then
    host[_formation]:relink(host, cel, linker, xval, yval)
  else
    if linker then
      cel[_linker] = linker
      cel[_xval] = xval
      cel[_yval] = yval
      dolinker(host, cel, linker, xval, yval)
    end
  end

  event:signal()

  return cel, true
end

function metatable.unlink(cel)
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

    refreshunlink(host, cel)
    event:signal()
  end
  return cel
end

metatable.islinkedto = islinkedto

metatable.islinkedtoroot = function(cel)
  return islinkedto(cel, CEL.root)
end

--TODO change method name to float
--puts cel at top of hosts link stack
function metatable.raise(cel)
  local host = rawget(cel, _host)

  if not host then return cel end

  local formation = rawget(host, _formation)
  --TODO let formation implement raise
  if formation and formation.pick then 
    return cel 
  end

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

  refreshlink(host, cel)

  return cel
end

--puts cel at bottom of hosts link stack
--TODO change method to a generic name that has meanings for more than stackformation
function metatable.sink(cel)
  local host = rawget(cel, _host)

  if not host then return cel end

  local formation = rawget(host, _formation)
  --TODO let formation implement sink 
  if formation and formation.pick then 
    return cel 
  end

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

  refreshlink(host, cel)

  return cel
end

function metatable.move(cel, x, y, w, h)
  return (move(cel, x or cel[_x], y or cel[_y], w or cel[_w], h or cel[_h])) or cel
end

function metatable.resize(cel, w, h)
  return (move(cel, cel[_x], cel[_y], w or cel[_w], h or cel[_h])) or cel
end

function metatable.moveby(cel, x, y, w, h)
  return (move(cel, cel[_x] + (x or 0), cel[_y] + (y or 0), cel[_w] + (w or 0), cel[_h] + (h or 0))) or cel
end

function metatable.setlimits(cel, minw, maxw, minh, maxh, nw, nh)
  if cel[_metacel].__setlimits then
    minw, maxw, minh, maxh = cel[_metacel]:__setlimits(cel, minw, maxw, minh, maxh, nw, nh)
  end

  minw = max(floor(minw or 0), 0)
  maxw = max(floor(maxw or maxdim), minw)
  minh = max(floor(minh or 0), 0)
  maxh = max(floor(maxh or maxdim), minh)

  local ominw = cel[_minw]
  local omaxw = cel[_maxw]
  local ominh = cel[_minh]
  local omaxh = cel[_maxh]

  local w = nw or cel[_w]
  local h = nh or cel[_h]

  if w > maxw then w = maxw end
  if w < minw then w = minw end
  if h > maxh then h = maxh end
  if h < minh then h = minh end

  event:wait()

  local host = rawget(cel, _host)
  local formation = host and rawget(host, _formation)

  if formation then
    formation:setlinklimits(host, cel, minw, maxw, minh, maxh, w, h)
  else
    cel[_minw] = minw
    cel[_maxw] = maxw
    cel[_minh] = minh
    cel[_maxh] = maxh

    if w ~= cel[_w] or h ~= cel[_h] then
      cel:resize(w, h)
    elseif rawget(cel, _linker) then
      dolinker(host, cel, rawget(cel, _linker), rawget(cel, _xval), rawget(cel, _yval))
    end
  end

  event:signal()

  return cel
end

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

--TODO focus should be for all devices, except mouse type devices
do --metatable.takefocus
  local hosts do 
    local function nexthost(_, link)
      return rawget(link, _host)
    end

    function hosts(link)
      return nexthost, nil, link 
    end
  end

  local function takefocus(device, target)
    --TODO should not have to do seperate code path for root
    local device_focus = device[_focus]

    if target == device_focus[device_focus.n] then
      return
    end

    if target == CEL.root then
      for i = device_focus.n, 1, -1 do
        event:onblur(device_focus[i])
        device_focus[device_focus[i]] = nil
        device_focus[i] = nil
      end

      device_focus.n = 1
      device_focus[1] = CEL.root
      device_focus[CEL.root] = 1
      event:onfocus(CEL.root)
      return
    end

    local z = islinkedto(target, CEL.root)

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
      event:onblur(device_focus[i])
      device_focus[device_focus[i]] = nil
      device_focus[i] = nil
    end

    device_focus.n = z
    device_focus[z] = target
    device_focus[target] = z
    event:onfocus(target)

    for host in hosts(target) do
      if device_focus[host] then
        break
      end
      z = z - 1
      device_focus[z] = host
      device_focus[host] = z
      event:onfocus(host)
    end
  end

  function metatable.takefocus(cel, source)
    if source == mouse then
      return 
    end

    source = source or keyboard
    event:wait()
    takefocus(source, cel)
    --TODO only refresh if focus actually changed
    refresh(cel)
    event:signal()

    return cel, cel:hasfocus(source)
  end
end

--TODO return cel, success
function metatable.trapmouse(cel, onfail)
  local t = mouse[_trap]

  if t.trap == cel then
    return true
  end

  --if cel is already trapping mouse, through a descendant, don't let it trap
  if mouse[_trap][cel] then
    if onfail then onfail(cel, mouse, 'already trapped by link') end
    return false
  end
  --can't trap if mouse is not in cel
  if not cel:hasfocus(mouse) then
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

function metatable.hasmousetrapped(cel)
  return mouse[_trap].trap == cel
end

function metatable.freemouse(cel, reason)
  local t = mouse[_trap]

  if t.trap == cel then
    local onfail = t.onfail

    for k,v in pairs(t) do
      t[k] = nil
    end

    t[CEL.root] = true
    t.trap = CEL.root

    if onfail then onfail(cel, mouse, reason or 'freed') end
  end
  return cel
end

function metatable.disable(cel)
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
  end
  return cel
end

function metatable.enable(cel)
  if cel[_disabled] then
    cel[_disabled] = false
    refresh(cel)
  end
  return cel
end

function metatable.hide(cel)
  cel[_hidden] = true
  refresh(cel)
  return cel
end

function metatable.unhide(cel)
  cel[_hidden] = nil
  refresh(cel)
  return cel
end

function metatable.__tostring(cel)
  return cel[_metacel][_name]
end

function metatable.addlinks(cel, t)
  linkall(cel, t)
  return cel
end

function metatable:call(func, ...)
  return self, func(self, ...)
end

--TODO remove
function metatable.setappstatus(cel, appstatus)
  cel[_appstatus] = appstatus
  refresh(cel)
  return cel
end

--TODO remove
function metatable.getappstatus(cel)
  return cel[_appstatus]
end


do --metatable.flow, metatable.flowvalue, metatable.flowlink
  local function addflow(cel, flow, fx, fy, fw, fh, context, update, finalize, xval, yval, linker)
    flows[cel] = {
      context = context,
      ox = cel[_x], oy = cel[_y], ow = cel[_w], oh = cel[_h],
      fx = fx, fy = fy, fw = fw, fh = fh,
      flow = flow,
      startmillis = CEL.timer.millis,
      update = update, 
      finalize = finalize,
      xval = xval, 
      yval = yval, 
      linker = linker,
    }
  end

  local function addflowvalue(cel, flow, ov, fv, context, update, finalize)
    flows[cel] = {
      context = context,
      ox = ov,
      fx = fv,
      flow = flow,
      startmillis = CEL.timer.millis,
      update = update, 
      finalize = finalize,
    }
  end

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

  local function flowlinker(hw, hh, x, y, w, h, cel, flow)
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
end

function metatable.getflow(cel, flow)
  local celface = cel[_face] or cel[_metacel][_face]
  if celface.flow then
    return celface.flow[flow]
  end
end

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

  local context = t.context
  local ox, oy, ow, oh = t.ox, t.oy, t.ow, t.oh
  local fx, fy, fw, fh = t.fx, t.fy, t.fw, t.fh 
  local flow = t.flow 
  local update = t.update 
  local finalize = t.finalize 

  context.duration = CEL.timer.millis - t.startmillis
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

do --CEL.root
  local metacel, metatable = metacel:newmetacel('root')

  metatable.raise = false
  metatable.link = false
  metatable.relink = false
  metatable.unlink = false

  CEL.root = metacel:new(0, 0)

  --TODO hax, need to give root its own metable to avoid this hack, see getX
  CEL.root.X = 0 
  CEL.root.Y = 0

  --TODO not very elegent to put mouse and keyboard initialization in here
  CEL.mouse[_trap] = {trap = CEL.root}

  CEL.root:takefocus() --TODO why is this here
end 

CEL.metacel = metacel
CEL.describe = describe
CEL.touch = touch
CEL.celmoved = celmoved
CEL.testlinker = testlinker 
CEL.getface = getface
CEL.pick = pick
