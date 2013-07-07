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
local table = table

local CEL = require 'cel.core.env'

local _formation = CEL._formation
local _host = CEL._host
local _links = CEL._links
local _slot = CEL._next --intentional rename
local _focus = CEL._focus
local _x = CEL._x
local _y = CEL._y
local _w = CEL._w
local _h = CEL._h
local _metacel = CEL._metacel
local _linker = CEL._linker
local _xval = CEL._xval
local _yval = CEL._yval
local _minw = CEL._minw
local _minh = CEL._minh
local _maxw = CEL._maxw
local _maxh = CEL._maxh
local _disabled = CEL._disabled
local _refresh = CEL._refresh

local _dcache = CEL.privatekey('_dcache')
local _flux = CEL.privatekey('_flux')
local _slotface = CEL.privatekey('_slotface')
local _index = CEL.privatekey('_index')
local _gap = CEL.privatekey('_gap')

local maxdim = CEL.maxdim
local event = CEL.event
local mouse = CEL.mouse
local describe = CEL.describe
local touch = CEL.touch
local celmoved = CEL.celmoved
local testlinker = CEL.testlinker
local getface = CEL.getface

local M = CEL.M

--_a major coordinate
--_b minor coordinate
--_as major size 
--_bs minor size 
for _, _seq_ in ipairs{ 'col', 'row' } do
  local _a = _seq_ == 'col' and _y or _x
  local _b = _seq_ == 'col' and _x or _y
  local _as = _seq_ == 'col' and _h or _w
  local _bs = _seq_ == 'col' and _w or _h
  local _minas = _seq_ == 'col' and _minh or _minw
  local _maxas = _seq_ == 'col' and _maxh or _maxw
  local _minbs = _seq_ == 'col' and _minw or _minh
  local _maxbs = _seq_ == 'col' and _maxw or _maxh

  local formation = {__nojoin=true}

  local function indexof(seq, link)
    local links = seq[_links]
    local index = link[_index]
    --assert(index)

    if links[index] ~= link then
      for i = 1, links.n do
        links[i][_index] = i
        if links[i] == link then
          index = i
          break
        end
      end
    end

    --assert(index == link[_index])
    return index
  end

  local getbraceedge do
    if _seq_ == 'col' then
      function getbraceedge(link, linker, xval, yval)
        if not linker then
          return link[_b] + link[_bs]
        else
          local minw, maxw = link[_minw], link[_maxw]
          local minh, maxh = link[_minh], link[_maxh]
          local x, y, w, h = linker(0, link[_h], link[_x], 0, link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

          if w < minw then w = minw end
          if w > maxw then w = maxw end

          x = math.modf(x)
          w = math.floor(w)


          return math.max(x + w, w, -x)
        end
      end
    else
      function getbraceedge(link, linker, xval, yval)
        if not linker then
          return link[_b] + link[_bs]
        else
          local minw, maxw = link[_minw], link[_maxw]
          local minh, maxh = link[_minh], link[_maxh]
          local x, y, w, h = linker(link[_w], 0, 0, link[_y], link[_w], link[_h], xval, yval, minw, maxw, minh, maxh) 

          if h < minh then h = minh end
          if h > maxh then h = maxh end

          y = math.modf(y)
          h = math.floor(h)

          return math.max(y + h, h, -y)
        end
      end
    end
  end

  --seq w, h and limits shall not mutate as a side effect of this funtion
  --assigns links.brace and links.minbs
  local function rebrace(seq)
    --[[if seq.__debug then dprint(_seq_, seq.id, 'rebrace') end --]]
    local links = seq[_links]

    if not links.brace then
      local oldbraceedge = links.minbs
      local minbs = 0
      local edge, brace, link, slot

      for i = 1, links.n do
        link = links[i]
        slot = link[_slot]

        edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

        if edge >= minbs then
          minbs = edge
          brace = link
          if edge == oldbraceedge then
            break
          end
        end
      end

      --assert(brace or links.n == 0)


      links.brace = brace
      links.minbs = minbs
      --links.bs = math.max(links.minbs, links.bs)
      --[[if seq.__debug then
        dprint(_seq_, seq.id, 'rebrace.2', 'links.minbs', minbs)
        dprint(_seq_, seq.id, 'rebrace.3', 'links.brace', brace)
      end --]]
    end
  end


  local collapse do
    local seqtestlinker do
      if _seq_ == 'col' then 
        function seqtestlinker(seq, host, linker, xval, yval, nas, nbs, minas, maxas, minbs, maxbs)
          local _, _, w, h = testlinker(seq, host, linker, xval, yval, nil, nil, nbs, nas, minbs, maxbs, minas, maxas)
          return h, w
        end
      else
        function seqtestlinker(seq, host, linker, xval, yval, nas, nbs, minas, maxas, minbs, maxbs)
          local _, _, w, h = testlinker(seq, host, linker, xval, yval, nil, nil, nas, nbs, minas, maxas, minbs, maxbs)
          return w, h
        end
      end
    end

    function collapse(seq, links)
      --if we don't have a brace then links.minbs may be invalid find the brace
      rebrace(seq)
      --assert(links.brace or links.n == 0)

      --collapse seq to its min size
      links.as = links.minas
      links.bs = links.minbs

      --[[if seq.__debug then dprint(_seq_, seq.id, 'collapse.1', 'links.as', links.as, 'links.bs', links.bs) end --]]

      --if a linker prevents collapse to min size
      if links.as ~= seq[_as] 
      or links.bs ~= seq[_bs]
      and rawget(seq, _linker) then
        local as, bs = seqtestlinker(seq, seq[_host], rawget(seq, _linker), rawget(seq, _xval), rawget(seq, _yval),
                                      links.as, links.bs, links.as, links.maxas, links.bs, nil)

        --the linker may only increase the seq w and h from its minimum values
        links.as = math.max(links.as, math.min(as, links.maxas))
        links.bs = math.max(links.bs, bs)

        --[[if seq.__debug then dprint(_seq_, seq.id, 'collapse.2', 'links.as', links.as, 'links.bs', links.bs) end --]]
      end
    end
  end

  local setwidthandheight do
    local seqsetlimits do
      if _seq_ == 'col' then
        function seqsetlimits(seq, minas, maxas, minbs, maxbs, nas, nbs)
          --[[if seq.__debug then dprint(_seq_, seq.id, 'setlimits', minbs, maxbs, minas, maxas, nbs, nas) end --]]
          return seq:setlimits(minbs, maxbs, minas, maxas, nbs, nas)
        end
      else
        function seqsetlimits(seq, minas, maxas, minbs, maxbs, nas, nbs)
          --[[if seq.__debug then dprint(_seq_, seq.id, 'setlimits', minas, maxas, minbs, maxbs, nas, nbs) end --]]
          return seq:setlimits(minas, maxas, minbs, maxbs, nas, nbs)
        end
      end
    end


    --seq w, h and limits shall not mutate as a side effect of this
    local function reflexandalign(seq, links)
      --do reflexandalign
      --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign') end --]]
      local unmaxedflex = links.flex
      local extra = links.as - links.minas

      --assert(extra>=0)
      --assign slot.as for each slot with flex
      if unmaxedflex > 0 then 
        local mult = extra/unmaxedflex
        unmaxedflex = 0

        local seqmaxas = 0
        local link
        local slot
        for i = 1, links.n do
          link = links[i]
          slot = link[_slot]

          if slot.flex > 0 then
            --flex
            local maxfromflex = slot.maxas - slot.minas
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.2', 'slot', i, 'maxfromflex', maxfromflex) end --]]
            local take = math.min(maxfromflex, math.floor(slot.flex * mult))
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.3', 'slot', i, 'take', take) end --]]
            --note that as is reduced if link[_minas] > slot.maxas 
            local as = slot.minas + take
       
            extra = extra - take

            if as < slot.maxas then
              unmaxedflex = unmaxedflex + slot.flex
            end

            slot.as = as
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.4', 'slot', i, '.as', slot.as) end --]]
            seqmaxas = math.min(seqmaxas + slot.maxas, maxdim)
          end
        end
        links.maxas = seqmaxas
      end

      --assert(extra>=0)
      --dolinkers to respond to new slot.as
      do --reform TODO only reform when it is necessary, avoid on initial build of seq
        local a = 0
        local gap = seq[_gap]
        local slot
        local link
        local unmaxedflexforthisiteration = unmaxedflex
        for i = 1, links.n do
          link = links[i]
          slot = link[_slot]
          link[_index] = i

          --assign remainint extra to slots with flex
          if extra > 0 and unmaxedflexforthisiteration > 0 and slot.flex > 0 and slot.as < slot.maxas then
            local take = math.min(math.ceil(slot.flex/unmaxedflexforthisiteration*extra), slot.maxas - slot.as)

            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.5', 'slot', i, '.maxas', slot.maxas, 'take', take) end --]]

            slot.as = slot.as + take

            
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.6', 'slot', i, '.as', slot.as) end --]]
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.6.0.1', 'slot', i, 'extra', extra) end --]]
            extra = extra - take

            if slot.as == slot.maxas then
              unmaxedflex = unmaxedflex-slot.flex
            end
          end

          --TODO limit maxas of seq if necessary 

          if rawget(link, _linker) then
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.6.1', 'slot', i, '.a', slot.a, '.as', slot.as) end --]]
            formation:dolinker(seq, link, link[_linker], rawget(link, _xval), rawget(link, _yval))
            --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.6.2', 'slot', i, '.a', slot.a, '.as', slot.as) end --]]
          end

          slot.a = a
          link[_a] = slot.a + (slot.linka or 0)
          a = a + slot.as + gap

          --[[if seq.__debug then dprint(_seq_, seq.id, 'reflexandalign.7', 'slot', i, '.a', slot.a, '.as', slot.as) end --]]
          --[[joins
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
          --]]
        end
      end
    end

    --[[
    --get new w and h of seq (stored in links.as and links.bs)
    --allocate flex
    --run linkers using new bs for linkers
    --rebrace and run linekers and check for change in new bs
    --if new bs changed, run linkers again with new bs, do not allow 
    --set w and h and limits of seq
    --]]
    function setwidthandheight(seq, depth)
      depth = depth or 1
      --[[if seq.__debug then dprint(_seq_, seq.id, 'setwidthandheight', 'depth', depth) end --]]
      local links = seq[_links]

      collapse(seq, links)

      local linksas = links.as
      local linksbs = links.bs

      reflexandalign(seq, links)

      --a link could have changed its bs, through metacel.__resize in response to its as changing
      --[[if seq.__debug then dprint(_seq_, seq.id, 'setwidthandheight.1', 'links.brace', links.brace) end --]]

      --[[if seq.__debug then dprint(_seq_, seq.id, 'setwidthandheight.1.1', 'links.minbs', links.minbs) end --]]

      collapse(seq, links)

      if links.as ~= linksas
      or links.bs ~= linksbs then
        reflexandalign(seq, links)
      end

      if seq[_as] ~= links.as
      or seq[_bs] ~= links.bs
      or seq[_minas] ~= links.minas 
      or seq[_maxas] ~= links.maxas 
      or seq[_minbs] ~= links.minbs then 
        seqsetlimits(seq, links.minas, links.maxas, links.minbs, nil, links.as, links.bs) 
        --[[if seq.__debug then dprint(_seq_, seq.id, 'setwidthandheight.9', 'w', seq.w, 'h', seq.h) end --]]
        if seq[_as] ~= links.as 
        or seq[_bs] ~= links.bs then
          return setwidthandheight(seq, depth + 1)
        end
      end

      --assert(seq[_as] == links.as)
      --assert(seq[_bs] == links.bs)
      --[[if seq.__debug then dprint(_seq_, seq.id, 'setwidthandheight.10', 'links.minas', links.minas) end --]]
      --assert(seq[_as] >= links.minas)
      --[[if seq.__debug then dprint(_seq_, seq.id, 'setwidthandheight.11', 'w', seq.w, 'h', seq.h) end --]]
    end
  end

  --reflex becuase the flex ratio of a slot changes
  --which means total flex changes or a sinlge slot flex changes
  --relex if the *excess* as of a seq changes
  local function reconcile(seq)
    --[[if seq.__debug then dprint(_seq_, seq.id, 'reconcile') end --]]
    --assert(seq[_flux] == 0)
    
    event:wait()
    seq[_flux] = 1
    setwidthandheight(seq)
    seq[_flux] = seq[_flux] - 1
    --[[if seq.__debug then dprint(_seq_, seq.id, 'END reconcile') end --]]
    event:signal() --TODO move wait/signal outside of this function
  end

  --called anytime seq is moved by any method
  do --formation.moved
    local moveandreconcile 
    if _seq_ == 'col' then
      function moveandreconcile(seq, x, y, w, h, ox, oy, ow, oh)
        if w ~= ow or h ~= oh then
          --[[if seq.__debug then seq.marc = seq.marc and seq.marc + 1 or 1 dprint(_seq_, seq.id, 'moveandreconcile.1', seq.marc) end --]]
          
          event:onresize(seq, ow, oh)

          seq[_flux] = 1

          local links = seq[_links]
          collapse(seq, links)

          if links.as ~= oh 
          or links.bs ~= ow then
            setwidthandheight(seq)
          end

          seq[_flux] = seq[_flux] - 1 

          if seq[_metacel].__resize then
            seq[_metacel]:__resize(seq, ow, oh)
          end

          --[[if seq.__debug then seq.marc = seq.marc - 1 dprint(_seq_, seq.id, 'moveandreconcile.2', seq.marc) end --]]
        end
      end
    else
      function moveandreconcile(seq, x, y, w, h, ox, oy, ow, oh)
        if w ~= ow or h ~= oh then
          --[[if seq.__debug then seq.marc = seq.marc and seq.marc + 1 or 1 dprint(_seq_, seq.id, 'moveandreconcile.1', seq.marc) end --]]
          
          event:onresize(seq, ow, oh)

          seq[_flux] = 1

          local links = seq[_links]
          collapse(seq, links)

          if links.as ~= ow 
          or links.bs ~= oh then
            setwidthandheight(seq)
          end

          seq[_flux] = seq[_flux] - 1 

          if seq[_metacel].__resize then
            seq[_metacel]:__resize(seq, ow, oh)
          end

          --[[if seq.__debug then seq.marc = seq.marc - 1 dprint(_seq_, seq.id, 'moveandreconcile.2', seq.marc) end --]]
        end
      end
    end

    function formation:moved(seq, x, y, w, h, ox, oy, ow, oh)
      --[[if seq.__debug then dprint(_seq_, seq.id, 'moved', x, y, w, h, ox, oy, ow, oh) end --]]

      if seq[_flux] == 0 then
        moveandreconcile(seq, x, y, w, h, ox, oy, ow, oh)
      elseif w ~= ow or h ~= oh then
        event:onresize(seq, ow, oh)
        if seq[_metacel].__resize then
          seq[_metacel]:__resize(seq, ow, oh)
        end
      end

      --[[joins
      if true then --TODO only do this if a link has joins at all
        local links = seq[_links]
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
      --]]
    end
  end

  --if not flex then
  --  if minw/h == number then
  --    slot.minw/h = minw/h 
  --  elseif minw/h == true then
  --    slot.minw/h = link.minw/h
  --  else
  --    slot.minw/h = link.minw/h
  --  end
  --  if maxw/h == number then
  --    slot.maxw/h = math.max(slot.minw/h, maxw/h)
  --  elseif maxw/h == true then
  --    slot.maxw/h = math.max(slot.minw/h, link.maxw/h)
  --  else
  --    slot.maxw/h = math.max(slot.minw/h, link.maxw/h)
  --  end
  --
  --  slot.w/h = math.max(math.min(slot.maxw/h, link.w/h), slot.minw/h)
  --else
  --  if minw/h == number then
  --    slot.minw/h = minw/h
  --  elseif minw/h == true then
  --    slot.minw/h = link.minw/h
  --  else
  --    slot.minw/h = 0
  --  end
  --  if maxw/h == number then
  --    slot.maxw/h = math.max(slot.minw/h, maxw/h)
  --  elseif maxw/h == true then
  --    slot.maxw/h = math.max(slot.minw/h, link.maxw/h)
  --  else
  --    slot.maxw/h = maxdim 
  --  end
  --  
  --  slot.w/h = slot.minw/h
  --end
  do --formation.link
    local nooption = {}
    
    function formation:link(seq, link, linker, xval, yval, option)
      --[[if seq.__debug then dprint(_seq_, seq.id, 'link', link) end --]]
      option = option or nooption

      local links = seq[_links]
      links.n = links.n + 1
      links[links.n] = link
      link[_index] = links.n --TODO remove index on unlink

      --TODO for col resolve when option.minh > option.maxh, minh should prevail
      --TODO for row resolve when option.minw > option.maxw, minw should prevail

      local minas = _seq_ == 'col' and option.minh or option.minw
      local maxas = _seq_ == 'col' and option.maxh or option.maxw

      local slot = {
        fixedlimits = 0,
        flex = option.flex and math.floor(option.flex) or 0, 
        face = option.face and getface('cel', option.face) or false,
        as = 0, --h = 0,
        a = 0, --y = 0,
        minas = 0, --minh = 0,
        maxas = maxdim, --maxh = maxdim,
        linka = 0, --linky = 0,
      }

      link[_slot] = slot

      do
        local gap = links.n > 1 and seq[_gap] or 0
     
        --slot.minas is the minas of the slot, if false then minas is inherited from the link
        --slot.maxas is the maxas of the slot, if false then maxas is inherited from the link
        --when a slot has flex it starts flexing from the minas of the slot
        
        slot.a = gap + links.minas

        if slot.flex == 0 then
          slot.fixedlimits = (type(minas) == 'number' and 1 or 0) + (type(maxas) == 'number' and 2 or 0) --0, 1, 2 or 3
          slot.minas = minas == true and link[_minas] or math.floor(minas or link[_minas])
          slot.maxas = math.max(slot.minas, maxas == true and link[_maxas] or math.floor(maxas or link[_maxas]))
          slot.as = math.max(math.min(slot.maxas, link[_as]), slot.minas)
          --[[if seq.__debug then 
            dprint(_seq_, seq.id, 'link.1', 'slot', links.n, '.minas', slot.minas, '.maxas', slot.maxas, '.as', slot.as) 
          end --]]
          links.minas = links.minas + gap + slot.as
          links.maxas = math.min(links.maxas + gap + slot.as, maxdim)
        else
          slot.fixedlimits = (minas ~= true and 1 or 0) + (maxas ~= true and 2 or 0) --0, 1, 2 or 3
          slot.minas = minas == true and link[_minas] or math.floor(minas or 0)
          slot.maxas = math.max(slot.minas, maxas == true and link[_maxas] or math.floor(maxas or maxdim))
          slot.as = slot.minas
          --[[if seq.__debug then 
            dprint(_seq_, seq.id, 'link.2', 'slot', links.n, '.minas', slot.minas, '.maxas', slot.maxas, '.as', slot.as) 
          end --]]
          links.minas = links.minas + gap + slot.minas
          links.maxas = math.min(links.maxas + gap + slot.maxas, maxdim)
          links.flex = links.flex + slot.flex
        end
        --[[if seq.__debug then dprint(_seq_, seq.id, 'link.3', 'links.minas', links.minas, 'links.maxas', links.maxas) end --]]

      end

      link[_a] = slot.a
     
      if linker then
        --get edge before running linker so that links.minbs is up to date for current link
        local edge = getbraceedge(link, linker, xval, yval)
        if edge > links.minbs then 
          links.brace = link 
          links.minbs = edge
          --[[if seq.__debug then dprint(_seq_, seq.id, 'link.4', 'links.minbs', links.minbs) end --]]
        end
        link[_linker] = linker
        link[_xval] = xval
        link[_yval] = yval
        self:dolinker(seq, link, linker, xval, yval)
      else
        local bval = _seq_ == 'col' and xval or yval
        link[_b] = math.max(0, math.floor(bval))
        local edge = link[_b] + link[_bs]
        if edge > links.minbs then 
          links.brace = link 
          links.minbs = edge
          --[[if seq.__debug then dprint(_seq_, seq.id, 'link.5', 'links.minbs', links.minbs) end --]]
        end
      end

      event:onlink(seq, link, links.n)

      if seq[_flux] == 0 then
        reconcile(seq)
      end
    end
  end

  function formation:relink(seq, link, linker, xval, yval)
    --[[if seq.__debug then dprint(_seq_, seq.id, 'relink') end --]]
    local links = seq[_links]
    local slot = link[_slot]

    if linker then
      --get edge before running linker so that links.minbs is up to date for current link
      local edge = getbraceedge(link, linker, xval, yval)
      --[[if seq.__debug then dprint(_seq_, seq.id, 'relink', 'edge', edge) end --]]
      if edge > links.minbs then 
        links.brace = link 
        links.minbs = edge
        --[[if seq.__debug then dprint(_seq_, seq.id, 'relink.1', 'links.minbs', links.minbs) end --]]
      elseif links.brace == link and edge < links.minbs then
        links.brace = false
      end
      link[_linker] = linker
      link[_xval] = xval
      link[_yval] = yval
      self:dolinker(seq, link, linker, xval, yval)
    else
      local edge = link[_b] + link[_bs]
      if edge > links.minbs then 
        links.brace = link 
        links.minbs = edge
        --[[if seq.__debug then dprint(_seq_, seq.id, 'relink.2', 'links.minbs', links.minbs) end --]]
      elseif links.brace == link and edge < links.minbs then
        links.brace = false
      end
    end

    if slot.flex == 0 then
      links.minas = links.minas - slot.as
      slot.as = math.max(math.min(slot.maxas, link[_as]), slot.minas)
      links.minas = links.minas + slot.as
    end

    --[[if seq.__debug then dprint(_seq_, seq.id, 'relink', 'brace', links.brace) end --]]
   
    if seq[_flux] == 0 then
      reconcile(seq)
    end
  end

  --called anytime the link[_linker] needs to be enforced
  --formation.dolinker
  function formation:dolinker(seq, link, linker, xval, yval)
    local ox, oy, ow, oh = link[_x], link[_y], link[_w], link[_h]
    local minw, maxw, minh, maxh = link[_minw], link[_maxw], link[_minh], link[_maxh]
    local x, y, w, h = self:linker(seq, link, linker, xval, yval, ox, oy, ow, oh, minw, maxw, minh, maxh)

    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end
    if h < minh then h = minh end

    --[[if seq.__debug then dprint(_seq_, seq.id, 'dolinker', link, x, y, w, h) end --]]
    if x ~= ox 
    or y ~= oy 
    or w ~= ow 
    or h ~= oh then
      link[_x] = x
      link[_w] = w
      link[_y] = y
      link[_h] = h
      --[[if seq.__debug then dprint(_seq_, seq.id, 'dolinker.celmoved', link, x, y, w, h, ox, oy, ow, oh) end --]]
      celmoved(seq, link, x, y, w, h, ox, oy, ow, oh)
    end
  end

  --formation.testlinker  TODO make all test linkers optionally take new x, y, w, h
  function formation:testlinker(seq, link, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
    nx, ny, nw, nh = nx or link[_x], ny or link[_y], nw or link[_w], nh or link[_h]
    minw, maxw, minh, maxh = minw or link[_minw], maxw or link[_maxw], minh or link[_minh], maxh or link[_maxh]
    local slot = link[_slot]

    --TODO if this link is the brace, then account for the new bs when linked with the linker
    local slota = slot.linka
    local x, y, w, h = self:linker(seq, link, linker, xval, yval, nx, ny, nw, nh, minw, maxw, minh, maxh)
    slot.linka = slota

    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end
    if h < minh then h = minh end

    return x, y, w, h
  end

  --called from dolinker/testlinker
  if _seq_ == 'col' then  
    function formation:linker(seq, link, linker, xval, yval, b, a, bs, as, minbs, maxbs, minas, maxas)
      local slot = link[_slot]
      local links = seq[_links]
      local hbs = math.max(links.minbs, links.bs) --TODO should be just links.bs, why can't it be
      local has = slot.as

      b, a, bs, as = linker(hbs, has, b, a - slot.a, bs, as, xval, yval, minbs, maxbs, minas, maxas)

      b = math.modf(b)
      a = math.modf(a)
      bs = math.floor(bs)
      as = math.floor(as)

      if bs > maxbs then bs = maxbs end
      if bs < minbs then bs = minbs end
      if as > maxas then as = maxas end   
      if as < minas then as = minas end

      --prevent linker from exceeding (left and right) edge of host
      bs = math.min(bs, hbs)
      b = math.max(0, b)
      if b + bs > hbs then b = hbs - bs end

      --linker cannot change the slot under any circumstances, slot does not have a bs, that is inherited from seq
      --TODO does not have to be 0 and has, take minas and maxas of slot into consideration
      if slot.flex == 0 then
        if as < has then
          if a + as > has then a = has - as end
          a = math.max(0, a)
        elseif has < minas then
          as = minas
          if a + as < has then a = has - as end
          a = math.min(0, a)
        else
          a = 0
          as = has
        end
      end

      slot.linka = a

      return b, slot.a + a, bs, as
    end
  else
    function formation:linker(seq, link, linker, xval, yval, a, b, as, bs, minas, maxas, minbs, maxbs)
      local slot = link[_slot]
      local links = seq[_links]
      local hbs = math.max(links.minbs, links.bs)
      local has = slot.as

      a, b, as, bs = linker(has, hbs, a - slot.a, b, as, bs, xval, yval, minas, maxas, minbs, maxbs)

      b = math.modf(b)
      a = math.modf(a)
      bs = math.floor(bs)
      as = math.floor(as)

      if bs > maxbs then bs = maxbs end
      if bs < minbs then bs = minbs end
      if as > maxas then as = maxas end   
      if as < minas then as = minas end

      --prevent linker from exceeding (top and bottom) edge of host
      bs = math.min(bs, hbs)
      b = math.max(0, b)
      if b + bs > hbs then b = hbs - bs end

      --linker cannot change the slot under any circumstances, slot does not have a bs, that is inherited from seq
      --TODO does not have to be 0 and has, take minas and maxas of slot into consideration
      if slot.flex == 0 then
        if as < has then
          if a + as > has then a = has - as end
          a = math.max(0, a)
        elseif has < minas then
          as = minas
          if a + as < has then a = has - as end
          a = math.min(0, a)
        else
          a = 0
          as = has
        end
      end

      slot.linka = a

      return slot.a + a, b, as, bs
    end
  end

  --formation.movelink
  if _seq_ == 'col' then
    local function movelinker(slot, has, hbs, link, linker, xval, yval, a, b, as, bs, minas, maxas, minbs, maxbs)
      b, a, bs, as = linker(hbs, has, b, a - slot.a, bs, as, xval, yval, minbs, maxbs, minas, maxas)

      b = math.modf(b)
      a = math.modf(a)
      bs = math.floor(bs)
      as = math.floor(as)

      if bs > maxbs then bs = maxbs end
      if bs < minbs then bs = minbs end
      if as > maxas then as = maxas end   
      if as < minas then as = minas end

      --prevent linker from exceeding (left and right) edge of host
      b = math.max(0, b)  --TODO is the below correct, why was i not checking against exceeding hbs

      --prevent linker from exceeding (left and right) edge of host
      --bs = math.min(bs, hbs)
      --b = math.max(0, b)
      --if b + bs > hbs then b = hbs - bs end

      --linker cannot change the slot under any circumstances, slot does not have a bs, that is inherited from seq
      --TODO does not have to be 0 and has, take minas and maxas of slot into consideration
      if slot.flex == 0 then
        if as < has then
          if a + as > has then a = has - as end
          a = math.max(0, a)
        elseif has < minas then
          as = minas
          if a + as < has then a = has - as end
          a = math.min(0, a)
        else
          a = 0
          as = has
        end
      end

      slot.linka = a

      return b, slot.a + a, bs, as
    end

    function formation:movelink(seq, link, b, a, bs, as, minbs, maxbs, minas, maxas, ob, oa, obs, oas)
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink') end --]]
      local links = seq[_links]
      local slot = link[_slot]

      if slot.flex == 0 then 
        --when a link with no flex is moved explicitly, it will change the as of the slot
        --bounded by the maxas of the link and the minas of the slot/link
        if rawget(link, _linker) then
          b, a, bs, as = movelinker(slot, math.max(math.min(slot.maxas, as), slot.minas), math.max(links.minbs, links.bs), 
                                    link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                    a, b, as, bs, minas, maxas, minbs, maxbs)
        else
          local has = math.max(math.min(slot.maxas, as), slot.minas)
          a = a - slot.a  

          if as < has then
            if a + as > has then a = has - as end
            a = math.max(0, a)
          elseif has < minas then
            as = minas
            if a + as < has then a = has - as end
            a = math.min(0, a)
          else
            a = 0
            as = has
          end

          slot.linka = a
          a = slot.a + a      

          b = math.max(0, b)
        end

        if as ~= oas then
          links.minas = links.minas - slot.as
          links.maxas = links.maxas - slot.as
          slot.as = math.max(math.min(slot.maxas, as), slot.minas)
          links.minas = links.minas + slot.as
          links.maxas = math.min(links.maxas + slot.as, maxdim)
          
          --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink.1.2', 'slot.minas', slot.minas, 'slot.maxas', slot.maxas) end --]]
          --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink.1.3', 'slot.as', slot.as, 'links.minas', links.minas, 'links.maxas', links.maxas) end --]]
        end
      else
        if rawget(link, _linker) then
          b, a, bs, as = movelinker(slot, slot.as, math.max(links.minbs, links.bs), 
                                    link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                    a, b, as, bs, minas, maxas, minbs, maxbs)
        else
          a = a - slot.a        
          slot.linka = a
          a = slot.a + a      
          b = math.max(0, b)
        end
      end

      link[_b] = b
      link[_bs] = bs
      link[_a] = a
      link[_as] = as

      do
        local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

        if edge > links.minbs then 
          links.brace = link 
          links.minbs = edge
          --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink.2', 'links.minbs', links.minbs) end --]]
        elseif links.brace == link and edge < links.minbs then
          links.brace = false
        end
      end

      event:wait()

      if b~= ob 
      or a ~= oa 
      or bs ~= obs 
      or as ~= oas then
        --celmoved(seq, link, x, y, w, h, ox, oy, ow, oh)
        --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink.3', 'celmoved', link, b, a, bs, as, ob, oa, obs, oas) end --]]
        celmoved(seq, link, b, a, bs, as, ob, oa, obs, oas)
      end

      if seq[_flux] == 0 then
        reconcile(seq)
      end

      event:signal()

      return link
    end
  else
    local function movelinker(slot, has, hbs, link, linker, xval, yval, a, b, as, bs, minas, maxas, minbs, maxbs)
      a, b, as, bs = linker(has, hbs, a - slot.a, b, as, bs, xval, yval, minas, maxas, minbs, maxbs)

      b = math.modf(b)
      a = math.modf(a)
      bs = math.floor(bs)
      as = math.floor(as)

      if bs > maxbs then bs = maxbs end
      if bs < minbs then bs = minbs end
      if as > maxas then as = maxas end   
      if as < minas then as = minas end

      --prevent linker from exceeding (top and bottom) edge of host
      b = math.max(0, b)  --TODO is the below correct, why was i not checking against exceeding hbs

      --prevent linker from exceeding (top and bottom) edge of host
      --bs = math.min(bs, hbs)
      --b = math.max(0, b)
      --if b + bs > hbs then b = hbs - bs end

      --linker cannot change the slot under any circumstances, slot does not have a bs, that is inherited from seq
      --TODO does not have to be 0 and has, take minas and maxas of slot into consideration
      if slot.flex == 0 then
        if as < has then
          if a + as > has then a = has - as end
          a = math.max(0, a)
        elseif has < minas then
          as = minas
          if a + as < has then a = has - as end
          a = math.min(0, a)
        else
          a = 0
          as = has
        end
      end

      slot.linka = a

      return slot.a + a, b, as, bs
    end

    function formation:movelink(seq, link, a, b, as, bs, minas, maxas, minbs, maxbs, oa, ob, oas, obs)
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink') end --]]
      local links = seq[_links]
      local slot = link[_slot]

      if slot.flex == 0 then 
        --when a link with no flex is moved explicitly, it will change the as of the slot
        --bounded by the maxas of the link and the minas of the slot/link
        if rawget(link, _linker) then
          a, b, as, bs = movelinker(slot, math.max(math.min(slot.maxas, as), slot.minas), math.max(links.minbs, links.bs), 
                                    link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                    a, b, as, bs, minas, maxas, minbs, maxbs)
        else
          local has = math.max(math.min(slot.maxas, as), slot.minas)
          a = a - slot.a  

          if as < has then
            if a + as > has then a = has - as end
            a = math.max(0, a)
          elseif has < minas then
            as = minas
            if a + as < has then a = has - as end
            a = math.min(0, a)
          else
            a = 0
            as = has
          end

          slot.linka = a
          a = slot.a + a      

          b = math.max(0, b)
        end

        if as ~= oas then
          links.minas = links.minas - slot.as
          links.maxas = links.maxas - slot.as
          slot.as = math.max(math.min(slot.maxas, as), slot.minas)
          links.minas = links.minas + slot.as
          links.maxas = math.min(links.maxas + slot.as, maxdim)
        end
      else
        if rawget(link, _linker) then
          a, b, as, bs = movelinker(slot, slot.as, math.max(links.minbs, links.bs), 
                                    link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval),
                                    a, b, as, bs, minas, maxas, minbs, maxbs)
        else
          a = a - slot.a        
          slot.linka = a
          a = slot.a + a      
          b = math.max(0, b)
        end
      end

      link[_b] = b
      link[_bs] = bs
      link[_a] = a
      link[_as] = as

      do
        local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))

        if edge > links.minbs then 
          links.brace = link 
          links.minbs = edge
          --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink.2', 'links.minbs', links.minbs) end --]]
        elseif links.brace == link and edge < links.minbs then
          links.brace = false
        end
      end

      event:wait()

      if b~= ob 
      or a ~= oa 
      or bs ~= obs 
      or as ~= oas then
        --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'movelink.3', 'celmoved', link, a, b, as, bs, oa, ob, oas, obs) end --]]
        celmoved(seq, link, a, b, as, bs, oa, ob, oas, obs)
      end

      if seq[_flux] == 0 then
        reconcile(seq)
      end

      event:signal()

      return link
    end
  end

  function formation:setlinklimits(seq, link, minw, maxw, minh, maxh, w, h)
    link[_minw] = minw
    link[_maxw] = maxw
    link[_minh] = minh
    link[_maxh] = maxh

    --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged', link) end --]]
    local links = seq[_links]
    local slot = link[_slot]

    if slot.flex == 0 then
      links.minas = links.minas - slot.as
      links.maxas = links.maxas - slot.as

      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.1', 'slot.fixedlimits', slot.fixedlimits) end --]]
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.1.1', 'slot.minas', slot.minas, 'slot.maxas', slot.maxas) end --]]
      if slot.fixedlimits % 2 ~= 1 then --if slot.minas is inherited from link
        slot.minas = link[_minas]  
      end
      if slot.fixedlimits < 2 then --if slot.maxas is inherited from link
        slot.maxas = link[_maxas]
      end
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.1.2', 'slot.minas', slot.minas, 'slot.maxas', slot.maxas) end --]]

      slot.maxas = math.max(slot.minas, slot.maxas)

      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.1.2.1', 'link[_as]', link[_as]) end --]]
      slot.as = math.max(math.min(slot.maxas, link[_as]), slot.minas)
      links.minas = links.minas + slot.as
      links.maxas = math.min(links.maxas + slot.as, maxdim)
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.1.3', 'links.minas', links.minas, 'links.maxas', links.maxas) end --]]
    else
      links.minas = links.minas - slot.minas
      links.maxas = links.maxas - slot.maxas

      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.2', 'slot.fixedlimits', slot.fixedlimits) end --]]
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.2.1', 'slot.minas', slot.minas, 'slot.maxas', slot.maxas) end --]]
      if slot.fixedlimits % 2 ~= 1 then --if slot.minas is inherited from link
        slot.minas = link[_minas]  
      end
      if slot.fixedlimits < 2 then --if slot.maxas is inherited from link
        slot.maxas = link[_maxas]
      end

      slot.maxas = math.max(slot.minas, slot.maxas)

      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.3', 'slot.minas', slot.minas, 'slot.maxas', slot.maxas) end --]]
      --slot.as = math.max(math.min(slot.maxas, link[_as]), slot.minas)
      links.minas = links.minas + slot.minas
      links.maxas = math.min(links.maxas + slot.maxas, maxdim)
    end

    if w ~= link[_w] or h ~= link[_h] then
      formation:movelink(seq, link, link[_x], link[_y], w, h, minw, maxw, minh, maxh, link[_x], link[_y], link[_w], link[_h])
      return --move link will dolinker, getbraceedge, and reconcile 
    end

    if rawget(link, _linker) then
      formation:dolinker(seq, link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
    end

    local edge = getbraceedge(link, rawget(link, _linker), rawget(link, _xval), rawget(link, _yval))
    --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.4', 'edge', edge, link, link.x, link.w) end --]]
    if edge > links.minbs then
      links.minbs = edge
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.5', 'links.minbs', links.minbs, link[_minbs]) end --]]
      links.brace = link
    elseif link == links.brace and edge < links.minbs then
      --[[if seq.__debug or link.__debug then dprint(_seq_, seq.id, 'linklimitschanged.6', 'links.minbs', links.minbs, 'edge', edge) end --]]
      links.brace = false 
    end

    if seq[_flux] == 0 then
      reconcile(seq)
    end
  end

  --TODO make this work when clearing, in which case seq[_links] is empty
  function formation:unlink(seq, link)
    --[[if seq.__debug then dprint(_seq_, seq.id, 'unlink', link) end --]]
    local links = seq[_links]
    local index = indexof(seq, link)

    table.remove(links, index)

    links.n = links.n - 1

    if link == links.brace then
      links.brace = false
    end

    local slot = link[_slot]
    link[_slot] = nil

    local gap = links.n > 0 and seq[_gap] or 0
  
    if slot.flex == 0 then
      links.minas = links.minas - gap - slot.as
      links.maxas = links.maxas - gap - slot.as

    else
      links.minas = links.minas - gap - slot.minas
      links.maxas = links.maxas - gap - slot.maxas
    end

    if seq[_metacel].__unlink then
      seq[_metacel]:__unlink(seq, link, index)
    end

    if seq[_flux] == 0 then
      reconcile(seq)
    end
  end

  do --formation.pick
    --TODO make sure works with 0 as slots
    local function pick(seq, ain)
      local links = seq[_links]
      local floor = math.floor
      local istart, iend, imid = 1, links.n, 0
      local gap = seq[_gap]

      while istart <= iend do
        imid = floor( (istart+iend)/2 )
        local value = links[imid][_slot].a
        local range = links[imid][_slot].as + gap 
        if ain >= value and ain < value + range then
          return links[imid], imid
        elseif ain < value then
          iend = imid - 1
        else
          if not (ain >= value + range) then
            --assert(ain >= value + range)
          end
          istart = imid + 1
        end
      end
    end

    if _seq_ == 'col' then
      function formation:pick(seq, x, y) return pick(seq, y) end
    else
      function formation:pick(seq, x, y) return pick(seq, x) end
    end
  end


  do --formation.describelinks
    local cache = setmetatable({}, {__mode='kv'})

    local function initdcache(seq, a, b)
      local dcache = seq[_dcache]
      if not dcache then
        dcache = setmetatable({}, {__mode='kv'})
        seq[_dcache] = dcache 
      end
      dcache.offset = a-1
    end

    local function getdescription(seq, index)
      local dcache = seq[_dcache]
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

    local describeslot
    if _seq_ == 'col' then
      function describeslot(seq, host, gx, gy, gl, gt, gr, gb, index, link, hasmouse, fullrefresh)
        local slot = link[_slot]

        gy = gy + slot.a

        if gy > gt then gt = gy end
        if gy + slot.as < gb then gb = gy + slot.as end

        if gr <= gl or gb <= gt then return end

        local face = slot.face or seq[_slotface]

        local t = getdescription(seq, index)

        t.id = 0 --virtual, find a way to assign an id
        t.metacel = '['.. index ..']'
        t.face = face
        t.host = host
        t.x = 0
        t.y = slot.a
        t.w = seq[_bs]
        t.h = slot.as
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

        do
          local a = link[_a] 
          link[_a] = slot.linka or 0 --TODO bad hack, do this another way 
          t[1] = describe(link, t, gx, gy, gl, gt, gr, gb, fullrefresh)
          link[_a] = a
        end

        return t
      end
    else
      function describeslot(seq, host, gx, gy, gl, gt, gr, gb, index, link, hasmouse, fullrefresh)
        local slot = link[_slot]

        gx = gx + slot.a

        if gx > gl then gl = gx end
        if gx + slot.as < gr then gr = gx + slot.as end

        if gr <= gl or gb <= gt then return end

        local face = slot.face or seq[_slotface]

        local t = getdescription(seq, index)

        t.id = 0 --virtual, find a way to assign an id
        t.metacel = '['.. index ..']'
        t.face = face
        t.host = host
        t.x = slot.a
        t.y = 0
        t.w = slot.as
        t.h = seq[_bs]
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

        do
          local a = link[_a] 
          link[_a] = slot.linka or 0 --TODO bad hack, do this another way 
          t[1] = describe(link, t, gx, gy, gl, gt, gr, gb, fullrefresh)
          link[_a] = a
        end

        return t
      end
    end

    --formation.describelinks
    function formation:describelinks(seq, host, gx, gy, gl, gt, gr, gb, fullrefresh)
      local links = seq[_links]
      local nlinks = links.n

      if nlinks > 0 then
        local _, a = self:pick(seq, gl - gx, gt - gy)
        local _, b = self:pick(seq, gr - gx, gb - gy)

        if a and a > 1 then a = a - 1 end
        if b and b < nlinks then b = b + 1 end

        a = a or 1
        b = b or nlinks

        local vcel
        if mouse[_focus][seq] then
          local x, y = seq.X, seq.Y
          vcel = self:pick(seq, mouse[_x] - x, mouse[_y] - y) --TODO allow pick to accept a search range
        end

        local i = 1
        local n = #host
        initdcache(seq, a, b)
        for index = a, b do
          host[i] = describeslot(seq, host, gx, gy, gl, gt, gr, gb, index, links[index], vcel == links[index], fullrefresh)
          i = host[i] and i + 1 or i
        end
        for i = i, n do
          host[i]=nil
        end
      end
    end
  end

  --define metacel
  local metacel, metatable = CEL.metacel:newmetacel(_seq_)

  function metacel:touch(cel, x, y)
    local link = formation:pick(cel, x, y)
    if link and touch(link, x - link[_x], y - link[_y]) then
      return true
    end
    return false
  end

  function metatable:setslotflexandlimits(indexorlink, flex, minas, maxas)
    --[[if self.__debug then dprint(_seq_, self.id, 'setslotflexandlimits', indexorlink) end --]]
    local links = self[_links]
    local link = type(indexorlink) == 'number' and self:get(indexorlink) or indexorlink
    local slot = link[_slot]
    --assert(slot)

    --undo slot.flex
    links.flex = links.flex - slot.flex

    --undo slot.minas/maxas
    if slot.flex == 0 then
      links.minas = links.minas - slot.as
      links.maxas = links.maxas - slot.as
    else
      links.minas = links.minas - slot.minas
      links.maxas = links.maxas - slot.maxas
    end

    slot.fixedlimits = (type(minas) == 'number' and 1 or 0) + (type(maxas) == 'number' and 2 or 0) --0, 1, 2 or 3
    slot.flex = flex and math.floor(flex) or slot.flex --if flex is nil, use current 

    --apply slot.minas
    if slot.flex == 0 then
      slot.minas = minas == true and link[_minas] or math.floor(minas or link[_minas])
      slot.maxas = math.max(slot.minas, maxas == true and link[_maxas] or math.floor(maxas or link[_maxas]))

      slot.as = math.max(math.min(slot.maxas, link[_as]), slot.minas)
      links.minas = links.minas + slot.as
      links.maxas = math.min(links.maxas + slot.as, maxdim)
    else
      slot.minas = minas == true and link[_minas] or math.floor(minas or 0)
      slot.maxas = math.max(slot.minas, maxas == true and link[_maxas] or math.floor(maxas or maxdim))

      slot.as = slot.minas
      links.minas = links.minas + slot.minas
      links.maxas = math.min(links.maxas + slot.maxas, maxdim)
      links.flex = links.flex + slot.flex
    end

    if self[_flux] == 0 then
      reconcile(self)
    end

    return self:refresh()
  end

  function metatable:setslotface(indexorlink, face)
    local link = type(indexorlink) == 'number' and self:get(indexorlink) or indexorlink
    local slot = link[_slot]
    --assert(slot)

    if face and not M.isface(face) then
      face = getface('cel', face)
    end

    slot.face = face or false

    link:refresh()

    return self
  end

  --TODO its probably faster to drop the old _links, but formation:unlink calls out to metacel
  --with the index that was unlinked
  function metatable:clear() 
    event:wait()
    local links = self[_links] 

    self:flux(function()
      while links.n > 0 do
        links[links.n]:unlink()
      end
    end)
    event:signal()
  end

  do --metatable.ilinks
    local function it(seq, i)
      i = i + 1
      local link = seq[_links][i]
      if link then
        return i, link
      end
    end

    function metatable:ilinks()
      return it, self, 0
    end
  end

  function metatable:len()
    return self[_links].n
  end

  function metatable:get(index)
    return self[_links][index]
  end

  --TODO pcall, with errorhandler function, driver must provide an error handler
  function metatable:flux(callback, ...)
    self[_flux] = self[_flux] + 1
    if callback then
      callback(...)
    end
    self[_flux] = self[_flux] - 1
    if self[_flux] == 0 then
      reconcile(self)
    end
    return self
  end

  function metatable:first()
    return self[_links][1]
  end

  function metatable:last()
    return self[_links][self[_links].n]
  end

  --TODO define so that nil input returns the first link
  function metatable:next(item)
    if item[_host] ~= self then return nil end

    local index = indexof(self, item)

    return self[_links][1 + index]
  end

  --TODO define so that nil input returns the last link
  function metatable:prev(item)
    if item[_host] ~= self then return nil end

    local index = indexof(self, item)

    return self[_links][-1 + index]
  end

  function metatable:insert(index, item, linker, xval, yval, option)
    index = index or -1

    self[_flux] = self[_flux] + 1

    if rawget(item, _host) == self then
      item:relink(linker, xval, yval, option)
      local links = self[_links]
      local n = links.n

      if index < -1 then
        index = math.max(1, n + index+1)
      elseif index > n or index <= 0 then
        index = n
      end

      local currentindex = indexof(self, item) 
      if index ~= currentindex then
        table.remove(links, currentindex)
        table.insert(links, index, item)
        self:refresh() --TODO may not have to refresh here, when refresh logic is working correctly
      end
    else
      item:link(self, linker, xval, yval, option)
      local links = self[_links]
      local n = links.n

      if index < -1 then
        index = math.max(1, n + index+1)
      elseif index > n or index <= 0 then
        index = n
      end

      if index ~= n then
        links[n] = nil
        table.insert(links, index, item)
      end
    end

    self[_flux] = self[_flux] - 1
    if self[_flux] == 0 then
      reconcile(self)
    end
    return self
  end

  --TODO if seq is stable, should not have to do indexof in unlink
  function metatable:remove(index)
    local item = self[_links][index]

    if item then
      item:unlink()
    end
    return self
  end

  --TODO make work, TODO make not possible infinite loop
  function metatable:indexof(item)
    if item[_host] == self then 
      return indexof(self, item)
    end
  end

  --returns item, index
  function metatable:pick(x, y)
    return formation:pick(self, x, y)
  end

  function metatable:sort(comp)
    self[_flux] = self[_flux] + 1
    table.sort(self[_links], comp)
    self[_flux] = self[_flux] - 1
    if self[_flux] == 0 then
      reconcile(self)
    end
    self:refresh() --TODO why is this here??
    return self
  end


  --TODO does not quite work
  function metacel:onmousemove(seq, x, y)
    local vx, vy = mouse:vector()
    local a = seq:pick(x, y)
    local b = seq:pick(x - vx, y - vy)
    if a ~= b then
      seq:refresh()
    end
  end

  do --metacel.new, metacel.assemble
    --TODO don't accept defaultslotface in new
    local _new = metacel.new
    local slotface = getface('cel')
    function metacel:new(gap, face, defaultslotface)
      face = self:getface(face)
      local seq = _new(self, 0, 0, face)
      seq[_flux] = 0
      seq[_links] = {
        brace = false,
        minas = 0, --minh
        maxas = 0, --maxh
        minbs = 0, --minw
        flex = 0,
        as = 0, 
        bs = 0,  --w
        n = 0,
      }

      seq[_gap] = gap or 0
      seq[_maxas] = 0    
      seq[_slotface] = getface('cel', defaultslotface) or slotface
      seq[_formation] = formation

      if seq.id == 150 or seq.id == 696 then seq.__debug = true end
      return seq
    end

    local _assemble = metacel.assemble
    function metacel:assemble(t, seq)
      seq = seq or metacel:new(t.gap, t.face, t.slotface)
      seq.__debug = t.__debug
      seq[_flux] = 1
      seq.onchange = t.onchange
      _assemble(self, t, seq)
      seq[_flux] = 0 
      reconcile(seq)
      if seq.id == 150 or seq.id == 696 then seq.__debug = true end
      return seq
    end

    function metacel:assembleentry(seq, entry, entrytype, linker, xval, yval, option)
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
          local link = M.tocel(entry[i], seq)
          if link then
            link._ = entry._ or link._ --TODO document what _ is for
            link:link(seq, linker, xval, yval, option or entry)
          end
        end 
      end
    end
  end

  if _seq_ == 'col' then
    M[_seq_] = metacel:newfactory({
      iscol = function(cel)
        return rawget(cel, _formation) == formation
      end
    })
  else
    M[_seq_] = metacel:newfactory({
      isrow = function(cel)
        return rawget(cel, _formation) == formation
      end
    })
  end
end --end main loop















