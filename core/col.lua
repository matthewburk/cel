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

--TODO should be optimized for 10000+ slots

local M = require 'cel.core.module'
local _ENV = require 'cel.core.env'
setfenv(1, _ENV)

local mouse = require('cel.core.mouse')
local keyboard = require('cel.core.keyboard')

local _dcache = {}
local _links = {}
local _flux = {}
local _slotface = {}
local _slot = _next
local colformation = {__nojoin=true}

local math = math
local table = table

local lastindex = 0 --not storing lastindex on per col basis on purpose

local function indexof(col, link)
  local links = col[_links]
  
  if link == links[1] then
    return 1
  elseif link == links[links.n] then
    return links.n
  elseif link == links[lastindex] then
    return lastindex
  elseif link == links[lastindex+1] then
    lastindex = lastindex+1
    return lastindex
  elseif link == links[lastindex-1] then
    lastindex = lastindex-1
    return lastindex
  end

  local _slot = _slot
  local floor = math.floor
  local istart, iend, imid = 1, links.n, 0
  local inval = link[_slot].y
   
  --binary search
  --TODO change to interpolating search
  while istart <= iend do
    imid = floor( (istart+iend)/2 )
    local value = links[imid][_slot].y
    if inval == value then
      lastindex = imid
      return imid
    elseif inval < value then
      iend = imid - 1
    else
      istart = imid + 1
    end
  end
end

local function getbraceedge(link, linker, xval, yval)
  if not linker then
    return link[_x] + link[_w]
  else
    local minw, maxw = link[_minw], link[_maxw]
    local minh, maxh = link[_minh], link[_maxh]
    local x, _, w, _ = linker(0, link[_h], link[_x], 0, link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

    if w < minw then w = minw end
    if w > maxw then w = maxw end

    x = math.modf(x)
    w = math.floor(w)

    return math.max(x + w, w, -x)
  end
end

--reflex becuase the flex ratio of a slot changes
--which means total flex changes or a sinlge slot flex changes
--relex if the *excess* height of a col changes
local function reflex(col, force, hreflex)
  if col[_flux] > 0 and not force then 
    return 'influx' 
  end

  local links = col[_links]

  if links.reflexing then
    links.reflexed = false
    return
  end

  
  event:wait()

  if links.n > 0 then
    local nloops = 0
    repeat
      local wreflex = links.wreflex
      nloops = nloops + 1
      if nloops > 2 then
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('XOMFASDF#@$!@FDSAFSAFAFSAFSDFAAF')
        print('ZOMG nloops is', nloops)
      end
      local colh = math.max(col[_h], links.minh)

      links.reflexing = true
      links.reflexed = true
      links.wreflex = false
      if wreflex or hreflex or links.reform then
        local colformation = colformation
        local dolinker = colformation.dolinker
        local extra = 0
        local mult = 0
       
        local gap = links.gap
        local y = 0

        local link = nil
        local slot = nil

        if links.flex > 0 and colh - links.minh > 0 then
          extra = (colh - links.minh) % links.flex
          mult = math.floor((colh - links.minh)/links.flex)
        end

        for i = 1, links.n do
          link = links[i]
          slot = link[_slot]
         
          --flex
          if slot.flex > 0 then
            local h = (slot.minh or link[_minh]) + (slot.flex * mult)

            if extra > 0 then
              h = h + math.min(slot.flex, extra)
              extra = extra - slot.flex
            end

            local h, extrah = math.modf(h)
            extra = extra + extrah
            slot.h = h

            if rawget(link, _linker) then
              dolinker(colformation, col, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
            end
          elseif wreflex then
            if rawget(link, _linker) then
              dolinker(colformation, col, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
            end
          end

          --reform
          slot.y = y
          link[_y] = slot.y + (slot.linky or 0)
          y = y + slot.h + gap

          --joins
          if joins[link] then
            for joinedcel in pairs(joins[link]) do
              if rawget(joinedcel, _linker) == joinlinker then
                joinanchormoved(joinedcel, link) 
                --only if joinedcel is joined to the target, 
                --relinking will unjoin but allow the join to reestablish if relinked with 
                --linker, xval and yval that were assigned when it was joined
              end
            end
          end
        end

        links.reform = false
      end
    until links.reflexed == true

    links.reflexing = false

    if not links.brace then
      --rebrace
      local minw = 0
      local edge = 0
      local breakat = links.minw
      local brace 
      for i = 1, links.n do
        link = links[i]
        slot = link[_slot]

        edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

        if edge >= minw then
          minw = edge
          brace = link
          if edge == breakat then
            break
          end
        end
      end
      links.brace = brace
      links.minw = minw
      assert(links.brace)
    end
  end
  local minw, minh = links.minw, links.minh
  local maxh

  if links.flex == 0 then maxh = minh end

  if col[_minh] ~= minh or col[_maxh] ~= maxh or col[_minw] ~= minw then
    col:setlimits(minw, nil, minh, maxh)
  end

  --seek minimum width
  if col[_w] ~= (col[_minw]) then
    col:resize(col[_minw])
  end

  event:signal() --TODO move wait/signal outside of this function
end

--called anytime col is moved by any method
--colformation.moved
function colformation:moved(col, x, y, w, h, ox, oy, ow, oh)
  if w ~= ow and h == oh then
    event:onresize(col, ow, oh)
    local links = col[_links]
    links.w = w
    links.wreflex = true

    if col[_flux] == 0 then
      --col:beginflux(false)
      for i = 1, links.n do
        local link = links[i] 
        if rawget(link, _linker) then
          self:dolinker(col, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
        end
      end
      --col:endflux(false)
    end
    if col[_metacel].__resize then
      col[_metacel]:__resize(col, ow, oh)
    end
  elseif w ~= ow or h ~= oh then
    event:onresize(col, ow, oh)
    local links = col[_links]
    links.w = w
    links.wreflex = links.wreflex or w ~= ow
    if col[_flux] == 0 then
      reflex(col, false, links.flex > 0 and h ~= oh)
    end
    if col[_metacel].__resize then
      col[_metacel]:__resize(col, ow, oh)
    end
  end

  --joins
  if true then --TODO only do this if a link has joins at all
    local links = col[_links]
    for i = 1, links.n do
      local link = links[i]
      if joins[link] then
        for joinedcel in pairs(joins[link]) do
          if rawget(joinedcel, _linker) == joinlinker then
            joinanchormoved(joinedcel, link) 
            --only if joinedcel is joined to the target, 
            --relinking will unjoin but allow the join to reestablish if relinked with 
            --linker, xval and yval that were assigned when it was joined
          end
        end
      end
    end
  end
end

do --colformation.link
  local nooption = {}
  local isface = M.isface
  local getface = M.getface
  function colformation:link(col, link, linker, xval, yval, option)
    option = option or nooption

    local links = col[_links]
    local index = links.n + 1 
    links[index] = link
    links.n = index

    local face = option.face
    if face and not isface(face) then
      face = getface('cel', face)
    end

    local slot = {
      h = math.max(link[_h], option.minh or 0), 
      y = 0,
      linky = 0,
      minh = option.minh, 
      flex = option.flex or 0, 
      face = face,
    }
    --TODO move slot entries to the link

    links.flex = links.flex + slot.flex

    --set slot.y and accumulate 
    if slot.flex == 0 then
      if links.n > 1 then
        slot.y = links.gap + links.minh
        links.minh = links.minh + links.gap + slot.h
      else
        links.minh = links.minh + slot.h
      end
    else
      if links.n > 1 then
        slot.y = links.gap + links.minh
        links.minh = links.minh + links.gap + (slot.minh or link[_minh])
      else
        links.minh = links.minh + (slot.minh or link[_minh])
      end
    end


    --TODO make slot same key as _next
    link[_slot] = slot
    link[_y] = slot.y

    local edge

    --set _x
    if not linker then
      link[_x] = xval <= 0 and 0 or math.floor(xval)

      edge = link[_x] + link[_w]
      if edge > links.minw then 
        links.brace = link 
        links.minw = edge
        links.wreflex = true
        if links.w < edge then links.w = edge end
      end
    else 
      edge = getbraceedge(link, linker, xval, yval)
      if edge > links.minw then 
        links.brace = link 
        links.minw = edge
        links.wreflex = true
        if links.w < edge then links.w = edge end
      end
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      self:dolinker(col, link, linker, xval, yval)
    end

    event:onlink(col, link, index)

    if col[_flux] == 0 then
      reflex(col, false, links.flex > 0)
    end
  end
end

function colformation:relink(col, link, linker, xval, yval)
  local links = col[_links]
  local slot = link[_slot]
  local edge
  local doreflex

  if linker then
    edge = getbraceedge(link, linker, xval, yval)
    link[_linker] = linker
    link[_xval] = xval
    link[_yval] = yval
  else
    edge = link[_x] + link[_w]
  end

  if edge > links.minw then 
    links.brace = link 
    links.minw = edge
    links.wreflex = true
    if links.w < edge then 
      links.w = edge 
      doreflex = true
    end
  elseif links.brace == link and edge < links.minw then
    links.brace = false
    doreflex = true
  end
  
  if linker then
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw = link[_minw], link[_maxw]
    local minh, maxh = link[_minh], link[_maxh]

    local x, y, w, h = self:linker(col, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end
    if h < minh then h = minh end

    if slot.flex == 0 then
      if h ~= oh then
        links.minh = links.minh - slot.h
        slot.h = math.max(h, slot.minh or 0)
        links.minh = links.minh + slot.h
        links.reform = true
        doreflex = true
      end
    end

    if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
      link[_x] = x
      link[_w] = w
      link[_y] = y
      link[_h] = h
      celmoved(col, link, x, y, w, h, ox, oy, ow, oh)
    end
  end

  if doreflex and col[_flux] == 0 then
    reflex(col, false)
  end
end

--called anytime the link[_linker] needs to be enforced
--colformation.dolinker
function colformation:dolinker(col, link, linker, xval, yval)
  local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
  local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]

  local x, y, w, h = self:linker(col, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

  if w > maxw then w = maxw end
  if w < minw then w = minw end
  if h > maxh then h = maxh end
  if h < minh then h = minh end

  if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
    link[_x] = x
    link[_w] = w
    link[_y] = y
    link[_h] = h
    celmoved(col, link, x, y, w, h, ox, oy, ow, oh)
  end
end

--colformation.testlinker
function colformation:testlinker(col, link, linker, xval, yval)
  local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
  local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]
  local slot = link[_slot]

  --TODO if this link is the brace, then account for the new width wehn linked with the linker
  local sloty = slot.linky
  local x, y, w, h = self:linker(col, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)
  slot.linky = sloty

  if w > maxw then w = maxw end
  if w < minw then w = minw end
  if h > maxh then h = maxh end
  if h < minh then h = minh end

  return x, y, w, h
end

do --colformation:linker
  --called from dolinker/testlinker/movelink
  function colformation:linker(col, link, linker, xval, yval, x, y, w, h, minw, maxw, minh, maxh, hh)
    local slot = link[_slot]
    local links = col[_links]
    local hw, hh = links.w, (hh or slot.h)

    assert(links.w >= col[_w])

    y = y - slot.y

    x, y, w, h = linker(hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)

    x = math.modf(x)
    y = math.modf(y)
    w = math.floor(w)
    h = math.floor(h)

    if w > hw then w = hw end
    if x + w > hw then x = hw - w end
    if x < 0 then x = 0 end

    if slot.flex == 0 then
      --if hh > slot.h and h ~= hh then hh = slot.h end 
      if h > hh then h = hh end
      if y + h > hh then y = hh - h end
      if y < 0 or (not slot.minh) or slot.minh <= h then
        y = 0
      end
    end

    slot.linky = y

    return x, slot.y + y, w, h
  end
end



--colformation.linklimitschanged
function colformation:linklimitschanged(col, link, ominw, omaxw, ominh, omaxh)
  local links = col[_links]
  local slot = link[_slot]

  local doreflex = false

  if slot.flex > 0 and not slot.minh then
    local original = links.minh
    links.minh = links.minh - (ominh or 0) 
    links.minh = links.minh + (link[_minh]) 

    if links.minh ~= original then
      links.reform = true
      doreflex = true
    end
  elseif slot.flex == 0 then
    if slot.h < link[_minh] then
      links.minh = links.minh - slot.h
      slot.h = link[_minh]
      links.minh = links.minh + slot.h
      links.reform = true
      doreflex = true
    end
  end

  if (link[_minw]) > links.minw then
    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
    if edge > links.minw then
      links.minw = edge
      links.brace = link
      links.wreflex = true
      if links.w < edge then 
        links.w = edge 
        doreflex = true
      end
    end
  elseif (link == links.brace) and ((link[_minw]) < link[_w]) then
    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
     if edge < links.minw then
      links.brace = false 
      doreflex = true
    end
  end

  if doreflex and col[_flux] == 0 then
    reflex(col)
  end
end

do --colformation.movelink
  --movelink should only be called becuase move was explicitly called, make sure that is the case
  local math = math
  function colformation:movelink(col, link, x, y, w, h)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw = link[_minw], link[_maxw]
    local minh, maxh = link[_minh], link[_maxh]

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end    

    if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return link end

    local links = col[_links]
    local slot = link[_slot]
    local doreflex = false

    if slot.flex > 0 then
      if rawget(link, _linker) then
        x, y, w, h = self:linker(col, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                     x, y, w, h, minw, maxw, minh, maxh)
      else
        y = math.modf(y) - slot.y        
        slot.linky = y
        y = slot.y + y      

        if x ~= ox then x = math.max(0, math.modf(x)) end
        if w ~= ow then w = math.floor(w) end
      end

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end
      if h < minh then h = minh end
    else
      --when a link with no flex is moved explicitly, it will change the height of the slot
      --bounded by the maxh of the link and the minh of the slot/link
      if rawget(link, _linker) then
        x, y, w, h = self:linker(col, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                 x, y, w, h, minw, maxw, minh, maxh,  math.max(h, slot.minh or 0))
      else
        local hh = math.max(h, slot.minh or 0)
        y = math.modf(y) - slot.y        
        if y + h > hh then y = hh - h end
        if y < 0 then y = 0 end

        slot.linky = y
        y = slot.y + y      

        if x ~= ox then x = math.max(0, math.modf(x)) end
        if w ~= ow then w = math.floor(w) end
      end

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h < minh then h = minh end
      if h > maxh then h = maxh end   

      if h ~= oh then
        links.minh = links.minh - slot.h
        slot.h = math.max(h, slot.minh or 0)
        links.minh = links.minh + slot.h
        links.reform = true
        doreflex = true
      end
    end

    
    link[_x] = x
    link[_w] = w
    link[_y] = y
    link[_h] = h

    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

    if edge > links.minw then
      links.minw = edge
      links.brace = link
      links.wreflex = true
      if links.w < edge then 
        links.w = edge 
        doreflex = true
      end
    elseif links.brace == link and edge < links.minw then
      links.brace = false
      doreflex = true
    end

    event:wait()

    if x~= ox or y ~= oy or w ~= ow or h ~= oh then
      celmoved(col, link, x, y, w, h, ox, oy, ow, oh)
    end

    if doreflex and col[_flux] == 0 then
      reflex(col)
    end

    event:signal()

    return link
  end
end

--TODO make this work when clearing, in which case col[_links] is empty
--TODO always make sure reform is done before search
do --colformation.unlink
  local math = math
  function colformation:unlink(col, link)
    local links = col[_links]
    local index = indexof(col, link)
    assert(index)
    table.remove(links, index)

    links.reform = true
    links.n = links.n - 1

    if link == links.brace then
      links.brace = false
    end

    local slot = link[_slot]
    link[_slot] = nil

    if links.n == 0 then
      links.minh = 0
    elseif slot.flex == 0 then
      links.minh = links.minh - slot.h - links.gap
    else
      links.minh = links.minh - (slot.minh or link[_minh]) - links.gap
    end

    if col[_metacel].__unlink then
      col[_metacel]:__unlink(col, link, index)
    end

    if col[_flux] == 0 then
      reflex(col)
    end
  end
end

do --colformation.pick
  function colformation:pick(col, _, yin)
    local links = col[_links]
    local floor = math.floor
    local istart, iend, imid = 1, links.n, 0
    local gap = links.gap

    while istart <= iend do
      imid = floor( (istart+iend)/2 )
      local value = links[imid][_slot].y
      local range = links[imid][_slot].h + gap 
      if yin >= value and yin < value + range then
        return links[imid], imid
      elseif yin < value then
        iend = imid - 1
      else
        if not (yin >= value + range) then
          assert(yin >= value + range)
        end
        istart = imid + 1
      end
    end
  end
end

do --colformation.describeslot
  local cache = setmetatable({}, {__mode='kv'})

  local function initdcache(col, a, b)
    local dcache = col[_dcache]
    if not dcache then
      dcache = setmetatable({}, {__mode='kv'})
      col[_dcache] = dcache 
    end
    dcache.offset = a-1
  end

  local function getdescription(col, index)
    local dcache = col[_dcache]
    local t = dcache[index-dcache.offset]
   
    t = t or {
      host = false,
      id = 0,
      metacel = false,
      face = false,
      x = 0,
      y = 0,
      w = 0,
      h = 0,
      mousefocus = false,
      mousefocusin = false,
      focus = false,
      flowcontext = false,
      index = 0,
      refresh = false,
      clip = {l=0,t=0,r=0,b=0},
      disabled = false,
    }

    dcache[index-dcache.offset]=t
    return t
  end

  function colformation:describeslot(col, host, gx, gy, gl, gt, gr, gb, index, link, hasmouse, fullrefresh)
    local slot = link[_slot]

    gy = gy + slot.y

    if gy > gt then gt = gy end
    if gy + slot.h < gb then gb = gy + slot.h end

    if gr <= gl or gb <= gt then return end

    local face = slot.face or col[_slotface]

    local t = getdescription(col, index)

    t.id = 0 --virtual, find a way to assign an id
    t.metacel = '['.. index ..']'
    t.face = face
    t.host = host
    t.x = 0
    t.y = slot.y
    t.w = col[_w]
    t.h = slot.h
    t.mousefocus = false
    t.mousefocusin = hasmouse --TODO only set if link doesn't have mouse
    t.index = index
    --TODO focus
    t.refresh = fullrefresh or link[_refresh]
    t.clip.l = gl
    t.clip.t = gt
    t.clip.r = gr
    t.clip.b = gb
    t.disabled = link[_disabled] or (host.disabled and 'host')

    if col[_metacel].__describeslot then
      col[_metacel]:__describeslot(col, link, index, t)
    end

    do
      local y = link[_y] 
      link[_y] = slot.linky or 0 --TODO bad hack, do this another way 
      t[1] = describe(link, t, gx, gy, gl, gt, gr, gb, fullrefresh)
      link[_y] = y
    end

    return t
  end

  --colformation.describelinks
  function colformation:describelinks(col, host, gx, gy, gl, gt, gr, gb, fullrefresh)
    local links = col[_links]
    local nlinks = links.n

    if nlinks > 0 then
      local _, a = self:pick(col, gl - gx, gt - gy)
      local _, b = self:pick(col, gr - gx, gb - gy)

      if a and a > 1 then a = a - 1 end
      if b and b < nlinks then b = b + 1 end

      a = a or 1
      b = b or nlinks

      local vcel
      if mouse[_focus][col] then
        local x, y = col.X, col.Y
        vcel = self:pick(col, mouse[_x] - x, mouse[_y] - y) --TODO allow pick to accept a search range
      end

      local i = 1
      local n = #host
      initdcache(col, a, b)
      for index = a, b do
        host[i] = self:describeslot(col, host, gx, gy, gl, gt, gr, gb, index, links[index], vcel == links[index], fullrefresh)
        i = host[i] and i + 1 or i
      end
      for i = i, n do
        host[i]=nil
      end
    end
  end
end


--define col metacel
local metacel, metatable = metacel:newmetacel('col')


function metacel:touch(cel, x, y)
  local formation = rawget(cel, _formation)

  if formation and formation.pick then
    local link = formation:pick(cel, x, y)
    if touch(link, x - link[_x], y - link[_y]) then
      return true
    end
    return false
  end

  for link in  links(cel) do
    if touch(link, x - link[_x], y - link[_y]) then
      return true
    end
  end
  return false
end

--TODO its probably faster to drop the old _links, but formation:unlink calls out to metacel
--with the index that was unlinked
function metatable.clear(col) 
  event:wait()
  local links = col[_links] 
  col:flux(function()
    repeat
      links[links.n]:unlink()
    until links.n == 0 
  end)
  event:signal()
end

do --metatable.ilinks
  local function it(col, i)
    i = i + 1
    local link = col[_links][i]
    if link then
      return i, link
    end
  end

  function metatable.ilinks(col)
    return it, col, 0
  end
end

function metatable.len(col)
  return col[_links].n
end

function metatable.get(col, index)
  return col[_links][index]
end

--TODO pcall, with errorhandler function, driver must provide an error handler
function metatable.flux(col, callback, ...)
  col[_flux] = col[_flux] + 1
  reflex(col, true)
  if callback then
    callback(...)
    reflex(col, true)
  end
  col[_flux] = col[_flux] - 1
  return col
end

--TODO remove this, or put it in metacel too easy to mess up
function metatable.beginflux(col, doreflex)
  col[_flux] = col[_flux] + 1
  if doreflex then 
    reflex(col, true) 
  end
  return col
end

--TODO remove this, or put it in metacel too easy to mess up
function metatable.endflux(col, force)
  col[_flux] = col[_flux] - 1
  if force == nil then force = true end
  reflex(col, force)
  return col
end

--TODO define so that nil input returns the first link
function metatable.next(col, item)
  if item[_host] ~= col then return nil end

  local index = indexof(col, item)

  if index then
    return col[_links][1 + index]
  end
end

--TODO define so that nil input returns the last link
function metatable.prev(col, item)
  if item[_host] ~= col then return nil end

  local index = indexof(col, item)

  if index then
    return col[_links][-1 + index]
  end
end

function metatable.insert(col, index, item, linker, xval, yval, option)
  index = index or -1

  col:beginflux()

  if rawget(item, _host) == col then
    item:relink(linker, xval, yval, option)
    local links = col[_links]
    local n = links.n

    if index < -1 then
      index = math.max(1, n + index+1)
    elseif index > n or index <= 0 then
      index = n
    end

    local currentindex = indexof(col, item) 
    if index ~= currentindex then
      links.reform = true
      table.remove(links, currentindex)
      table.insert(links, index, item)
      col:refresh() --TODO may not have to refresh here, when refresh logic is working correctly
    end
  else
    item:link(col, linker, xval, yval, option)
    local links = col[_links]
    local n = links.n

    if index < -1 then
      index = math.max(1, n + index+1)
    elseif index > n or index <= 0 then
      index = n
    end

    if index ~= n then
      links.reform = true
      links[n] = nil
      table.insert(links, index, item)
    end
  end

  col:endflux()
  return col
end

--TODO if col is stable, should not have to do indexof in unlink
function metatable.remove(col, index)
  local item = col[_links][index]

  if item then
    item:unlink()
  end
  return col
end

--TODO make work
function metatable.indexof(col, item)
  if item[_host] == col then 
    local i = indexof(col, item)

    if col[_links][i] == item then
      return i
    else
      reflex(col, true)
      return indexof(col, item)
    end
  end
end

--returns item, index
function metatable.pick(col, x, y)
  return colformation:pick(col, x, y)
end

function metatable.sort(col, comp)
  col:beginflux()
  local links = col[_links]
  table.sort(links, comp)
  links.reform = true
  col:endflux()
  col:refresh() --TODO why is this here??
  return col
end

--TODO does not quite work
function metacel:onmousemove(col, x, y)
  local vx, vy = mouse:vector()
  local a = col:pick(x, y)
  local b = col:pick(x - vx, y - vy)
  if a ~= b then
    col:refresh()
  end
end

local layout = {
  slotface = nil
}

do --metacel.new, metacel.compile
  local _new = metacel.new
  local slotface = M.getface('cel')
  function metacel:new(gap, face)
    face = self:getface(face)
    local layout = face.layout or layout
    local col = _new(self, 0, 0, face)
    col[_flux] = 0
    col[_links] = {
      brace = false,
      reflex = false,
      wrefelx = false,
      minh = 0,
      maxh = 0,
      minw = 0,
      flex = 0,
      w = 0,
      gap = gap or 0,
      n = 0,
    }

    col[_maxh] = 0    

    if layout.slotface then
      if M.isface(layout.slotface) then
        col[_slotface] = layout.slotface
      else
        col[_slotface] = M.getface('cel', layout.slotface) or slotface
      end
    else
      col[_slotface] = slotface
    end
    col[_formation] = colformation
    return col
  end

  local _compile = metacel.compile
  function metacel:compile(t, col)
    col = col or metacel:new(t.gap, t.face)
    col[_flux] = 1
    col.onchange = t.onchange
    _compile(self, t, col)
    col[_flux] = 0 
    reflex(col, false)
    return col
  end

  function metacel:compileentry(col, entry, entrytype, linker, xval, yval, option)
    if 'table' == entrytype then
      --TODO interpret link how _cel does, need function like { linker, xval, yval, option = cel.decodelink(entry.link) }
      if entry.link then
        if type(entry.link) == 'table' then
          linker, xval, yval, option = unpack(entry.link, 1, 4)
        else
          linker, xval, yval, option = entry.link, nil, nil, nil
        end
      end

      for i = 1, #entry do
        local link = M.tocel(entry[i], col)
        if link then
          link:link(col, linker, xval, yval, option or entry)
        end
      end 
    end
  end
end

return metacel:newfactory({layout=layout})
