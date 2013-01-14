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

local metatable = _ENV.metacel.metatable

do --metatable.setlimits
  local floor = math.floor
  local function max(a, b) if a >= b then return a else return b end end

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

    cel[_minw] = minw
    cel[_maxw] = maxw
    cel[_minh] = minh
    cel[_maxh] = maxh

    if not (ominw ~= minw or omaxw ~= maxw or ominh ~= minh or omaxh ~= maxh) then
      return cel
    end

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
        formation:linklimitschanged(host, cel, ominw, omaxw, ominh, omaxh)
      end
    end

    --this resizes the cel if the limits now constrain it
    --but also need to resize if the limits unconstrain it
    --if i always resize it makes it really slow under certain conditions
    --like a sequence of wrapping text
    --don't do this, the formation should handle it only, so just do it for the stackformation
    --or do it when there is no host
    if w ~= cel[_w] or h ~= cel[_h] then
      cel:resize(w, h)
    elseif host and rawget(cel, _linker) then
      dolinker(host, cel, rawget(cel, _linker), rawget(cel, _xval), rawget(cel, _yval))
    end

    event:signal()
    return cel
  end
end

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

do --metatable.addlinks
  function metatable.addlinks(cel, t)
    linkall(cel, t)
    return cel
  end
end

do --metatable.join
  local joinlinker = joinlinker
  function metatable.join(cel, anchor, joiner, xval, yval)
    if type(joiner) ~= 'function' then joiner = joiners[joiner] end
    if type(joiner) ~= 'function' then error('joiner is not a function') end

    local host = rawget(anchor, _host)
    if not host then
      return error('cannot join an unlinked anchor', cel, anchor)
    end

    while rawget(host, _formation) and host[_formation].__nojoin do
      host = rawget(host, _host)
      if not host then
        return error('cannot join an unhosted anchor', cel, anchor)
      end
    end

    event:wait()

    if rawget(cel, _host) == host then
      if rawget(cel, _linker) == joinlinker then
        metatable.relink(cel, joinlinker, cel[_xval], {joinedcel=cel, xval=xval, yval=yval, joiner=joiner, anchor=anchor})
      else
        metatable.relink(cel, joinlinker, {joinedcel=cel, xval=xval, yval=yval, joiner=joiner, anchor=anchor}, nil)
      end
    else
      metatable.link(cel, host, joinlinker, {joinedcel=cel, xval=xval, yval=yval, joiner=joiner, anchor=anchor}, nil)
    end

    if joins[anchor] then
      joins[anchor][cel] = true
    else
      joins[anchor] = setmetatable({[cel]=true}, {__mode='k'})
    end

    event:signal()

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

    while rawget(host, '__link') do
      host = rawget(host, '__link')
    end

    if not host or not host[_x] then error('retargeted host is invalid') end

    --[[ don't do this becuase option would be ignored, document that this will unlink the cel from its host and link it again
    --with new linker and option, use relink to avoid the unlink
    if rawget(cel, _host) == host then
      return metatable.relink(cel, linker, xval, yval)
    end
    --]]

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
end

do --metatable.relink
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
end

do --metatable.unlink
  function metatable.unlink(cel)
    local host = rawget(cel, _host)
    if host then
      event:wait()

      --unjoin 
      if joins[cel] then --if this cel is an anchor, unjoin all the cels joined to it
        for joinedcel in pairs(joins[cel]) do
          joinedcel:relink()  --TODO just remove the joins to this anchor, not all
        end
        joins[cel]=nil
      end
      --if this cel is joined to an anchor, remove join from anchor to this cel
      if rawget(cel, _linker) == joinlinker then
        local anchor = cel[_yval]
        joins[anchor][cel] = nil
      end
      --TODO remove join from anchor2 to this cel

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

do --metatable.hide
  function metatable.hide(cel)
    cel[_hidden] = true
    refresh(cel)
    return cel
  end
end

do --metatable.unhide
  function metatable.unhide(cel)
    cel[_hidden] = nil
    refresh(cel)
    return cel
  end
end

do --metatable.setappstatus
  local _appstatus = _appstatus
  function metatable.setappstatus(cel, appstatus)
    cel[_appstatus] = appstatus
    refresh(cel)
    return cel
  end

  function metatable.getappstatus(cel)
    return cel[_appstatus]
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
    local celface = cel[_face] or cel[_metacel][_face]
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

    return cel, cel:hasfocus(source)
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
        event:onblur(device_focus[i])
        device_focus[device_focus[i]] = nil
        device_focus[i] = nil
      end

      device_focus.n = 1
      device_focus[1] = _ENV.root
      device_focus[_ENV.root] = 1
      event:onfocus(_ENV.root)
      assert(_ENV.root)
      return
    end

    --TODO don't call out through metatable, give opportunity to mess it up
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

    local formation = rawget(host, _formation)
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
end

do --metatable.sink
  --puts cel at bottom of hosts link stack
  --TODO change method to a generic name that has meanings for more than stackformation
  function metatable.sink(cel)
    local host = rawget(cel, _host)

    if not host then return cel end

    local formation = rawget(host, _formation)
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
end

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

  --local rawget = rawget
  --local getX, getY = getX, getY

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

function metatable:dump()
  local F = string.format
  local name = self[_metacel][_name]

  print(self, name)
  print(self, F('x%d', self.x), F('y%d', self.y), F('w%d', self.w), F('h%d', self.h))
  print(self, F('minw%d', self.minw), F('maxw%d', self.maxw))
  print(self, F('minh%d', self.minh), F('maxh%d', self.maxh))
  print(self, 'PAIRS')
  for k, v in pairs(self) do
    print(' ', k, v)
  end

  if self[_metacel].__dump then
    self[_metacel]:__dump(self)
  end
end
