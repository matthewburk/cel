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

local _brace = {}
local _rebrace = {}
local _reform = {}
local _links = {}
local _gap = {}
local _influx = {}
local _fluxh = {}
local _fluxw = {}
local _fluxminw = {}

local colformation = {}

local math = math
local table = table

--binary search
--TODO change to interpolating search
local function indexof(sequence, item)
  local floor = math.floor
  local t = sequence[_links]
  local gap = sequence[_gap]
  local istart,iend,imid = 1,#t,0
  local sequencepos = _y
  local sequencedim = _h
  local inval = item[sequencepos]

  while istart <= iend do
    imid = floor( (istart+iend)/2 )
    local value = t[imid][sequencepos]
    if inval == value then
      return imid
    elseif inval < value then
      iend = imid - 1
    else
      istart = imid + 1
    end
  end
end

local function pick(t, valueindex, rangeindex, gap, inval)
  local floor = math.floor
  local istart, iend, imid = 1, #t, 0

  while istart <= iend do
    imid = floor( (istart+iend)/2 )
    local value = t[imid][valueindex]
    local range = t[imid][rangeindex] + gap 
    if inval >= value and inval < value + range then
      return t[imid], imid
    elseif inval < value then
      iend = imid - 1
    else
      if not (inval >= value + range) then
        assert(inval >= value + range)
      end
      istart = imid + 1
    end
  end
end

do --colformation.reconcile
  local clamp = M.util.clamp

  function colformation:reconcile(host, force)
    if host[_influx] and host[_influx] > 0 and not force then  return end
     
    --local _x, _y, _w, _h = _x, _y, _w, _h
    local links = host[_links]

    if host[_reform] then
      local gap = host[_gap]
      local  y = 0
      local link
      for i = 1, #links do
        link = links[i] 
        link[_y] = y 
        y = y + link[_h] + gap
      end

      host[_fluxh] = math.max(0, y - gap) 
      host[_reform] = nil
    end

    if host[_rebrace] then
      --local _linker, _xval, _yval = _linker, _xval, _yval
      --local _brace = _brace
      local link
      local brace
      local edge = 0
      local min = 0
      local hostedge = host[_fluxminw]
      for i = 1, #links do
        link = links[i]

        edge = self:getbraceedge(host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

        if edge > min then
          min = edge
          host[_brace] = link
        end

        if edge == hostedge then
          break
        end
      end
      host[_fluxminw] = min
      host[_fluxw] = min
      host[_rebrace] = false
    end

    local minw, maxw = host[_fluxminw], maxdim 
    local minh, maxh = host[_fluxh], host[_fluxh] 
    local w, h = host[_fluxw], host[_fluxh]

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end   

    event:wait()

    host[_metacel]:setlimits(host, minw, maxw, minh, maxh)

    --colformation expects that the minh, maxh always equals the h, so does
    --not respond to changes in its height, because they can only come from 
    --itself, this mean the col metacel needs to keep that in mind when reacting to a __resize
    --or else the formation breaks.
    --also setlimts should change the height, col metacel changes that by changing minh
    if host[_w] ~= w then
      host:resize(w)
    end

    event:signal()
  end
end

do --colformation.moved
  --called anytime host is moved by any method
  --local _linker, _xval, _yval = _linker, _xval, _yval
  function colformation:moved(host, x, y, w, h, ox, oy, ow, oh)
    if w ~= ow then
      event:onresize(host, ow, oh)
      local _linker, _xval, _yval = _linker, _xval, _yval
      local links = host[_links]
      host:beginflux(false)
      for i = 1, #links do
        local link = links[i] 
        if rawget(link, _linker) then
          self:dolinker(host, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
        end
      end
      host:endflux(false)
      if host[_metacel].__resize then
        host[_metacel]:__resize(host, ow, oh)
      end
    elseif h ~= oh then
      event:onresize(host, ow, oh)
      if host[_metacel].__resize then
        host[_metacel]:__resize(host, ow, oh)
      end
    end
  end
end

do --colformation.getbraceedge
  local math = math
  function colformation:getbraceedge(host, link, linker, xval, yval)
    if not linker then
      return link[_x] + link[_w]
    else
      local minw, maxw = link[_minw] or 0, link[_maxw] or maxdim
      local minh, maxh = link[_minh] or 0, link[_maxh] or maxdim
      local x, _, w, _ = linker(0, link[_h], link[_x], 0, link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

      if w < minw then w = minw end
      if w > maxw then w = maxw end

      x = math.modf(x)
      w = math.floor(w)

      return math.max(x + w, w, -x)
    end
  end
end

do --colformation.link
  local math = math
  local table = table
  function colformation:link(host, link, linker, xval, yval, index)
    --put in array 
    if index and index <= #host[_links] then
      table.insert(host[_links], index, link)
      host[_reform] = true
    else
      index = #host[_links] + 1
      host[_links][index] = link
    end

    --set _y and increase host height
    if host[_fluxh] == 0 then
      link[_y] = 0 
      host[_fluxh] = link[_h]
    else
      link[_y] = host[_gap] + host[_fluxh] 
      host[_fluxh] = host[_fluxh] + link[_h] + host[_gap]
    end

    local edge

    --set _x
    if not linker then
      link[_x] = xval <= 0 and 0 or math.floor(xval)
      edge = link[_x] + link[_w]
      if edge > host[_fluxminw] then 
        host[_brace] = link 
        host[_fluxminw] = edge
        if host[_fluxw] < edge then
          host[_fluxw] = edge
        end
      end
    else 
      edge = self:getbraceedge(host, link, linker, xval, yval)
      if edge > host[_fluxminw] then 
        host[_brace] = link 
        host[_fluxminw] = edge
        if host[_fluxw] < edge then
          host[_fluxw] = edge
        end
      end
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      self:dolinker(host, link, linker, xval, yval)
    end

    --increase host width to edge
    

    event:onlink(host, link, index)

    self:reconcile(host)
  end
end

do --colformation:linker
  local math = math
  function colformation:linker(host, link, linker, xval, yval, x, y, w, h, minw, maxw, minh, maxh)
    --assert(linker)
    local hw, hfw = host[_w], host[_fluxw]
    if hfw > hw then hw = hfw end
    local ow = w
    local _
    --hh is link.h we ignore return y and h becuase the linker must not alter them
    x, _, w, _ = linker(hw, h, x, 0, w, h, xval, yval, minw, maxw, minh, maxh)
    x = math.modf(x)
    w = math.floor(w)

    --if w ~= ow then
      if w > hw then w = hw end
    --end

    if x + w > hw then x = hw - w end

    if x < 0 then x = 0 end
    
    return x, link[_y], w, h
  end
end

do --colformation.testlinker
  local math = math
  local selflinker = colformation.linker
  function colformation:testlinker(host, link, linker, xval, yval)
    assert(linker)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw] or 0, link[_maxw] or maxdim, link[_minh] or 0, link[_maxh] or maxdim

    local x, y, w, h = ox, oy, ow, oh
    do
      local hw, hh = host[_w], h 
      local ow = w
      --hh is link.h we ignore return y and h becuase the linker must not alter them
      x, _, w, h = linker(hw, h, x, 0, w, h, xval, yval, minw, maxw, minh, maxh)
      x = math.modf(x)
      w = math.floor(w)
      h = math.floor(h)

      if w > hw then w = hw end
      if h > hh then h = hh end

      if x + w > hw then x = hw - w end
      
      x, y, w, h = math.max(x, 0), link[_y], w, h
    end

    --enforce min/max
    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end

    return math.modf(x), oy, math.floor(w), h
  end
end

--[[
do --colformation.testlinker
  local math = math
  local selflinker = colformation.linker
  function colformation:testlinker(host, link, linker, xval, yval)
    assert(linker)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw] or 0, link[_maxw] or maxdim, link[_minh] or 0, link[_maxh] or maxdim

    local x, _, w, _ = selflinker(self, host, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    --enforce min/max
    if w < minw then w = minw end
    if w > maxw then w = maxw end

    return math.modf(x), oy, math.floor(w), oh
  end
end
--]]

do --colformation.dolinker
  --called anytime the link[_linker] needs to be enforced
  local celmoved = celmoved
  local selflinker = colformation.linker
  function colformation:dolinker(host, link, linker, xval, yval)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw] or 0, link[_maxw] or maxdim, link[_minh] or 0, link[_maxh] or maxdim

    local x, _, w, _ = selflinker(self, host, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    if w < minw then w = minw end
    if w > maxw then w = maxw end

    if x ~= ox then link[_x] = x end
    if w ~= ow then link[_w] = w end

    if x ~= ox or w ~= ow then
      celmoved(host, link, x, oy, w, oh, ox, oy, ow, oh)
    end
  end
end

---[[
do --colformation.linklimitschanged
  function colformation:linklimitschanged(host, link, minw, maxw, minh, maxh)
    if minw < link[_w] and link == host[_brace] then
      local edge = self:getbraceedge(host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
      if edge < host[_fluxminw] then
        host[_brace] = nil
        host[_rebrace] = true
        self:reconcile(host)
      end
    end
  end
end
--]]

do --colformation.movelink
  --movelink should only be called becuase move was explicitly called, make sure that is the case
  local math = math
  local selflinker = colformation.linker
  function colformation:movelink(host, link, x, y, w, h)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw = link[_minw] or 0, link[_maxw] or maxdim
    local minh, maxh = link[_minh] or 0, link[_maxh] or maxdim

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end    

    if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return link end

    --always apply the colformation linker
    if rawget(link, _linker) then
      x, y, w, h = selflinker(self, host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                              x, y, w, h, minw, maxw, minh, maxh)
    end

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end    

    if x ~= ox then x = math.max(0, math.modf(x)); link[_x] = x; end
    --y is set by layout, can't move y
    if w ~= ow then w = math.floor(w); link[_w] = w; end
    if h ~= oh then h = math.floor(h); link[_h] = h; end

    local reconcile = false

    if h ~= oh then
      host[_reform] = true --TODO same thing in sequencex
      reconcile = true
    end

    local edge = self:getbraceedge(host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

    if edge > host[_fluxminw] then
      host[_fluxminw] = edge
      host[_brace] = link
      reconcile = true
    elseif host[_brace] == link and edge < host[_fluxminw] then
      host[_brace] = nil
      host[_rebrace] = true
      reconcile = true
    end

    event:wait()

    if x ~= ox or w ~= ow or h ~= oh then
      celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
    end

    if reconcile then
      self:reconcile(host)
    end

    event:signal()

    return link
  end
end

do --colformation.unlink
  local math = math
  function colformation:unlink(host, link)
    --TODO make this work when clearing, in which case host[_links] is empty
    --TODO always make sure reform is done before search
    local index = indexof(host, link)
    assert(index)
    table.remove(host[_links], index)

    if link == host[_brace] then
      host[_brace] = nil
      host[_rebrace] = true 
    end

    host[_reform] = true

    if host[_metacel].__unlink then
      host[_metacel]:__unlink(host, link, index)
    end

    self:reconcile(host)
  end
end

do --colformation.pick
  function colformation:pick(host, x, y)
    return pick(host[_links], _y, _h, host[_gap], y)
  end
end

do --colformation.describeslot
  local slotface = M.face[_metafaces]['cel']

  function colformation:describeslot(seq, host, gx, gy, gl, gt, gr, gb, index, link, hasmouse)
    if not seq[_metacel].__describeslot then
      return describe(link, host, gx, gy, gl, gt, gr, gb)
    else
      gy = gy + link[_y] --TODO clamp to maxint

      if gy > gt then gt = gy end
      if gy + link[_h] < gb then gb = gy + link[_h] end

      if gr <= gl or gb <= gt then return end

      local t = {
        id = 0,
        metacel = false,
        face = slotface,
        host = host,
        x = gx,
        y = gy,
        w = seq[_w],
        h = link[_h],
        mousefocus = false,
        mousefocusin = hasmouse, --TODO only set if link doesn't have mouse
        index = index,
        clip = {l = gl, r = gr, t = gt, b = gb},
      }

      seq[_metacel]:__describeslot(seq, link, index, t)

      do
        local y = link[_y] 
        link[_y] = 0 
        t[1] = describe(link, t, gx, gy, gl, gt, gr, gb)
        link[_y] = y
      end

      return t
    end
  end
end

do --colformation.describelinks
  function colformation:describelinks(seq, host, gx, gy, gl, gt, gr, gb)
    local links = seq[_links]
    local nlinks = #links

    if nlinks > 0 then
      local _, a = self:pick(seq, gl - gx, gt - gy)
      local _, b = self:pick(seq, gr - gx, gb - gy)

      if a and a > 1 then a = a - 1 end
      if b and b < nlinks then b = b + 1 end

      a = a or 1
      b = b or nlinks

      local vcel
      if mouse[_focus][seq] then
        local x, y = M.translate(seq, _ENV.root, 0, 0)
        vcel = self:pick(seq, mouse[_x] - x, mouse[_y] - y) --TODO allow pick to accept a search range
      end

      local i = 1
      for index = a, b do
        host[i] = self:describeslot(seq, host, gx, gy, gl, gt, gr, gb, index, links[index], vcel == links[index])
        i = host[i] and i + 1 or i
      end
    end
  end
end

local metacel, metatable = metacel:newmetacel('sequence.y')

do --metatable.clear
  function metatable.clear(sequence)
    event:wait()
    local links = sequence[_links] 
    sequence[_links] = nil 

    for i=1, #links do
      links[i]:unlink()
    end

    sequence[_links] = {}
    event:signal()
    return sequence
  end
end

--TODO use _next and _prev for all links so iteration is fast
do --metatable.ilinks
  local function it(sequence, i)
    i  = i + 1
    local link = sequence[_links][i]
    if link then
      return i, link
    end
  end

  function metatable.ilinks(sequence)
    return it, sequence, 0
  end
end

do --metatable.len
  function metatable.len(sequence)
    return #sequence[_links]
  end
end

do --metatable.get
  function metatable.get(sequence, index)
    return sequence[_links][index]
  end
end

do --metatable.flux
  --when flux is started sequence is is reconciled(so it is no longer in flux) 
  --while in flux adjustments don't happen, before flux retruns it is reconciled 
  function metatable.flux(sequence, callback, ...)
    sequence[_influx] = (sequence[_influx] or 0) + 1
    ---[[don't force a reconcile if already in flux
    colformation:reconcile(sequence, true)
    --]]

    if callback then
      callback(...)
      colformation:reconcile(sequence, true)
    end

    sequence[_influx] = sequence[_influx] - 1
    return sequence
  end
end

do --metatable.beginflux
  --TODO remove this, or put it in metacel too easy to fuck up
  function metatable.beginflux(sequence, reconcile)
    sequence[_influx] = (sequence[_influx] or 0) + 1
    if reconcile then 
      colformation:reconcile(sequence, true) 
    end
    return sequence
  end
end

do --metatable.endflux
  --TODO remove this, or put it in metacel too easy to fuck up
  function metatable.endflux(sequence, force)
    sequence[_influx] = sequence[_influx] - 1
    if force == nil then force = true end
    colformation:reconcile(sequence, force)
    return sequence
  end
end

do --metatable.next
  function metatable.next(sequence, item)
    if item[_host] ~= sequence then return nil end

    local index = indexof(sequence, item)

    if index then
      return sequence[_links][1 + index]
    end
  end
end

do --metatable.prev
  function metatable.prev(sequence, item)
    if item[_host] ~= sequence then return nil end

    local index = indexof(sequence, item)

    if index then
      return sequence[_links][-1 + index]
    end
  end
end

do --metatable.insert
  function metatable.insert(sequence, index, item)
    if item then
      item:link(sequence, nil, nil, nil, index)
    else
      item = index
      item:link(sequence)
    end
    return sequence
  end
end

do --metatable.remove
  function metatable.remove(sequence, index)
    local item = sequence[_links][index]

    if item then
      item:unlink()
    end
    return sequence
  end
end

do --metatable.indexof
  metatable.indexof = function(sequence, item)
    if item[_host] == sequence then 
      local i = indexof(sequence, item)

      if sequence[_links][i] == item then
        return i
      else
        colformation:reconcile(sequence, true)
        return indexof(sequence, item)
      end
    end
  end
end

do --metatable.pick
  --returns item, index
  function metatable.pick(sequence, x, y)
    return pick(sequence[_links], _y, _h, sequence[_gap], y)
  end
end

--[[
do --metacel.onresize()
  function metacel:onresize(sequence)
    sequence:beginflux()
    self:asyncall('endresize', sequence)
  end

  function metacel:endresize(sequence)
    sequence:endflux()
  end
end
--]]

do --metacel.onmousemove
  function metacel:onmousemove(sequence, x, y)
    local vx, vy = mouse:vector()
    local a = sequence:pick(x, y)
    local b = sequence:pick(x - vx, y - vy)
    if a ~= b then
      sequence:refresh()
    end
  end
end

do --metacel.new, metacel.compile
  local _new = metacel.new
  function metacel:new(gap, face)
    --TODO note somewhere that we use self:getface so that it is going through topmost metacel
    local sequence = _new(self, 0, 0, self:getface(face))
    sequence[_reform] = false 
    sequence[_brace] = false 
    sequence[_links] = {}
    sequence[_gap] = gap or 0
    sequence[_minw] = 0
    sequence[_minh] = 0
    sequence[_maxh] = 0
    sequence[_fluxw] = 0
    sequence[_fluxh] = 0
    sequence[_fluxminw] = 0
    sequence[_formation] = colformation
    return sequence
  end

  local _compile = metacel.compile
  function metacel:compile(t, sequence)
    sequence = sequence or metacel:new(t.gap, t.face)
    --sequence[_influx] = 1
    --sequence.onchange = t.onchange
    _compile(self, t, sequence)
    --sequence[_influx] = 0 
    --colformation:reconcile(sequence)
    return sequence
  end
end

return metacel:newfactory()

end
