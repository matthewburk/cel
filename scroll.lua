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
--returns the current value of the scrollbar
--min value is 0 max value is scrollbar.max

--returns the h of a hypothetical cel that would be moved relative to the scrollbar for a y scrollbar
--returns the w of a hypothetical cel that would be moved relative to the scrollbar for a x scrollbar
--the idea is that when a scrollbar is at its maximum value the bottom of the hypothetical cel would align
--with the bottom of the scrollbar and at its minimum value the top of the hypothetical cel would align
--with the top of the scrollbar (in terms of a y scrollbar)
--returns the maximum allowed value for the scrollbar
--is equal to scrollbar.range - scrollbar.size
--the size of the scrollbar, 
--is equal to scrollbar.h for y scrollbars and srollbar.w for x scrollbar
----TODO this thing is too messy, unwanted recursion happens too easily
local cel = require 'cel'

--local --print = function() end
local metacel, metatable = cel.newmetacel('scroll')
metacel['.portal'] = cel.newmetacel('scroll.portal')
metacel['.bar'] = cel.newmetacel('scroll.bar')

do
  local metacel = metacel['.bar']
  metacel['.track'] = cel.button.newmetacel('scroll.bar.track')
  metacel['.inc'] = cel.button.newmetacel('scroll.bar.inc')
  metacel['.dec'] = cel.button.newmetacel('scroll.bar.dec')
  metacel['.thumb'] = cel.grip.newmetacel('scroll.bar.thumb')
end

local _scroll = {}
local _scrollbar = {}
local _track = {}
local _thumb = {}
local _portal = {}
local _slot = {}
local _xdim = {}
local _ydim = {}
local _xbar = {}
local _ybar = {}
local _insync = {}
local _updateflow = {}
local _borders = {}

local layout
do
  local size = 28 --width for y, height for x
  layout = {
    stepsize = 20,
    ybar = {
      --show can be true, false, or nil, nil is auto
      --show = true, 
      align = 'left',
      size = size, 
      track = {
        size = size,
        link = {'fill.margin', 0, size},
        thumb = {
          --TODO allow link, but constrain it so it acts like a thumb
          minsize = 10,
          size = size,
        };
      },
      decbutton = {
        size = size,
        link = 'width.top',
      },
      incbutton = {
        size = size,
        link = 'width.bottom',
      },
    },
    xbar = {
      --show = false,
      align = 'bottom',
      size = size,
      track = {
        size = size,
        link = {'fill.margin', size, 0},
        thumb = {
          minsize = 10,
          size = size,
        },
      },
      decbutton = {
        size = size,
        link = {'left.height'},
      },
      incbutton = {
        size = size,
        link = {'right.height'},
      },
    },
  }
  
end

local linkers = {}

local sync = {}


local function matches(v, a, b)
  return (v == a or (b == nil or v == b))
end

local flowybar = {}
local flowxbar = {}

do
  function flowybar.showbar(ybar, p)
    local scroll = ybar[_scroll]
    local portal = scroll[_portal]
    local xbar = scroll[_xbar]

    ybar:relink(ybar.linker, p, xbar)

    if ybar.align == 'left' then
      ybar.lgap = ybar.r
      ybar.rgap = 0
    else 
      ybar.lgap = 0
      ybar.rgap = scroll.w - ybar.l
    end

    xbar:relink(xbar.linker, xbar.xval, ybar)

    do
      local gaps = portal.gaps
      gaps.l = gaps.fixedl + ybar.lgap
      gaps.r = gaps.fixedr + ybar.rgap 
      portal:relink(portal.linker, gaps)
    end
  end

  function flowxbar.showbar(xbar, p)
    --TODO clamp p 0 to 1
    local scroll = xbar[_scroll]
    local portal = scroll[_portal]
    local ybar = scroll[_ybar]

    --TODO why am i moving subject here, but not for flowybar.showbar?
    --this pins it to the bottom if its alreayd on the bottom, is that always
    --the correct thing to do?  I think it is
    local movesubject = scroll[_slot] and scroll[_slot].b == portal.h

    xbar:relink(xbar.linker, p, ybar)

    if xbar.align == 'top' then
      xbar.tgap = xbar.b
      xbar.bgap = 0
    else 
      xbar.tgap = 0
      xbar.bgap = scroll.h - xbar.t
    end

    ybar:relink(ybar.linker, ybar.xval, xbar)

    do
      local gaps = portal.gaps
      gaps.t = gaps.fixedt + xbar.tgap
      gaps.b = gaps.fixedb + xbar.bgap 
      portal:relink(portal.linker, gaps)
    end

    if movesubject then
      scroll[_slot]:moveby(nil, -math.huge)
    else
      --print('not moving for xbar', scroll[_slot].b, portal.h)
    end
  end

  function flowybar.hidebar(ybar, p)
    local scroll = ybar[_scroll]
    local portal = scroll[_portal]
    local xbar = scroll[_xbar]

    ybar:relink(ybar.linker, p, xbar)

    if ybar.align == 'left' then
      ybar.lgap = ybar.r
      ybar.rgap = 0
    else 
      ybar.lgap = 0
      ybar.rgap = scroll.w - ybar.l
    end

    xbar:relink(xbar.linker, xbar.xval, ybar)

    --portal:relink is not flowed and immediately snaps to place
  end

  function flowxbar.hidebar(xbar, p)
    --TODO clamp p 0 to 1
    local scroll = xbar[_scroll]
    local portal = scroll[_portal]
    local ybar = scroll[_ybar]

    xbar:relink(xbar.linker, p, ybar)

    if xbar.align == 'top' then
      xbar.tgap = xbar.b
      xbar.bgap = 0
    else 
      xbar.tgap = 0
      xbar.bgap = scroll.h - xbar.t
    end

    ybar:relink(ybar.linker, ybar.xval, xbar)

    --portal:relink is not flowed and immediately snaps to place
  end

  local function syncportal(scroll)
    local portal = scroll[_portal]
    local xbar = scroll[_xbar]
    local ybar = scroll[_ybar]
    local xbarnewmode
    local ybarnewmode

    if xbar.autohide == 'unhide' then
      --print('showing xbar')
      xbar.autohide = 'show'
      xbarnewmode = 'showbar'
    elseif xbar.autohide == 'unshow' then
      --print('hiding xbar')
      xbar.autohide = 'hide'
      xbarnewmode = 'hidebar'
    end

    if ybar.autohide == 'unhide' then
      --print('showing ybar')
      ybar.autohide = 'show'
      ybarnewmode = 'showbar'
    elseif ybar.autohide == 'unshow' then
      --print('hiding ybar', debug.traceback())
      ybar.autohide = 'hide'
      ybarnewmode = 'hidebar'
    end

    if xbarnewmode or ybarnewmode then      
      --print('mode', xbarnewmode, 'x', xbar.autohide)
      if xbarnewmode == 'showbar' then
        xbar:endflow()
        xbar:flowvalue(scroll:getflow('showxbar'), 0, 1, flowxbar[xbarnewmode])
      elseif xbarnewmode == 'hidebar' then
        xbar:endflow()
        xbar:flowvalue(scroll:getflow('hidexbar'), 1, 0, flowxbar[xbarnewmode])

        do
          local gaps = portal.gaps
          gaps.t = gaps.fixedt
          gaps.b = gaps.fixedb 
          portal:relink(portal.linker, gaps)
        end
      end
      --print('mode', ybarnewmode, 'y', ybar.autohide)
      if ybarnewmode == 'showbar' then
        ybar:endflow()
        ybar:flowvalue(scroll:getflow('showybar'), 0, 1, flowybar[ybarnewmode])
      elseif ybarnewmode == 'hidebar' then
        ybar:endflow()
        ybar:flowvalue(scroll:getflow('hideybar'), 1, 0, flowybar[ybarnewmode])
        do
          local gaps = portal.gaps
          gaps.l = gaps.fixedl
          gaps.r = gaps.fixedr 
          portal:relink(portal.linker, gaps)
        end
      end

      if not ybarnewmode then ybar:relink(ybar.linker, ybar.xval, xbar) end
      if not xbarnewmode then xbar:relink(xbar.linker, xbar.xval, ybar) end
    end
  end

  --sync value, portal, modelvalue and modelsize
  function sync.scroll(scroll)
    if scroll[_insync] == nil or scroll[_insync] == false then
      scroll[_insync] = 'syncing' 

      --has to be synced before value becuase of subject linker
      --doing it twice on purpose because subject could resize due to portal resize
      syncportal(scroll)
      syncportal(scroll)

      if scroll[_slot] then
        scroll[_slot]:move(-scroll[_xdim].value, -scroll[_ydim].value)
      end

      sync.model(scroll)
      
      scroll[_insync] = true 
    end
    return scroll
  end

end


do
  local function updatemodel(bar, range, value, max, size)
    local modelrange = bar.modelrange
    local minmodelsize = bar.minmodelsize
    local modelsize 
    local modelmax 
    local modelvalue  

    if range > 0 and range > size then
      if modelrange > minmodelsize then
        modelsize = math.max(math.floor(.5 + (modelrange * size / range)), minmodelsize)
      else
        modelsize = 0
      end

      modelmax = modelrange - modelsize; assert(modelmax >= 0)
      modelvalue = math.floor(modelmax * (value/max) + 0.5)
    else  --disable scrollbar
      modelsize = 0 
      modelmax = 0
      modelvalue = 0
    end

    bar.modelmax = modelmax
    return modelsize, modelvalue
  end

  function sync.model(scroll)
    local xbar = scroll[_xbar]
    if xbar then
      local dim = scroll[_xdim]
      local modelsize, modelvalue = updatemodel(xbar, dim.range, dim.value, dim.max, dim.size)
      xbar[_thumb]:move(modelvalue, nil, modelsize, nil)

      if dim.size >= dim.range then
        xbar:disable() --TODO not enough, make sure we don't try to scroll without a subject
      else
        xbar:enable()
      end
    end

    local ybar = scroll[_ybar]
    if ybar then
      local dim = scroll[_ydim]
      local modelsize, modelvalue = updatemodel(ybar, dim.range, dim.value, dim.max, dim.size)
      ybar[_thumb]:move(nil, modelvalue, nil, modelsize)

      if dim.size >= dim.range then
        ybar:disable() 
      else
        ybar:enable()
      end
    end
    return scroll
  end
end

local function __updatevalue(scroll, dim, value)
  assert(scroll)
  assert(dim)
  assert(value)
  value = math.max(value, 0)
  value = math.min(value, dim.max)
  if dim.value ~= value then
    dim.value = value
    scroll[_insync] = false 
  end
end

local function trackpressed(button)
end

--mode is line or page
local function scrollstep(scroll, xsteps, ysteps, mode)
  scroll[_slot]:endflow(scroll:getflow('scroll'))  

  local subject = scroll:getsubject()

  if not subject then
    return scroll
  end

  if scroll.step then
    return scroll:step(xsteps, ysteps, mode)
  elseif cel.col.iscol(subject) then
    local x, y = scroll:getvalues()
    if ysteps and ysteps ~= 0 then
      local item = subject:pick(0, y)

      if item then
        if ysteps > 0 then
          item = subject:next(item)
        else 
          if y <= item.y then --to keep step to the top of a cel if we are in the middle of it
            item = subject:prev(item)
          end
        end
      end

      if item then
        y = item.y
      elseif ysteps > 0 then
        y = subject.h
      else
        y = 0
      end
    else
      y = nil
    end

    if xsteps then
      x = x + (xsteps * scroll.stepsize)
    else
      x = nil
    end

    return scroll:scrollto(x, y)
  else
    local xdim = scroll[_xdim]
    local ydim = scroll[_ydim]
    local x, y = xdim.value, ydim.value

    if mode == nil or mode == 'line' then
      if xsteps and xsteps ~= 0 then x = x + (xsteps * scroll.stepsize) end
      if ysteps and ysteps ~= 0 then y = y + (ysteps * scroll.stepsize) end
    elseif mode == 'page' then
      if xsteps and xsteps ~= 0 then x = x + (xsteps * xdim.size) end
      if ysteps and ysteps ~= 0 then y = y + (ysteps * ydim.size) end
    end

    return scroll:scrollto(x, y)
  end
end

local function incpressed(button)
  local scrollbar = button[_scrollbar]
  local scroll = scrollbar[_scroll]
  if scrollbar.axis == 'y' then
    scrollstep(scroll, nil, 1)
  else
    scrollstep(scroll, 1, nil)
  end
end

local function decpressed(button)
  local scrollbar = button[_scrollbar]
  local scroll = scrollbar[_scroll]
  if scrollbar.axis == 'y' then
    scrollstep(scroll, nil, -1)
  else
    scrollstep(scroll, -1, nil)
  end
end

local function thumbdragged(thumb, dx, dy)
  local scrollbar = thumb[_scrollbar]
  local scroll = scrollbar[_scroll]
  local modelvalue
  local dim
  local value = 0

  if scrollbar.axis == 'y' then
    dim = scroll[_ydim]
    modelvalue = thumb.y + dy
    if scrollbar.modelmax > 0 then
      value = math.floor(dim.max * (modelvalue/scrollbar.modelmax) + .5)
    end
  else
    dim = scroll[_xdim]
    modelvalue = thumb.x + dx
    if scrollbar.modelmax > 0 then
      value = math.floor(dim.max * (modelvalue/scrollbar.modelmax) + .5)
    end
  end
 

  __updatevalue(scroll, dim, value)
  sync.scroll(scroll)
end

do --track
  local metatrack = metacel['.bar']['.track']

  function metatrack:__resize(track)
    local scrollbar = track[_scrollbar]
    if scrollbar.axis == 'y' then
      scrollbar.modelrange = track.h
    else
      scrollbar.modelrange = track.w
    end  
  end

  function metatrack:onresize(track)
    sync.model(track[_scrollbar][_scroll])
  end
end

do --portal
  local metaportal = metacel['.portal']

  metaportal.__relink = false --don't allow subject to relink, must link how scroll makes it

  local function __updatesize(scroll, portal, dim, size)
    if size < 0 then size = 0 end 
    if dim.size ~= size then
      local range = dim.range
      local max = math.max(range - size, 0)
      local value = math.min(dim.value, max)
      dim.max = max
      dim.value = value
      dim.size = size
      scroll[_insync] = false 
      --print('updated size for', dim == scroll[_xdim] and 'x' or 'y', size)
    end
  end

  local function __checkbars(scroll, portal)
    local xdim = scroll[_xdim]
    local ydim = scroll[_ydim]
    local xbar = scroll[_xbar]
    local ybar = scroll[_ybar]
    local xbarautohidein = xbar and xbar.autohide 
    local ybarautohidein = ybar and ybar.autohide 
    local xautohide
    local yautohide

    if xbar then
      local bar = xbar
      local autohide = bar.autohide
      if xdim.size >= xdim.range then
        if autohide == 'show' then 
          autohide = 'unshow'
        elseif autohide == 'unhide' then
          autohide = 'hide'
        end
      elseif xdim.size < xdim.range then
        if autohide == 'hide' then
          autohide = 'unhide'
        elseif autohide == 'unshow' then
          autohide = 'show'
        end
      end

      xautohide = autohide
    end

    if ybar then
      local bar = ybar
      local autohide = bar.autohide
      if ydim.size >= ydim.range then
        if 'show' == autohide then
          autohide = 'unshow'
        elseif 'unhide' == autohide then
          autohide = 'hide'
        end
      elseif ydim.size < ydim.range then
        if 'hide' == autohide then
          autohide = 'unhide'
        elseif 'unshow' == autohide then
          autohide = 'show'
        end
      end

      yautohide = autohide
    end

    if xbar and ybar then
      local gaps = scroll[_portal].gaps
      if scroll.h-(gaps.fixedt + gaps.fixedb) >= ydim.range and scroll.w - (gaps.fixedl + gaps.fixedr) >= xdim.range then
        if 'show' == ybar.autohide then
          yautohide = 'unshow'
        elseif 'unhide' == ybar.autohide then
          yautohide = 'hide'
        end
        if 'show' == xbar.autohide then
          xautohide = 'unshow'
        elseif 'unhide' == xbar.autohide then
          xautohide = 'hide'
        end
      end
    end

    xbar.autohide = xautohide
    ybar.autohide = yautohide

    if (xbar and (xbar.autohide ~= xbarautohidein)) or (ybar and (ybar.autohide ~= ybarautohidein)) then
      scroll[_insync] = false
    end
  end

  function metaportal:__resize(portal, ow, oh)
    local scroll = portal[_scroll]
    if portal.w ~= ow then 
      __updatesize(scroll, portal, scroll[_xdim], portal.w)
    end
    if portal.h ~= oh then
      __updatesize(scroll, portal, scroll[_ydim], portal.h)
    end
    __checkbars(scroll, portal)
  end

  function metaportal:onresize(portal)
    sync.scroll(portal[_scroll])
  end

  --returns true if range changed
  local function __updaterange(scroll, dim, range)
    assert(scroll)
    assert(dim)
    assert(range)
    if range < 0 then range = 0 end
    if dim.range ~= range then
      local size = dim.size
      local max = math.max(range - size, 0)
      local value = math.min(dim.value, max)
      dim.range = range
      dim.max = max
      dim.value = value
      scroll[_insync] = false 
      return true
    end
    return false
  end

  function metaportal:__link(portal, link, linker, xval, yval, option)
    if 'subjectslot' == option then
      local scroll = portal[_scroll]
      __updaterange(scroll, scroll[_xdim], link.w)
      __updaterange(scroll, scroll[_ydim], link.h)
      __checkbars(scroll, portal)

    end
  end

  metaportal.metatable.__tostring = nil
  function metaportal:onlink(portal, link)
    local scroll = portal[_scroll]
    if scroll[_slot] == link then
      sync.scroll(portal[_scroll])
      for name, border in pairs(scroll[_borders]) do
        if border.subject then
          if name == 'top' or name == 'bottom' then
            border.subject:move(link.x, 0, link.w) 
          else
            border.subject:move(0, link.y, nil, link.h) 
          end
        end
      end
    end
  end

  function metaportal:__unlink(portal, link)
    local scroll = portal[_scroll]
    if scroll[_slot] == link then
      scroll[_slot] = nil
      __updaterange(scroll, scroll[_xdim], 0)
      __updaterange(scroll, scroll[_ydim], 0)
      __checkbars(scroll, portal)
      sync.scroll(scroll)

    end
  end

  function metaportal:__linkmove(portal, link, ox, oy, ow, oh)
    local scroll = portal[_scroll]
   
    if scroll[_slot] == link then
      if scroll[_insync] ~= 'syncing' then
        local checkbars = false 
        if ox ~= link.x then __updatevalue(scroll, scroll[_xdim], -link.x) end
        if oy ~= link.y then __updatevalue(scroll, scroll[_ydim], -link.y) end
        if ow ~= link.w then checkbars = __updaterange(scroll, scroll[_xdim], link.w) or checkbars end
        if oh ~= link.h then checkbars = __updaterange(scroll, scroll[_ydim], link.h) or checkbars end
        if checkbars then __checkbars(scroll, portal) end
      elseif scroll[_insync] == 'syncing' then 
        local checkbars = false 
        if ow ~= link.w then checkbars = __updaterange(scroll, scroll[_xdim], link.w) or checkbars end
        if oh ~= link.h then checkbars = __updaterange(scroll, scroll[_ydim], link.h) or checkbars end
        if checkbars then __checkbars(scroll, portal) end
      end
    end
  end

  function metaportal:onlinkmove(portal, link)
    local scroll = portal[_scroll]
    if scroll[_slot] == link then
      sync.scroll(portal[_scroll])
      for name, border in pairs(scroll[_borders]) do
        if border.subject then
          if name == 'top' or name == 'bottom' then
            border.subject:move(link.x, 0, link.w) 
          else
            border.subject:move(0, link.y, nil, link.h) 
          end
        end
      end
    end
  end
end

do
  local metabar =  metacel['.bar']
  local _new = metacel.new

  function metabar:__describe(scrollbar, t)
    t.axis = scrollbar.axis
    t.size = scrollbar.size
  end

  function metabar:new(scroll, axis, layout, face)
    assert(scroll)
    assert(axis)
    assert(layout)
    face = self:getface(face)

    local scrollbar = _new(self, layout.size, layout.size, face)
    scrollbar[_scroll] = scroll
    scrollbar.axis = axis
    scrollbar.size = layout.size
    scrollbar.autohide = layout.show == nil and 'hide' or false 
    scrollbar.modelrange = 0
    scrollbar.modelmax = 0
    scrollbar.minmodelsize = layout.track.thumb.minsize or 1

    do
      local layout = layout.track
      scrollbar[_track] = self['.track']:new(layout.size, layout.size, layout.face)
      scrollbar[_track][_scrollbar] = scrollbar
      scrollbar[_track].onpress = trackpressed
      scrollbar[_track].onhold = trackpressed
      do
        local layout = layout.thumb
        scrollbar[_thumb] = self['.thumb']:new(layout.size, layout.size, layout.face)
        scrollbar[_thumb][_scrollbar] = scrollbar
        scrollbar[_thumb].ondrag = thumbdragged
      end
    end

    if layout.incbutton then 
      local layout = layout.incbutton
      local button = self['.inc']:new(layout.size, layout.size, layout.face)
      button[_scrollbar] = scrollbar
      button.onpress = incpressed
      button.onhold = incpressed
      button:link(scrollbar, layout.link)
    end

    if layout.decbutton then
      local layout = layout.decbutton
      local button = self['.dec']:new(layout.size, layout.size, layout.face)
      button[_scrollbar] = scrollbar
      button.onpress = decpressed
      button.onhold = decpressed
      button:link(scrollbar, layout.link)
    end

    scrollbar[_track]:link(scrollbar, layout.track.link)
    scrollbar[_thumb]:link(scrollbar[_track], nil, nil, 'fence')
    return scrollbar
  end
end

function metatable:settopborder(bordercel, linker, xval, yval, option)
  local h = bordercel.h
  local border = self[_borders].top
  local portal = self[_portal]

  local gaps = portal.gaps

  gaps.t = gaps.t - gaps.fixedt
  gaps.fixedt = h
  gaps.t = gaps.t + h

  if not border then
    border = cel.new(portal.w, h):link(self, linkers.border.top, gaps, nil, 'raw'):sink() 
    self[_borders].top = border
  else
    border:resize(portal.w, h)
  end

  local target 
  if option == 'subject' then
    border.subject = border.subject or cel.new(0, h):link(border, 'height')
    target = border.subject

    if self[_slot] then 
      border.subject:move(self[_slot].x, 0, self[_slot].w)
    end
  else
    if border.subject then
      border.subject:unlink()
      border.subject = nil
    end
    target = border
  end

  portal:relink(portal.linker, portal.xval)
  bordercel:link(target, linker, xval, yval)
  return self
end

function metatable:setleftborder(bordercel, linker, xval, yval, option)
  local w = bordercel.w
  local border = self[_borders].left
  local portal = self[_portal]

  local gaps = portal.gaps

  gaps.l = gaps.l - gaps.fixedl
  gaps.fixedl = w
  gaps.l = gaps.l + w

  if not border then
    border = cel.new(w, portal.h):link(self, linkers.border.left, gaps, nil, 'raw'):sink() 
    self[_borders].left = border
  else
    border:resize(w, portal.h)
  end

  local target 
  if option == 'subject' then
    border.subject = border.subject or cel.new(w, 0):link(border, 'width')
    target = border.subject

    if self[_slot] then 
      border.subject:move(0, self[_slot].y, nil, self[_slot].h)
    end
  else
    if border.subject then
      border.subject:unlink()
      border.subject = nil
    end
    target = border
  end

  portal:relink(portal.linker, portal.xval)
  bordercel:link(target, linker, xval, yval)
  return self
end

function metatable:setbottomborder(bordercel, linker, xval, yval, option)
  local h = bordercel.h
  local border = self[_borders].bottom
  local portal = self[_portal]

  local gaps = portal.gaps

  gaps.b = gaps.b - gaps.fixedb
  gaps.fixedb = h
  gaps.b = gaps.b + h

  if not border then
    border = cel.new(portal.w, h):link(self, linkers.border.bottom, gaps, nil, 'raw'):sink() 
    self[_borders].bottom = border
  else
    border:resize(portal.w, h)
  end

  local target 
  if option == 'subject' then
    border.subject = border.subject or cel.new(0, h):link(border, 'height')
    target = border.subject

    if self[_slot] then 
      border.subject:move(self[_slot].x, 0, self[_slot].w)
    end
  else
    if border.subject then
      border.subject:unlink()
      border.subject = nil
    end
    target = border
  end

  portal:relink(portal.linker, portal.xval)
  bordercel:link(target, linker, xval, yval)
  return self
end

function metatable:setrightborder(bordercel, linker, xval, yval, option)
  local w = bordercel.w
  local border = self[_borders].right
  local portal = self[_portal]

  local gaps = portal.gaps

  gaps.r = gaps.r - gaps.fixedr
  gaps.fixedr = w
  gaps.r = gaps.r + w

  if not border then
    border = cel.new(w, portal.h):link(self, linkers.border.right, gaps, nil, 'raw'):sink() 
    self[_borders].right = border
  else
    border:resize(w, portal.h)
  end

  local target 
  if option == 'subject' then
    border.subject = border.subject or cel.new(w, 0):link(border, 'width')
    target = border.subject

    if self[_slot] then 
      border.subject:move(0, self[_slot].y, nil, self[_slot].h)
    end
  else
    if border.subject then
      border.subject:unlink()
      border.subject = nil
    end
    target = border
  end

  portal:relink(portal.linker, portal.xval)
  bordercel:link(target, linker, xval, yval)
  return self
end

do
  local function updateflow(scroll, subject, x, y)
    __updatevalue(scroll, scroll[_xdim], -x)
    __updatevalue(scroll, scroll[_ydim], -y)
    sync.scroll(scroll)
  end

  function metatable.scrollto(scroll, x, y)
    sync.scroll(scroll)
    if scroll[_slot] then
      local xdim, ydim = scroll[_xdim], scroll[_ydim]
      x = x or xdim.value
      y = y or ydim.value
      if x < 0 then x = 0 end
      if y < 0 then y = 0 end
      if x > xdim.max then x = xdim.max end
      if y > ydim.max then y = ydim.max end
      if not scroll[_updateflow] then
        scroll[_updateflow] = function(...) return updateflow(scroll, ...) end
      end

      scroll[_slot]:endflow(scroll:getflow('scroll'))      
      scroll[_slot]:flow(scroll:getflow('scroll'), -x, -y, nil, nil, scroll[_updateflow])
    end
    return scroll
  end

  function metatable:scrolltocel(acel, align)
    if not acel or not self[_slot] then
      return self
    end

    local ix, iy = cel.translate(acel, 0, 0, self[_slot])

    if not ix then
      return self
    end

    local x, y, w, h = self:getportalrect()
    x, y = self:getvalues()

    if align == 'top' then
      self:scrollto(nil, iy)
    else
      if y + h < iy + acel.h then
        self:scrollto(nil, iy + acel.h - h)
      elseif iy < y then
        self:scrollto(nil, iy)
      end
    end
    return self
  end

  function metatable:jumptocel(acel)
    self:scrolltocel(acel)
    self[_slot]:endflow(self:getflow('scroll')) 
  end
end

function metatable.getvalues(scroll)
  return scroll[_xdim].value, scroll[_ydim].value 
end

function metatable.getmaxvalues(scroll)
  return scroll[_xdim].max, scroll[_ydim].max 
end

function metatable.setsubject(scroll, subject, linker, xval, yval)
  assert(scroll)
  assert(subject)
  assert(scroll[_portal])

  local current = scroll[_slot]:getsubject()

  if current then
    current:unlink()
  end

  subject:link(scroll[_slot], linker, xval, yval, 'slot') 
  return scroll
end

--THIS makes scroll a container, its item is getable and setable
function metatable.getsubject(scroll)
  return scroll[_slot]:getsubject()
end

function metatable.getportalrect(scroll)
  return scroll[_portal]:pget('x', 'y', 'w', 'h')
end

function metacel:__link(scroll, link, linker, xval, yval, option)
  if scroll[_slot] and not option then
    return scroll[_slot], linker, xval, yval, option 
  elseif option == 'portal' then
    return scroll[_portal], linker, xval, yval
  elseif option == 'ybar' then
    return scroll[_ybar], linker, xval, yval
  elseif option == 'xbar' then
    return scroll[_xbar], linker, xval, yval
  elseif option == 'raw' then
    return scroll, linker, xval, yval
  end
  return scroll[_slot], linker, xval, yval, option
end

function metacel:__relink(scroll, link)
  if link == scroll[_portal] then
    for name, border in pairs(scroll[_borders]) do
      border:relink(border.linker, border.xval)
    end
  end
end

function metacel:onmousewheel(scroll, direction, x, y, intercepted)
  if not intercepted and scroll[_slot] then
    local invalue = scroll[_slot].y
    if cel.mouse.wheel.down == direction then
      scrollstep(scroll, nil, cel.mouse.scrolllines or 1)
    elseif cel.mouse.wheel.up == direction then
      scrollstep(scroll, nil, -(cel.mouse.scrolllines or 1))
    end
    return true
    --does not work with flows
    --return invalue ~= scroll[_slot].y
  end
end

do
  linkers.xbar = {
    bottom = function(hw, hh, x, y, w, h, p, ybar)
      return ybar.lgap, hh - (h * p), hw - (ybar.lgap + ybar.rgap), h
    end,
    top = function(hw, hh, x, y, w, h, p, ybar)
      return ybar.lgap, -(h * (1-p)), hw - (ybar.lgap + ybar.rgap), h
    end,
  }

  linkers.ybar = {
    right = function(hw, hh, x, y, w, h, p, xbar)
      return hw - (w * p), xbar.tgap, w, hh - (xbar.tgap + xbar.bgap)
    end,
    left = function(hw, hh, x, y, w, h, p, xbar)
      return -(w * (1-p)), xbar.tgap, w, hh - (xbar.tgap + xbar.bgap)
    end
  }

  linkers.portal = function(hw, hh, x, y, w, h, gaps)
    return gaps.l, gaps.t, hw - (gaps.l + gaps.r), hh - (gaps.t + gaps.b)
  end

  linkers.border = {
    top = function(hw, hh, x, y, w, h, gaps)
      return gaps.l, gaps.t-gaps.fixedt, hw - (gaps.l + gaps.r), h 
    end,
    bottom = function(hw, hh, x, y, w, h, gaps)
      return gaps.l, hh-gaps.b, hw - (gaps.l + gaps.r), h 
    end,
    left = function(hw, hh, x, y, w, h, gaps)
      return gaps.l-gaps.fixedl, gaps.t, w, hh - (gaps.t + gaps.b) 
    end,
    right = function(hw, hh, x, y, w, h, gaps)
      return hw-gaps.r, gaps.t, w, hh - (gaps.t + gaps.b) 
    end,
  }


  local _new = metacel.new
  function metacel:new(w, h, face)
    face = self:getface(face)
    local layout = face.layout or layout
    local scroll = _new(self, w, h, face)
    scroll.stepsize = layout.stepsize or 1

    scroll[_xdim] = { value = 0, max = 0, size = 0, range = 0, }
    scroll[_ydim] = { value = 0, max = 0, size = 0, range = 0, }
    scroll[_borders] = {}

    scroll[_portal] = self['.portal']:new(w, h)
    scroll[_portal][_scroll] = scroll
    scroll[_portal].gaps = {
      l=0, r=0, t=0, b=0,
      fixedl = 0,
      fixedr = 0,
      fixedt = 0,
      fixedb = 0,
    }

    scroll[_portal]:link(scroll, linkers.portal, scroll[_portal].gaps, nil, 'raw')

    do
      local xbar = self['.bar']:new(scroll, 'x', layout.xbar, layout.xbar.face)
      xbar.align = layout.xbar.align == 'top' and 'top' or 'bottom'
      xbar.tgap = 0
      xbar.bgap = 0
      scroll[_xbar] = xbar
      

      local ybar = self['.bar']:new(scroll, 'y', layout.ybar, layout.ybar.face)
      ybar.align = layout.ybar.align == 'left' and 'left' or 'right'
      ybar.lgap = 0
      ybar.rgap = 0
      scroll[_ybar] = ybar

      xbar:link(scroll, linkers.xbar[xbar.align], 0, ybar, 'raw') 
      ybar:link(scroll, linkers.ybar[ybar.align], 0, xbar, 'raw')

      if layout.xbar.show == true then
        flowxbar.showbar(xbar, 1)
      end
      if layout.ybar.show == true then
        flowybar.showbar(ybar, 1)
      end
    end

    scroll[_slot] = cel.slot.new()
    scroll[_slot]:link(scroll[_portal], 'scroll', true, true, 'subjectslot') 
    return scroll
  end

  local _assemble = metacel.assemble
  function metacel:assemble(t, scroll)
    scroll = scroll or metacel:new(t.w, t.h, t.face)
    if t.stepsize then
      scroll.stepsize = t.stepsize
    end

    if t.step then
      scroll.step = t.step
    end

    return _assemble(self, t, scroll)
  end

  local _newmetacel = metacel.newmetacel
  function metacel:newmetacel(name)
    local newmetacel, metatable = _newmetacel(self, name) 
    return newmetacel, metatable
  end
end

return metacel:newfactory({layout = layout})
