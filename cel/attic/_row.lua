return function (_ENV, M)
setfenv(1, _ENV)

local _brace = {}
local _rebrace = {}
local _reform = {}
local _links = {}
local _gap = {}
local _influx = {}
local _fluxh = {}
local _fluxw = {}
local _fluxminh = {}
local _slotface = {}

local rowformation = {}
local gridformation = {}

local math = math
local table = table

--binary search
--TODO change to interpolating search
local function indexof(sequence, item)
  local floor = math.floor
  local t = sequence[_links]
  local gap = sequence[_gap]
  local istart,iend,imid = 1,#t,0
  local sequencepos = _x
  local sequencedim = _w
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

do --rowformation.reconcile
  local clamp = M.util.clamp

  function rowformation:reconcile(host, force)
    if host[_influx] and host[_influx] > 0 and not force then  return end
     
    local links = host[_links]

    if host[_reform] then
      local gap = host[_gap]
      local  x = 0
      local link
      for i = 1, #links do
        link = links[i] 
        link[_x] = x 
        x = x + link[_w] + gap
      end

      host[_fluxw] = math.max(0, x - gap) 
      host[_reform] = nil
    end

    if host[_rebrace] then
      local link
      local brace
      local edge = 0
      local min = 0
      local hostedge = host[_fluxminh]
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
      host[_fluxminh] = min
      host[_fluxh] = min
      host[_rebrace] = false
    end

    local minw, maxw = host[_fluxw], host[_fluxw] 
    local minh, maxh = host[_fluxminh], maxdim 
    local w, h = host[_fluxw], host[_fluxh]

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end   

    event:wait()

    host[_metacel]:setlimits(host, minw, maxw, minh, maxh)

    if w ~= host[_w] or h ~= host[_h] then
      host:resize(w, h)
    end

    event:signal()
  end
end

do --rowformation.moved
  --called anytime host is moved by any method
  local _linker, _xval, _yval = _linker, _xval, _yval
  function rowformation:moved(host, x, y, w, h, ox, oy, ow, oh)
    if h ~= oh then
      event:onresize(host, ow, oh)
      local _linker, _xval, _yval = _linker, _xval, _yval
      local links = host[_links]
      for i = 1, #links do
        local link = links[i] 
        if rawget(link, _linker) then
          self:dolinker(host, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
        end
      end
      if host[_metacel].__resize then
        host[_metacel]:__resize(host, ow, oh)
      end
    elseif w ~= ow then
      event:onresize(host, ow, oh)
      if host[_metacel].__resize then
        host[_metacel]:__resize(host, ow, oh)
      end
    end
  end
end

do --rowformation.getbraceedge
  local math = math
  function rowformation:getbraceedge(host, link, linker, xval, yval)
    if not linker then
      return link[_y] + link[_h]
    else
      local minw, maxw = link[_minw] or 0, link[_maxw] or maxdim
      local minh, maxh = link[_minh] or 0, link[_maxh] or maxdim
      local _, y, _, h = linker(link[_w], 0, 0, link[_y], link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

      if h < minh then h = minh end
      if h > maxh then h = maxh end

      y = math.modf(y)
      h = math.floor(h)

      return math.max(y + h, h, -y)
    end
  end
end

do --rowformation.link
  local math = math
  local table = table
  function rowformation:link(host, link, linker, xval, yval, index)
    --put in array
    if not index then
      index = #host[_links] + 1
      host[_links][index] = link
    elseif index <= #host[_links] then
      table.insert(host[_links], index, link)
      host[_reform] = true
    else
      index = #host[_links] + 1
      host[_links][index] = link
    end

    --set _x and increase host width 
    if host[_fluxw] ~= 0 then
      link[_x] = host[_gap] + host[_fluxw] 
      host[_fluxw] = host[_fluxw] + link[_w] + host[_gap]
    else
      link[_x] = 0 
      host[_fluxw] = link[_w]
    end

    --set _y
    if not linker then
      link[_y] = yval <= 0 and 0 or math.floor(yval)
    else 
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      self:dolinker(host, link, linker, xval, yval)
    end

    local edge
    if linker then 
      edge = self:getbraceedge(host, link, linker, xval, yval)
    else
      edge = link[_y] + link[_h]
    end

    --increase host height to edge
    if edge > host[_fluxminh] then 
      host[_brace] = link 
      host[_fluxminh] = edge
      if host[_fluxh] < edge then
        host[_fluxh] = edge
      end
    end


    event:onlink(host, link, index)

    self:reconcile(host)
  end
end

do --rowformation:linker
  local math = math
  function rowformation:linker(host, link, linker, xval, yval, x, y, w, h, minw, maxw, minh, maxh)
    if linker then
      local hh, _ = host[_h], nil
      local oh = h
      --hw is link.w we ignore return x and w becuase the linker must not alter them
      _, y, _, h = linker(w, hh, 0, y, w, h, xval, yval, minw, maxw, minh, maxh)
      y = math.modf(y)
      h = math.floor(h)

      if h ~= oh then
        if h > hh then h = hh end
      end

      if y + h > hh then y = hh - h end
    end
    
    if y < 0 then y = 0 end

    return link[_x], y, w, h
  end
end

do --rowformation.testlinker
  local math = math
  function rowformation:testlinker(host, link, linker, xval, yval)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw] or 0, link[_maxw] or maxdim, link[_minh] or 0, link[_maxh] or maxdim

    local _, y, _, h = self:linker(host, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    --enforce min/max
    if h ~= oh then
      if h < minh then h = minh end
      if h > maxh then h = maxh end
    end

    return ox, math.modf(y), ow, math.floor(h)
  end
end

do --rowformation.dolinker
  --called anytime the link[_linker] needs to be enforced
  local celmoved = celmoved
  local selflinker = rowformation.linker
  function rowformation:dolinker(host, link, linker, xval, yval)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw] or 0, link[_maxw] or maxdim, link[_minh] or 0, link[_maxh] or maxdim

    local _, y, _, h = selflinker(self, host, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    if h < minh then h = minh end
    if h > maxh then h = maxh end

    if y ~= oy then link[_y] = y end
    if h ~= oh then link[_h] = h end

    if y ~= oy or h ~= oh then
      celmoved(host, link, ox, y, ow, h, ox, oy, ow, oh)
    end
  end
end

do --rowformation.movelink
  --movelink should only be called becuase move was explicitly called, make sure that is the case
  local math = math
  function rowformation:movelink(host, link, x, y, w, h)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw = link[_minw] or 0, link[_maxw] or maxdim
    local minh, maxh = link[_minh] or 0, link[_maxh] or maxdim

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end    

    if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return link end

    --always apply the rowformation linker
    x, y, w, h = self:linker(host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                             x, y, w, h, minw, maxw, minh, maxh)
    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end    

    --don't need to check x, it can't change, enforced by self:linker
    if y ~= oy then y = math.modf(y); link[_y] = y; end
    if w ~= ow then w = math.floor(w); link[_w] = w; end
    if h ~= oh then h = math.floor(h); link[_h] = h; end

    local reconcile = false

    if w ~= ow then
      host[_reform] = true
      reconcile = true
    end

    local edge = self:getbraceedge(host, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

    if edge > host[_fluxminh] then
      host[_fluxminh] = edge
      host[_brace] = link
      reconcile = true
    elseif host[_brace] == link and edge < host[_fluxminh] then
      host[_brace] = nil
      host[_rebrace] = true
      reconcile = true
    end

    event:wait()

    if y ~= oy or w ~= ow or h ~= oh then
      celmoved(host, link, x, y, w, h, ox, oy, ow, oh)
    end

    if reconcile then
      self:reconcile(host)
    end

    event:signal()

    return link
  end
end

do --rowformation.unlink
  local math = math
  function rowformation:unlink(host, link)
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

do --rowformation.pick
  function rowformation:pick(host, x, y)
    return pick(host[_links], _x, _w, host[_gap], x)
  end
end

do --rowformation.describeslot
  function rowformation:describeslot(seq, host, gx, gy, gl, gt, gr, gb, index, link, hasmouse)
    if not seq[_metacel].__describeslot then
      return describe(link, host, gx, gy, gl, gt, gr, gb)
    else
      gx = gx + link[_x] --TODO clamp to maxint

      if gx > gl then gl = gx end
      if gx + link[_w] < gr then gr = gx + link[_w] end

      if gr <= gl or gb <= gt then return end

      local t = {
        id = 0,
        metacel = 'sequence.x.slot',
        face = seq[_slotface],
        host = host,
        x = gx,
        y = gy,
        w = link[_w],
        h = seq[_h],
        mouse = hasmouse,
        mousefocus = hasmouse, --TODO only set if link doesn't have mouse
        index = index,
        clip = {l = gl, r = gr, t = gt, b = gb},
      }

      seq[_metacel]:__describeslot(seq, link, index, t)

      do
        local x = link[_x] 
        link[_x] = 0 
        t[1] = describe(link, t, gx, gy, gl, gt, gr, gb)
        link[_x] = x
      end

      return t
    end
  end
end

do --rowformation.describelinks
  function rowformation:describelinks(seq, host, gx, gy, gl, gt, gr, gb)
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
        local x, y = M.translate(seq, M.root, 0, 0)
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

local metacel, metatable = metacel:newmetacel('sequence.x')

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
  end
end

do --metatable.items
  function metatable.items(sequence)
    return ipairs(sequence[_links])
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
    rowformation:reconcile(sequence, true)

    if callback then
      callback(...)
      rowformation:reconcile(sequence, true)
    end

    sequence[_influx] = sequence[_influx] - 1
  end
end

do --metatable.beginflux
  --TODO remove this, or put it in metacel too easy to fuck up
  function metatable.beginflux(sequence)
    sequence[_influx] = (sequence[_influx] or 0) + 1
    rowformation:reconcile(sequence, true)
  end
end

do --metatable.endflux
  --TODO remove this, or put it in metacel too easy to fuck up
  function metatable.endflux(sequence)
    sequence[_influx] = sequence[_influx] - 1
    rowformation:reconcile(sequence, true)
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
  end
end

do --metatable.remove
  function metatable.remove(sequence, index)
    local item = sequence[_links][index]

    if item then
      item:unlink()
    end
  end
end

do --metatable.indexof
  metatable.indexof = function(sequence, item)
    if item[_host] == sequence then 
      return indexof(sequence, item)
    end
  end
end

do --metatable.pick
  --returns item, index
  function metatable.pick(sequence, x, y)
    return pick(sequence[_links], _x, _w, sequence[_gap], x)
  end
end

do --matacel.onmousemove
  function metacel:onmousemove(sequence, x, y)
    local vx, vy = mouse:vector()
    local a = sequence:pick(x, y)
    local b = sequence:pick(x - vx, y - vy)
    if a ~= b then
      sequence:refresh()
    end
  end
end

local layout = {
  gap = 0,
  slotface = M.face {
    metacel = 'sequence.x.slot',
  } 
}

do --metacel.new, metacel.compile
  local _new = metacel.new

  function metacel:new(gap, face)
    face = self:getface(face)
    local layout = face.layout or layout
    local sequence = _new(self, 0, 0, face)
    sequence[_reform] = false 
    sequence[_brace] = false 
    sequence[_links] = {}
    sequence[_gap] = gap or layout.gap or 0
    sequence[_minw] = 0
    sequence[_maxw] = 0
    sequence[_minh] = 0
    sequence[_fluxw] = 0
    sequence[_fluxh] = 0
    sequence[_fluxminh] = 0
    sequence[_slotface] = layout.slotface
    sequence[_formation] = rowformation
    return sequence
  end

  local _compile = metacel.compile
  function metacel:compile(t, sequence)
    sequence = sequence or metacel:new(t.gap, t.face)
    sequence[_influx] = 1
    sequence.onchange = t.onchange
    _compile(self, t, sequence)
    sequence[_influx] = 0 
    rowformation:reconcile(sequence, true)
    return sequence
  end
end

return M.newfactory(metacel, {layout=layout})

end

