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

local function dprint() end

local lastindex = 0 --not storing lastindex on per col basis on purpose

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

--col w, h and limits shall not mutate as a side effect of this funtion
--assigns links.brace and links.minw
local function rebrace(col)
  dprint('col', col.id, 'rebrace')
  local links = col[_links]

  if not links.brace then
    local oldbraceedge = links.minw
    local minw = 0
    local edge, brace, link, slot

    for i = 1, links.n do
      link = links[i]
      slot = link[_slot]

      edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

      if edge >= minw then
        minw = edge
        brace = link
        if edge == oldbraceedge then
          break
        end
      end
    end

    assert(brace)

    if col.__debug then
      dprint('rebrace minw', minw)
      dprint('rebrace brace', brace.minw, brace.w, brace.r)
    end

    links.brace = brace
    links.minw = minw
  end
end

--col w, h and limits shall not mutate as a side effect of this funtion
local function reflexandalign(col)
  dprint('col', col.id, 'reflexandalign')
  local links = col[_links]
  local unmaxedflex = links.flex
  local extra = col[_h] - links.minh

  assert(extra>=0)
  if unmaxedflex > 0 then 
    local mult = extra/unmaxedflex
    unmaxedflex = 0

    local link
    local slot
    for i = 1, links.n do
      link = links[i]
      slot = link[_slot]

      if slot.flex > 0 then
        --flex
        local maxfromflex = slot.maxh - slot.minh
        local take = math.min(maxfromflex, math.floor(slot.flex * mult))
        --note that height is reduced if link[_minh] > slot.maxh 
        local h = slot.minh + take
   
        extra = extra - take

        if h < slot.maxh then
          unmaxedflex = unmaxedflex + slot.flex
        end

        slot.h = h
        if col.__debug then
          dprint('col.reflexandalign', col.id, 'slot.h', slot.h)
        end
      end
    end
  end

  --dolinkers to respond to new slot.h

  if true then -- do --reform TODO only reform when it is necessary, avoid on initial build of col
    local y = 0
    local gap = links.gap
    local colmaxh = 0

    local link
    local slot
    for i = 1, links.n do
      link = links[i]
      slot = link[_slot]

      if extra > 0 and unmaxedflex > 0 and slot.flex > 0 then
        local take = math.min(math.ceil(slot.flex/unmaxedflex*extra), slot.maxh - slot.h)
        slot.h = slot.h + take
        extra = extra - take
      end

      colmaxh = math.min(colmaxh + slot.maxh, maxdim)
      --TODO limit maxh of col if necessary 

      if rawget(link, _linker) then
        colformation:dolinker(col, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
      end

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
  end
end

local function setwidthandheight(col)
  local links = col[_links]

  if links.n == 0 then return end --TODO set w and h and limits before returning

   --collapse col to its min size
  local newcolw = links.minw
  local newcolh = links.minh

  dprint('reconcile links.minw', links.minw)
  dprint('reconcile newcolw', newcolw)


  --if a linker prevents collapse to min size
  if (newcolw ~= col[_w] or newcolh ~= col[_h]) and rawget(col, _linker) then
    local x, y, w, h = testlinker(col, col[_host], rawget(col, _linker), rawget(col, _xval), rawget(col, _yval), nil, nil, newcolw, newcolh, newcolw, nil, newcolh, links.maxh)
    --the linker may only increase the col w and h from its minimum values
    newcolw = math.max(newcolw, w)
    newcolh = math.max(newcolh, math.min(h, links.maxh))
    --TODO links.maxh must be set when a slot is created, it can increase to maxdim
    --unlinking or changing the maxh of a slot will force a new links.maxh to be calculated
    dprint('reconcile newcolw', newcolw, w)
  end


  if newcolw ~= col[_w] or newcolh ~= col[_h] or col[_minw] ~= links.minw or col[_minh] ~= links.minh or col[_maxh] ~= links.maxh then
    local ow = col[_w]
    if col.__debug then
      dprint('col', col.id, 'setlimits', links.minw, nil, links.minh, links.maxh, newcolw, newcolh)
    end
    col:setlimits(links.minw, nil, links.minh, links.maxh, newcolw, newcolh)

    if col.__debug then
      dprint('col', col.id, 'w', col.w, 'h', col.h)
    end
    --col is now potentially sized and limited properly
    --a link could have changed its height, through metacel.__resize in response to its width changing
    --so recheck minh, maxh

    if ow ~= col[_w] then
      local colformation = colformation
      local link
      for i = 1, links.n do
        link = links[i]
        if rawget(link, _linker) then
          colformation:dolinker(col, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
        end
      end
      --at this point a link could have changed its height, through metacel.__resize
      --in response to its width changing

      assert(links.brace)

      newcolh = links.minh

      if newcolh ~= col[_h] or col[_minh] ~= links.minh or col[_maxh] ~= links.maxh then
        if col.__debug then
          dprint('col', col.id, 'setlimits2', links.minw, nil, links.minh, links.maxh, col[_w], newcolh)
        end
        col:setlimits(links.minw, nil, links.minh, links.maxh, col[_w], newcolh)
        --col is now sized and limited properly
      end
    end
  end

  dprint('links.minh', links.minh)
  assert(col[_h] >= links.minh, col[_h], links.minh)
end

--reflex becuase the flex ratio of a slot changes
--which means total flex changes or a sinlge slot flex changes
--relex if the *excess* height of a col changes
local function reconcile(col, force)
  dprint('col', col.id, 'reconcile')
  assert(col[_flux] == 0)

  --if we don't have a brace then links.minw may be invalid find the brace
  rebrace(col)
  
  event:wait()

  col[_flux] = 1

  setwidthandheight(col)
  reflexandalign(col)

  col[_flux] = col[_flux] - 1

  event:signal() --TODO move wait/signal outside of this function
end

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

--links = {
--  n=number of links in col
--  gap=gap to put between each slot
--  minh=minh of all slots + gaps, if a slot has no flex, its minh is the height of the link
--  maxh=math.min(maxdim, maxh of all slots + gaps)
--  flex=sum of flex of all slots
--  minw=minw that is >= the right edge of all links
--  maxw=nil, not used, but what if the maxw of a col is changed by the user prevent or allow?
--  brace=the link that has the greatest right edge when its linker is run with a hw of 0
--}

--called anytime col is moved by any method
do --colformation.moved

  local function moveandreconcile(col, x, y, w, h, ox, oy, ow, oh)
    if w ~= ow or h ~= oh then
      dprint('col', col.id, 'moveandreconcile')
      event:onresize(col, ow, oh)

      col[_flux] = 1
      setwidthandheight(col)
      reflexandalign(col)
      col[_flux] = col[_flux] - 1 

      if col[_metacel].__resize then
        col[_metacel]:__resize(col, ow, oh)
      end
    end
  end

  function colformation:moved(col, x, y, w, h, ox, oy, ow, oh)
    if col.__debug then
      dprint('col.moved', col.id, x, y, w, h, ox, oy, ow, oh)
    end

    if col[_flux] == 0 then
      moveandreconcile(col, x, y, w, h, ox, oy, ow, oh)
    elseif w ~= ow or h ~= oh then
      event:onresize(col, ow, oh)
      if col[_metacel].__resize then
        col[_metacel]:__resize(col, ow, oh)
      end
    end

    --joins
    if true then --TODO only do this if a link has joins at all
      local links = col[_links]
      local link 
      for i = 1, links.n do
        link = links[i]
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
end

do --colformation.link
  local getface = M.getface
  local nooption = {}

  function colformation:link(col, link, linker, xval, yval, option)
    option = option or nooption

    local links = col[_links]
    links.n = links.n + 1
    links[links.n] = link

    --TODO resolve when option.minh > option.maxh, minh should prevail
    local slot = {
      fixedlimits = (type(option.minh) == 'number' and 1 or 0) + (type(option.maxh) == 'number' and 2 or 0), --0, 1, 2 or 3
      h = 0,
      y = 0,
      minh = 0,
      maxh = maxdim,
      flex = option.flex and math.floor(option.flex) or 0, 
      face = option.face and getface('cel', option.face) or false,
      linky = 0,
    }

    link[_slot] = slot

    if col.__debug then
      print('col slot.minh', slot.minh)
    end

    do
      local gap = links.n > 1 and links.gap or 0
   
      --slot.minh is the minh of the slot, if false then minh is inherited from the link
      --slot.maxh is the maxh of the slot, if false then maxh is inherited from the link
      --when a slot has flex it starts flexing from the minh of the slot
      
      slot.y = gap + links.minh

      if slot.flex == 0 then
        slot.minh = option.minh == true and link[_minh] or math.floor(option.minh or link[_minh])
        slot.maxh = math.max(slot.minh, option.maxh == true and link[_maxh] or math.floor(option.maxh or link[_maxh]))

        --slot.h = math.max(math.min(slot.maxh, link[_h]), slot.minh)
        slot.h = math.max(math.min(slot.maxh, link[_h]), slot.minh)
        links.minh = links.minh + gap + slot.h
        links.maxh = math.min(links.maxh + gap + slot.h, maxdim)
      else
        slot.minh = option.minh == true and link[_minh] or math.floor(option.minh or 0)
        slot.maxh = math.max(slot.minh, option.maxh == true and link[_maxh] or math.floor(option.maxh or maxdim))

        --local maxh = math.min(slot.maxh, link[_maxh])
        --slot.h = math.min(slot.minh, maxh)
        slot.h = slot.minh
        links.minh = links.minh + gap + slot.minh
        links.maxh = math.min(links.maxh + gap + slot.maxh, maxdim)
        links.flex = links.flex + slot.flex
      end

    end

    link[_y] = slot.y
   
    if linker then
      --get edge before running linker so that links.minw is up to date for current link
      local edge = getbraceedge(link, linker, xval, yval)
      if edge > links.minw then 
        links.brace = link 
        links.minw = edge
      end
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      self:dolinker(col, link, linker, xval, yval)
    else
      link[_x] = math.max(0, math.floor(xval))
      local edge = link[_x] + link[_w]
      if edge > links.minw then 
        links.brace = link 
        links.minw = edge
      end
    end

    event:onlink(col, link, links.n)

    if col[_flux] == 0 then
      reconcile(col)
    end
  end
end

function colformation:relink(col, link, linker, xval, yval)
  local links = col[_links]
  local slot = link[_slot]

  if linker then
    --get edge before running linker so that links.minw is up to date for current link
    local edge = getbraceedge(link, linker, xval, yval)
    if edge > links.minw then 
      links.brace = link 
      links.minw = edge
    elseif links.brace == link and edge < links.minw then
      links.brace = false
    end
    link[_linker] = linker
    link[_xval] = xval
    link[_yval] = yval
    self:dolinker(col, link, linker, xval, yval)
  else
    local edge = link[_x] + link[_w]
    if edge > links.minw then 
      links.brace = link 
      links.minw = edge
    elseif links.brace == link and edge < links.minw then
      links.brace = false
    end
  end

  if slot.flex == 0 then
    links.minh = links.minh - slot.h
    slot.h = math.max(math.min(slot.maxh, link[_h]), slot.minh)
    links.minh = links.minh + slot.h
  end

  if col.__debug then
    dprint('relink brace', links.brace)
  end
 
  if col[_flux] == 0 then
    reconcile(col)
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
    if col.__debug then
          dprint('link.w', link.w)
        end
    celmoved(col, link, x, y, w, h, ox, oy, ow, oh)
  end
end

--colformation.testlinker  TODO make all test linkers optionally take new x, y, w, h
function colformation:testlinker(col, link, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
  nx, ny, nw, nh = nx or link[_x], ny or link[_y], nw or link[_w], nh or link[_h]
  minw, maxw, minh, maxh = minw or link[_minw], maxw or link[_maxw], minh or link[_minh], maxh or link[_maxh]
  local slot = link[_slot]

  --TODO if this link is the brace, then account for the new width wehn linked with the linker
  local sloty = slot.linky
  local x, y, w, h = self:linker(col, link, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
  slot.linky = sloty

  if w > maxw then w = maxw end
  if w < minw then w = minw end
  if h > maxh then h = maxh end
  if h < minh then h = minh end

  return x, y, w, h
end

do --colformation:linker
  --called from dolinker/testlinker
  function colformation:linker(col, link, linker, xval, yval, x, y, w, h, minw, maxw, minh, maxh)
    local slot = link[_slot]
    local links = col[_links]
    local hw = math.max(links.minw, col[_w])
    local hh = slot.h

    x, y, w, h = linker(hw, hh, x, y - slot.y, w, h, xval, yval, minw, maxw, minh, maxh)

    x = math.modf(x)
    y = math.modf(y)
    w = math.floor(w)
    h = math.floor(h)

    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end   
    if h < minh then h = minh end

    --prevent linker from exceeding left and right edge of host
    w = math.min(w, hw)
    x = math.max(0, x)
    if x + w > hw then x = hw - w end

    --linker cannot change the slot under any circumstances, slot does not have a w, that is inherited from col
    --TODO does not have to be 0 and hh, take minh and maxh of slot into consideration
    if slot.flex == 0 then
      if h < hh then
        if y + h > hh then y = hh - h end
        y = math.max(0, y)
      elseif hh < minh then
        h = minh
        if y + h < hh then y = hh - h end
        y = math.min(0, y)
      else
        y = 0
        h = hh
      end
    end

    slot.linky = y

    return x, slot.y + y, w, h
  end
end

do --colformation.movelink
  --movelink should only be called becuase move was explicitly called, make sure that is the case
  local math = math

  local function movelinker(hw, hh, slot, link, linker, xval, yval, x, y, w, h, minw, maxw, minh, maxh)
    x, y, w, h = linker(hw, hh, x, y - slot.y, w, h, xval, yval, minw, maxw, minh, maxh)

    x = math.modf(x)
    y = math.modf(y)
    w = math.floor(w)
    h = math.floor(h)

    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end   
    if h < minh then h = minh end

    --prevent linker from exceeding left and right edge of host
    x = math.max(0, x)

    --linker cannot change the slot under any circumstances, slot does not have a w, that is inherited from col
    --TODO does not have to be 0 and hh, take minh and maxh of slot into consideration
    if slot.flex == 0 then
      if h < hh then
        if y + h > hh then y = hh - h end
        y = math.max(0, y)
      elseif hh < minh then
        h = minh
        if y + h < hh then y = hh - h end
        y = math.min(0, y)
      else
        y = 0
        h = hh
      end
    end

    slot.linky = y

    return x, slot.y + y, w, h
  end

  function colformation:movelink(col, link, x, y, w, h, minw, maxw, minh, maxh, ox, oy, ow, oh)
    local links = col[_links]
    local slot = link[_slot]

    if slot.flex == 0 then 
      --when a link with no flex is moved explicitly, it will change the height of the slot
      --bounded by the maxh of the link and the minh of the slot/link
      if rawget(link, _linker) then
        x, y, w, h = movelinker(col[_w], math.max(math.min(slot.maxh, h), slot.minh), slot, 
                                link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                x, y, w, h, minw, maxw, minh, maxh)
      else
        local hh = math.max(math.min(slot.maxh, h), slot.minh)
        y = y - slot.y  

        if h < hh then
          if y + h > hh then y = hh - h end
          y = math.max(0, y)
        elseif hh < minh then
          h = minh
          if y + h < hh then y = hh - h end
          y = math.min(0, y)
        else
          y = 0
          h = hh
        end

        slot.linky = y
        y = slot.y + y      

        x = math.max(0, x)
      end

      if h ~= oh then
        links.minh = links.minh - slot.h
        slot.h = math.max(math.min(slot.maxh, h), slot.minh)
        links.minh = links.minh + slot.h
      end
    else
      if rawget(link, _linker) then
        x, y, w, h = movelinker(col[_w], slot.h, slot,
                                link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                x, y, w, h, minw, maxw, minh, maxh)
      else
        y = y - slot.y        
        slot.linky = y
        y = slot.y + y      
        x = math.max(0, x)
      end
    end

    link[_x] = x
    link[_w] = w
    link[_y] = y
    link[_h] = h

    do
      local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

      if edge > links.minw then 
        links.brace = link 
        links.minw = edge
      elseif links.brace == link and edge < links.minw then
        links.brace = false
      end
    end

    event:wait()

    if x~= ox or y ~= oy or w ~= ow or h ~= oh then
      celmoved(col, link, x, y, w, h, ox, oy, ow, oh)
    end

    if col[_flux] == 0 then
      reconcile(col)
    end

    event:signal()

    return link
  end
end

do --colformation.linklimitschanged
  function colformation:linklimitschanged(col, link, ominw, omaxw, ominh, omaxh)
    local links = col[_links]
    local slot = link[_slot]

    if slot.flex == 0 then
      links.minh = links.minh - slot.h
      links.maxh = links.maxh - slot.h

      if slot.fixedlimits % 2 ~= 1 then --if slot.minh is inherited from link
        slot.minh = link[_minh]  
      end
      if slot.fixedlimits < 2 then --if slot.maxh is inherited from link
        slot.maxh = link[_maxh]
      end

      slot.maxh = math.max(slot.minh, slot.maxh)

      slot.h = math.max(math.min(slot.maxh, link[_h]), slot.minh)
      links.minh = links.minh + slot.h
      links.maxh = math.min(links.maxh + slot.h, maxdim)
    else
      links.minh = links.minh - slot.minh
      links.maxh = links.maxh - slot.maxh

      if slot.fixedlimits % 2 ~= 1 then --if slot.minh is inherited from link
        slot.minh = link[_minh]  
      end
      if slot.fixedlimits < 2 then --if slot.maxh is inherited from link
        slot.maxh = link[_maxh]
      end

      slot.maxh = math.max(slot.minh, slot.maxh)

      slot.h = slot.minh
      links.minh = links.minh + slot.minh
      links.maxh = math.min(links.maxh + slot.maxh, maxdim)
    end

    if link[_minw] > links.minw then
      local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
      if edge > links.minw then
        links.minw = edge
        links.brace = link
      end
    elseif link == links.brace and link[_minw] < link[_w] then
      local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
      if edge < links.minw then
        links.brace = false 
      end
    end

    if col[_flux] == 0 then
      reconcile(col)
    end
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

    links.n = links.n - 1

    if link == links.brace then
      links.brace = false
    end

    local slot = link[_slot]
    link[_slot] = nil

    local gap = links.n > 1 and links.gap or 0
  
    if slot.flex == 0 then
      links.minh = links.minh - gap - slot.h
    else
      links.minh = links.minh - gap - slot.h
    end

    if col[_metacel].__unlink then
      col[_metacel]:__unlink(col, link, index)
    end

    if col[_flux] == 0 then
      reconcile(col)
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
  local link = colformation:pick(cel, x, y)
  if link and touch(link, x - link[_x], y - link[_y]) then
    return true
  end
  return false
end

do --metatable.setslotflexandlimits
  function metatable:setslotflexandlimits(indexorlink, flex, minh, maxh)
    local links = self[_links]
    local link = type(indexorlink) == 'number' and self:get(indexorlink) or indexorlink
    local slot = link[_slot]
    assert(slot)

    flex = flex or 0

    --undo slot.flex
    links.flex = links.flex - slot.flex

    --undo slot.minh
    if slot.flex == 0 then
      if links[1] ~= link then
        links.minh = links.minh - links.gap - slot.h
      else
        links.minh = links.minh - slot.h
      end
    else
      if links[1] ~= link then
        links.minh = links.minh - links.gap - slot.minh
      else
        links.minh = links.minh - slot.minh
      end
    end

    slot.flex = flex
    slot.minh = minh or link[_minh]
    slot.maxh = maxh or link[_maxh]
    slot.h = math.min(math.max(link[_h], slot.minh), slot.maxh) --TODO to row

    --apply slot.flex
    links.flex = links.flex + slot.flex

    --apply slot.minh
    if slot.flex == 0 then
      if links[1] ~= link then
        links.minh = links.minh + links.gap + slot.h
      else
        links.minh = links.minh + slot.h
      end
    else
      if links[1] ~= link then
        links.minh = links.minh + links.gap + slot.minh
      else
        links.minh = links.minh + slot.minh
      end
    end

    links.reform = true
    if self[_flux] == 0 then
      reconcile(self)
    end

    return self:refresh()
  end
end

do --metatable.setslotface
  function metatable:setslotface(indexorlink, face)
    local link = type(indexorlink) == 'number' and self:get(indexorlink) or indexorlink
    local slot = link[_slot]
    assert(slot)

    if face and not isface(face) then
      face = getface('cel', face)
    end

    slot.face = face

    link:refresh()

    return self
  end
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
  --reconcile(col, true)
  if callback then
    callback(...)
  end
  col[_flux] = col[_flux] - 1
  reconcile(col, true) --this is done after flux reduce becuase the col can be moved by limits changing, such as maxh increasing, then its resized the when respoding to the move it will only do the reconcile if its not in flux
  return col
end

--TODO remove this, or put it in metacel too easy to mess up
function metatable.beginflux(col, doreconcile)
  col[_flux] = col[_flux] + 1
  if doreconcile then 
    --reconcile(col, true) 
  end
  return col
end

--TODO remove this, or put it in metacel too easy to mess up
function metatable.endflux(col, force)
  --ignore force for now
  force = false
  col[_flux] = col[_flux] - 1
  if force == nil then force = true end
  if force or col[_flux] == 0 then
    reconcile(col, force)
  end
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

--TODO make work, TODO make not possible infinite loop
function metatable.indexof(col, item)
  if item[_host] == col then 
    local i = indexof(col, item)

    if col[_links][i] == item then
      return i
    else
      reconcile(col, true)
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

do --metacel.new, metacel.assemble
  local _new = metacel.new
  local slotface = M.getface('cel')
  function metacel:new(gap, face, defaultslotface)
    face = self:getface(face)
    local col = _new(self, 0, 0, face)
    col[_flux] = 0
    col[_links] = {
      brace = false,
      minh = 0,
      maxh = 0,
      minw = 0,
      flex = 0,
      w = 0,
      gap = gap or 0,
      n = 0,
    }

    col[_maxh] = 0    
    col[_slotface] = M.getface('cel', defaultslotface) or slotface
    col[_formation] = colformation
    return col
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, col)
    col = col or metacel:new(t.gap, t.face)
    col[_flux] = 1
    col.onchange = t.onchange
    _assemble(self, t, col)
    col[_flux] = 0 
    reconcile(col)
    return col
  end

  function metacel:assembleentry(col, entry, entrytype, linker, xval, yval, option)
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
          link._ = entry._ or link._
          link:link(col, linker, xval, yval, option or entry)
        end
      end 
    end
  end
end

return metacel:newfactory()
