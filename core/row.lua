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

--TODO rows should be optimized for 1-100 slots cols should be opimizted for 10000+ slots

local M = require 'cel.core.module'
local _ENV = require 'cel.core.env'
setfenv(1, _ENV)

local mouse = require('cel.core.mouse')
local keyboard = require('cel.core.keyboard')

local _dcache = {}
local _links = {}
local _flux = {}
local _slotface = {}
local _slot = {}
local rowformation = {}

local math = math
local table = table

local lastindex = 0 --not storing lastindex on per row basis on purpose

local function indexof(row, link)
  local links = row[_links]
  
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
  local inval = link[_slot].x
   
  --binary search
  --TODO change to interpolating search
  while istart <= iend do
    imid = floor( (istart+iend)/2 )
    local value = links[imid][_slot].x
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
    return link[_y] + link[_h]
  else
    local minw, maxw = link[_minw], link[_maxw]
    local minh, maxh = link[_minh], link[_maxh]
    local _, y, _, h = linker(link[_w], 0, 0, link[_y], link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

    if h < minh then h = minh end
    if h > maxh then h = maxh end

    y = math.modf(y)
    h = math.floor(h)

    return math.max(y + h, h, -y)
  end
end

--reflex becuase the flex ratio of a slot changes
--which means total flex changes or a sinlge slot flex changes
--relex if the *excess* width of a row changes
local function reflex(row, force, wreflex)
  if row[_flux] > 0 and not force then return 'influx' end

  
  local links = row[_links]

  if links.reflexing then
    links.reflexed = false
    return
  end

  event:wait()

  if links.n > 0 then
    local nloops = 0
    repeat
      local hreflex = links.hreflex
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
      local roww = math.max(row[_w], links.minw)
      links.reflexing = true
      links.reflexed = true
      links.hreflex = false
      if wreflex or hreflex or links.reform then
        local rowformation = rowformation
        local dolinker = rowformation.dolinker
        local extra = 0
        local mult = 0
       
        local gap = links.gap
        local x = 0

        local link = nil
        local slot = nil

        if links.flex > 0 and roww - links.minw > 0 then
          extra = (roww - links.minw) % links.flex
          mult = math.floor((roww - links.minw)/links.flex)
        end


        for i = 1, links.n do
          link = links[i]
          slot = link[_slot]
         
          --flex
          if slot.flex > 0 then
            local w = (slot.minw or link[_minw]) + (slot.flex * mult)

            if extra > 0 then
              w = w + math.min(slot.flex, extra)
              extra = extra - slot.flex
            end

            local w, extraw = math.modf(w)
            extra = extra + extraw
            slot.w = w

            if rawget(link, _linker) then
              dolinker(rowformation, row, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
            end
          elseif hreflex then
            if rawget(link, _linker) then
              dolinker(rowformation, row, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
            end
          end

          --reform
          slot.x = x
          link[_x] = slot.x + (slot.linkx or 0)
          x = x + slot.w + gap
        end

        links.reform = false
      end
    until links.reflexed == true

    links.reflexing = false

    if not links.brace then
      --rebrace
      local minh = 0
      local edge = 0
      local breakat = links.minh
      local brace 
      for i = 1, links.n do
        link = links[i]
        slot = link[_slot]

        edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

        if edge >= minh then
          minh = edge
          brace = link
          if edge == breakat then
            break
          end
        end
      end
      links.brace = brace
      links.minh = minh
      assert(links.brace)
    end
  end
  --this is reconcile, brings row in sync with links
  --resize row
  local minw, minh = links.minw, links.minh
  local maxw

  if links.flex == 0 then maxw = minw end

  if row[_minw] ~= minw or row[_maxw] ~= maxw or row[_minh] ~= minh then
    row:setlimits(minw, maxw, minh, nil)
  end

  --seek minimum height
  if row[_h] ~= (row[_minh]) then
    row:resize(nil, row[_minh])
  end

  event:signal() --TODO move wait/signal outside of this function
end

--called anytime row is moved by any method
--rowformation.moved
function rowformation:moved(row, x, y, w, h, ox, oy, ow, oh)
  if h ~= oh and w == ow then
    event:onresize(row, ow, oh)
    local links = row[_links]
    links.h = h
    links.hreflex = true

    if row[_flux] == 0 then
      --row:beginflux(false)
      for i = 1, links.n do
        local link = links[i] 
        if rawget(link, _linker) then
          self:dolinker(row, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
        end
      end
      --row:endflux(false)
    end
    if row[_metacel].__resize then
      row[_metacel]:__resize(row, ow, oh)
    end
  elseif w ~= ow or h ~= oh then
    event:onresize(row, ow, oh)
    local links = row[_links]
    links.h = h
    links.hreflex = links.hreflex or h ~= oh
    if row[_flux] == 0 then
      reflex(row, false, links.flex > 0 and w ~= ow)
    end
    if row[_metacel].__resize then
      row[_metacel]:__resize(row, ow, oh)
    end
  end
end

do --rowformation.link
  local nooption = {}
  local isface = M.isface
  local getface = M.getface
  function rowformation:link(row, link, linker, xval, yval, option)
    option = option or nooption

    local links = row[_links]
    local index = links.n + 1
    links[index] = link
    links.n = index

    local face = option.face
    if face and not isface(face) then
      face = getface('cel', face)
    end

    local slot = {
      w = math.max(link[_w], option.minw or 0), --when flex is 0 width is not changed by flexing, only
                                                --by moving the link, furthermore the width is constrained
                                                --by the minw of the slot
      x = 0,
      linkx = 0,
      minw = option.minw, --overrides minw of link, slot will flex after this minw is allocated and will not go below this minw
      flex = option.flex or 0, --when a slot has no flex w and minw should alwyas be kept in sync and be the current width of the link
      face = face,
    }

    links.flex = links.flex + slot.flex

    --set slot.x and accumulate 
    if slot.flex == 0 then
      if links.n > 1 then
        slot.x = links.gap + links.minw
        links.minw = links.minw + links.gap + slot.w
      else
        links.minw = links.minw + slot.w
      end
    else
      if links.n > 1 then
        slot.x = links.gap + links.minw
        links.minw = links.minw + links.gap + (slot.minw or link[_minw])
      else
        links.minw = links.minw + (slot.minw or link[_minw])
      end
    end

    --TODO make slot same key as _next
    link[_slot] = slot
    link[_x] = slot.x

    local edge

    --set _y
    if not linker then
      link[_y] = yval <= 0 and 0 or math.floor(yval)

      edge = link[_y] + link[_h]
      if edge > links.minh then 
        links.brace = link 
        links.minh = edge
        links.hreflex = true
        if links.h < edge then links.h = edge end
      end
    else 
      edge = getbraceedge(link, linker, xval, yval)
      if edge > links.minh then 
        links.brace = link 
        links.minh = edge
        links.hreflex = true
        if links.h < edge then links.h = edge end
      end
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      self:dolinker(row, link, linker, xval, yval)
    end

    event:onlink(row, link, index)

    if row[_flux] == 0 then
      reflex(row, false, links.flex > 0)
    end
  end
end

function rowformation:relink(row, link, linker, xval, yval)
  local links = row[_links]
  local slot = link[_slot]
  local edge
  local doreflex

  if linker then
    edge = getbraceedge(link, linker, xval, yval)
    link[_linker] = linker
    link[_xval] = xval
    link[_yval] = yval
  else
    edge = link[_y] + link[_h]
  end

  if edge > links.minh then 
    links.brace = link 
    links.minh = edge
    links.hreflex = true
    if links.h < edge then 
      links.h = edge 
      doreflex = true
    end
  elseif links.brace == link and edge < links.minh then
    links.brace = false
    doreflex = true
  end
  
  if linker then
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw = link[_minw], link[_maxw]
    local minh, maxh = link[_minh], link[_maxh]

    local x, y, w, h = self:linker(row, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end
    if h < minh then h = minh end

    if slot.flex == 0 then
      if w ~= ow then
        links.minw = links.minw - slot.w
        slot.w = math.max(w, slot.minw or 0)
        links.minw = links.minw + slot.w
        links.reform = true
        doreflex = true
      end
    end

    if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
      link[_x] = x
      link[_w] = w
      link[_y] = y
      link[_h] = h
      celmoved(row, link, x, y, w, h, ox, oy, ow, oh)
    end
  end

  if doreflex and row[_flux] == 0 then
    reflex(row, false)
  end
end

--called anytime the link[_linker] needs to be enforced
--rowformation.dolinker
function rowformation:dolinker(row, link, linker, xval, yval)
  local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
  local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]

  local x, y, w, h = self:linker(row, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

  if w > maxw then w = maxw end
  if w < minw then w = minw end
  if h > maxh then h = maxh end
  if h < minh then h = minh end

  if x ~= ox or y ~= oy or w ~= ow or h ~= oh then
    link[_x] = x
    link[_w] = w
    link[_y] = y
    link[_h] = h
    celmoved(row, link, x, y, w, h, ox, oy, ow, oh)
  end
end

--rowformation.testlinker
function rowformation:testlinker(row, link, linker, xval, yval)
  local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
  local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]
  local slot = link[_slot]

  --TODO if this link is the brace, then account for the new height wehn linked with the linker
  local slotx = slot.linkx
  local x, y, w, h = self:linker(row, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)
  slot.linkx = slotx

  if w > maxw then w = maxw end
  if w < minw then w = minw end
  if h > maxh then h = maxh end
  if h < minh then h = minh end

  return x, y, w, h
end

do --rowformation:linker
  --called from dolinker/testlinker/movelink
  local joinlinker = joinlinker
  function rowformation:linker(row, link, linker, xval, yval, x, y, w, h, minw, maxw, minh, maxh, hw)
    local slot = link[_slot]
    local links = row[_links]
    local hw, hh = hw or slot.w, links.h

    assert(links.h >= row[_h])

    x = x - slot.x

    x, y, w, h = linker(hw, hh, x, y, w, h, xval, yval, minw, maxw, minh, maxh)

    x = math.modf(x)
    y = math.modf(y)
    w = math.floor(w)
    h = math.floor(h)

    if linker == joinlinker then hw=w end

    if slot.flex == 0 then
      if hw > slot.w and w ~= hw then hw = slot.w end 
      if w > hw then w = hw end
      if x + w > hw then x = hw - w end
      if x < 0 or (not slot.minw) or slot.minw <= w then
        x = 0
      end
    end

    if h > hh then h = hh end
    if y + h > hh then y = hh - h end
    if y < 0 then y = 0 end

    slot.linkx = x

    return slot.x + x, y, w, h
  end
end


--rowformation.linklimitschanged
function rowformation:linklimitschanged(row, link, ominw, omaxw, ominh, omaxh)
  local links = row[_links]
  local slot = link[_slot]

  local doreflex = false

  if slot.flex > 0 and not slot.minw then
    local original = links.minw
    links.minw = links.minw - (ominw or 0) 
    links.minw = links.minw + (link[_minw]) 

    if links.minw ~= original then
      links.reform = true
      doreflex = true
    end
  elseif slot.flex == 0 then
    if slot.w < link[_minw] then
      links.minw = links.minw - slot.w
      slot.w = link[_minw]
      links.minw = links.minw + slot.w
      links.reform = true
      doreflex = true
    end
  end

  if (link[_minh]) > links.minh then
    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
    if edge > links.minh then
      links.minh = edge
      links.brace = link
      links.hreflex = true
      if links.h < edge then 
        links.h = edge 
        doreflex = true
      end
    end
  elseif (link == links.brace) and ((link[_minh]) < link[_h]) then
    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
     if edge < links.minh then
      links.brace = false 
      doreflex = true
    end
  end

  if doreflex and row[_flux] == 0 then
    reflex(row)
  end
end

do --rowformation.movelink
  --movelink should only be called becuase move was explicitly called, make sure that is the case
  local math = math
  function rowformation:movelink(row, link, x, y, w, h)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw = link[_minw], link[_maxw]
    local minh, maxh = link[_minh], link[_maxh]

    if w < minw then w = minw end
    if w > maxw then w = maxw end
    if h < minh then h = minh end
    if h > maxh then h = maxh end    

    if not(x ~= ox or y ~= oy or w ~= ow or h ~= oh) then return link end

    local links = row[_links]
    local slot = link[_slot]
    local doreflex = false

    if slot.flex > 0 then
      if rawget(link, _linker) then
        x, y, w, h = self:linker(row, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                     x, y, w, h, minw, maxw, minh, maxh)
      else
        x = math.modf(x) - slot.x        
        slot.linkx = x
        x = slot.x + x      

        if y ~= oy then y = math.max(0, math.modf(y)) end
        if h ~= oh then h = math.floor(h); end
      end

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h > maxh then h = maxh end
      if h < minh then h = minh end
    else
      --when a link with no flex is moved explicitly, it will change the width of the slot
      --bounded by the maxw of the link and the minw of the slot/link
      if rawget(link, _linker) then
        x, y, w, h = self:linker(row, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                 x, y, w, h, minw, maxw, minh, maxh,  math.max(w, slot.minw or 0))
      else
        local hw = math.max(w, slot.minw or 0)
        x = math.modf(x) - slot.x        
        if x + w > hw then x = hw - w end
        if x < 0 then x = 0 end

        slot.linkx = x
        x = slot.x + x      

        if y ~= oy then y = math.max(0, math.modf(y)) end
        if h ~= oh then h = math.floor(h); end
      end

      if w > maxw then w = maxw end
      if w < minw then w = minw end
      if h < minh then h = minh end
      if h > maxh then h = maxh end   

      if w ~= ow then
        links.minw = links.minw - slot.w
        slot.w = math.max(w, slot.minw or 0)
        links.minw = links.minw + slot.w
        links.reform = true
        doreflex = true
      end
    end

    
    link[_x] = x
    link[_w] = w
    link[_y] = y
    link[_h] = h

    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

    if edge > links.minh then
      links.minh = edge
      links.brace = link
      links.hreflex = true
      if links.h < edge then 
        links.h = edge 
        doreflex = true
      end
    elseif links.brace == link and edge < links.minh then
      links.brace = false
      doreflex = true
    end

    event:wait()

    if x~= ox or y ~= oy or w ~= ow or h ~= oh then
      celmoved(row, link, x, y, w, h, ox, oy, ow, oh)
    end

    if doreflex and row[_flux] == 0 then
      reflex(row)
    end

    event:signal()

    return link
  end
end

--TODO make this work when clearing, in which case row[_links] is empty
--TODO always make sure reform is done before search
do --rowformation.unlink
  local math = math
  function rowformation:unlink(row, link)
    local links = row[_links]
    local index = indexof(row, link)
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
      links.minw = 0
    elseif slot.flex == 0 then
      links.minw = links.minw - slot.w - links.gap
    else
      links.minw = links.minw - (slot.minw or link[_minw]) - links.gap
    end

    if row[_metacel].__unlink then
      row[_metacel]:__unlink(row, link, index)
    end

    if row[_flux] == 0 then
      reflex(row)
    end
  end
end

do --rowformation.pick
  function rowformation:pick(row, xin, yin)
    local links = row[_links]
    local floor = math.floor
    local istart, iend, imid = 1, links.n, 0
    local gap = links.gap

    while istart <= iend do
      imid = floor( (istart+iend)/2 )
      local value = links[imid][_slot].x
      local range = links[imid][_slot].w + gap 
      if xin >= value and xin < value + range then
        return links[imid], imid
      elseif xin < value then
        iend = imid - 1
      else
        if not (xin >= value + range) then
          assert(xin >= value + range)
        end
        istart = imid + 1
      end
    end
  end
end

do --rowformation.describeslot
  local cache = setmetatable({}, {__mode='kv'})

  local function initdcache(row, a, b)
    local dcache = row[_dcache]
    if not dcache then
      dcache = setmetatable({}, {__mode='kv'})
      row[_dcache] = dcache 
    end
    dcache.offset = a-1
  end

  local function getdescription(row, index)
    local dcache = row[_dcache]
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

  function rowformation:describeslot(row, host, gx, gy, gl, gt, gr, gb, index, link, hasmouse, fullrefresh)
    local slot = link[_slot]

    gx = gx + slot.x

    if gx > gl then gl = gx end
    if gx + slot.w < gr then gr = gx + slot.w end

    if gr <= gl or gb <= gt then return end

    local face = slot.face or row[_slotface]

    local t = getdescription(row, index)

    t.id = 0 --virtual, find a way to assign an id
    t.metacel = '['.. index ..']'
    t.face = face
    t.host = host
    t.x = slot.x 
    t.y = 0 
    t.w = slot.w
    t.h = row[_h]
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

    if row[_metacel].__describeslot then
      row[_metacel]:__describeslot(row, link, index, t)
    end

    do
      local x = link[_x] 
      link[_x] = slot.linkx or 0 --TODO bad hack, do this another way 
      t[1] = describe(link, t, gx, gy, gl, gt, gr, gb, fullrefresh)
      link[_x] = x
    end

    return t
  end

  --rowformation.describelinks
  function rowformation:describelinks(row, host, gx, gy, gl, gt, gr, gb, fullrefresh)
    local links = row[_links]
    local nlinks = links.n

    if nlinks > 0 then
      local _, a = self:pick(row, gl - gx, gt - gy)
      local _, b = self:pick(row, gr - gx, gb - gy)

      if a and a > 1 then a = a - 1 end
      if b and b < nlinks then b = b + 1 end

      a = a or 1
      b = b or nlinks

      local vcel
      if mouse[_focus][row] then
        local x, y = row.X, row.Y
        vcel = self:pick(row, mouse[_x] - x, mouse[_y] - y) --TODO allow pick to accept a search range
      end

      local i = 1
      local n = #host
      initdcache(row, a, b)
      for index = a, b do
        host[i] = self:describeslot(row, host, gx, gy, gl, gt, gr, gb, index, links[index], vcel == links[index], fullrefresh)
        i = host[i] and i + 1 or i
      end
      for i = i, n do
        host[i]=nil
      end
    end
  end
end


--define row metacel
local metacel, metatable = metacel:newmetacel('row')

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
function metatable.clear(row) 
  event:wait()
  local links = row[_links] 
  row:flux(function()
    repeat
      links[links.n]:unlink()
    until links.n == 0 
  end)
  event:signal()
end

do --metatable.ilinks
  local function it(row, i)
    i = i + 1
    local link = row[_links][i]
    if link then
      return i, link
    end
  end

  function metatable.ilinks(row)
    return it, row, 0
  end
end

function metatable.len(row)
  return row[_links].n
end

function metatable.get(row, index)
  return row[_links][index]
end

--TODO pcall, with errorhandler function, driver must provide an error handler
function metatable.flux(row, callback, ...)
  row[_flux] = row[_flux] + 1
  reflex(row, true)
  if callback then
    callback(...)
    reflex(row, true)
  end
  row[_flux] = row[_flux] - 1
  return row
end

--TODO remove this, or put it in metacel too easy to mess up
function metatable.beginflux(row, doreflex)
  row[_flux] = row[_flux] + 1
  if doreflex then 
    reflex(row, true) 
  end
  return row
end

--TODO remove this, or put it in metacel too easy to mess up
function metatable.endflux(row, force)
  row[_flux] = row[_flux] - 1
  if force == nil then force = true end
  reflex(row, force)
  return row
end

--TODO define so that nil input returns the first link
function metatable.next(row, item)
  if item[_host] ~= row then return nil end

  local index = indexof(row, item)

  if index then
    return row[_links][1 + index]
  end
end

--TODO define so that nil input returns the last link
function metatable.prev(row, item)
  if item[_host] ~= row then return nil end

  local index = indexof(row, item)

  if index then
    return row[_links][-1 + index]
  end
end

function metatable.insert(row, index, item, linker, xval, yval, option)
  index = index or -1

  row:beginflux()

  if rawget(item, _host) == row then
    item:relink(linker, xval, yval, option)
    local links = row[_links]
    local n = links.n

    if index < -1 then
      index = math.max(1, n + index+1)
    elseif index > n or index <= 0 then
      index = n
    end

    local currentindex = indexof(row, item) 
    if index ~= currentindex then
      links.reform = true
      table.remove(links, currentindex)
      table.insert(links, index, item)
      row:refresh() --TODO may not have to refresh here, when refresh logic is working correctly
    end
  else
    item:link(row, linker, xval, yval, option)
    local links = row[_links]
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

  row:endflux()
  return row
end

--TODO if row is stable, should not have to do indexof in unlink
function metatable.remove(row, index)
  local item = row[_links][index]

  if item then
    item:unlink()
  end
  return row
end

--TODO make work
function metatable.indexof(row, item)
  if item[_host] == row then 
    local i = indexof(row, item)

    if row[_links][i] == item then
      return i
    else
      reflex(row, true)
      return indexof(row, item)
    end
  end
end

--returns item, index
function metatable.pick(row, x, y)
  return rowformation:pick(row, x, y)
end

function metatable.sort(row, comp)
  row:beginflux()
  local links = row[_links]
  table.sort(links, comp)
  links.reform = true
  row:endflux()
  row:refresh()
  return row 
end

--TODO does not quite work
function metacel:onmousemove(row, x, y)
  local vx, vy = mouse:vector()
  local a = row:pick(x, y)
  local b = row:pick(x - vx, y - vy)
  if a ~= b then
    row:refresh()
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
    local row = _new(self, 0, 0, face)
    row[_flux] = 0
    row[_links] = {
      brace = false,
      reflex = false,
      hreflex = false,
      minw = 0,
      maxw = 0,
      minh = 0,
      flex = 0,
      h = 0,
      gap = gap or 0,
      n = 0,
    }

    row[_maxw] = 0

    if layout.slotface then
      if M.isface(layout.slotface) then
        row[_slotface] = layout.slotface
      else
        row[_slotface] = M.getface('cel', layout.slotface) or slotface
      end
    else
      row[_slotface] = slotface
    end

    row[_formation] = rowformation
    return row
  end

  local _compile = metacel.compile
  function metacel:compile(t, row)
    row = row or metacel:new(t.gap, t.face)
    row[_flux] = 1
    row.onchange = t.onchange
    _compile(self, t, row)
    row[_flux] = 0 
    reflex(row, true)
    return row
  end

  function metacel:compileentry(row, entry, entrytype, linker, xval, yval, option)
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
        local link = M.tocel(entry[i], row)
        if link then
          link:link(row, linker, xval, yval, option or entry)
        end
      end 
    end
  end
end

return metacel:newfactory({layout=layout})

