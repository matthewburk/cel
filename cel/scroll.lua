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
----TODO this thing is fucked, too messy, unwanted recursion happens too easily
local cel = require 'cel'

--local print = function() end
local metacel, metatable = cel.newmetacel('scroll')
metacel['.portal'] = cel.newmetacel('scroll.portal')
metacel['.bar'] = cel.newmetacel('scroll.bar')

do
  local metacel = metacel['.bar']
  metacel['.track'] = cel.button.newmetacel('scroll.bar.track')
  metacel['.inc'] = cel.button.newmetacel('scroll.bar.inc')
  metacel['.dec'] = cel.button.newmetacel('scroll.bar.dec')
  metacel['.slider'] = cel.grip.newmetacel('scroll.bar.slider')
end

local _scroll = {}
local _scrollbar = {}
local _track = {}
local _slider = {}
local _portal = {}
local _subject = {}
local _xdim = {}
local _ydim = {}
local _xbar = {}
local _ybar = {}
local _insync = {}
local _updateflow = {}

local layout
do
  local size = 18 --width for y, height for x
  layout = {
    stepsize = 20,
    ybar = {
      autohide = true, --TODO doesn't work when false on both bars
      size = size, 
      track = {
        size = size,
        link = {'edges', nil, size},
        slider = {
          --TODO allow link, but constrain it so it acts like a slider
          minsize = 10,
          size = size,
        };
      },
      decbutton = {
        size = size,
        link = {'width.top'},
      },
      incbutton = {
        size = size,
        link = {'width.bottom'},
      },
    },
    xbar = {
      autohide = true,
      size = size,
      track = {
        size = size,
        link = {'edges', size, nil},
        slider = {
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

function linkers.subject(hw, hh, x, y, w, h, fillx, filly)
  if x >= 0 or w <= hw then 
    x = 0
  elseif x + w < hw then
    x = hw - w
  end

  if y >= 0 or h <= hh then
    y = 0
  elseif y + h < hh then
    y = hh - h
  end

  return x, y, fillx and hw or w, filly and hh or h
end

function linkers.portal(hw, hh, x, y, w, h, xval, yval)
  xval = xval or 0
  yval = yval or 0
  return 0, 0, hw - xval, hh - yval
end

function linkers.ybar(hw, hh, x, y, w, h, p, bargap)
  return hw - (w * p), 0, w, hh - bargap
end

function linkers.xbar(hw, hh, x, y, w, h, p, bargap)
  return 0, hh - (h * p), hw - bargap, h
end

local sync = {}

local synccount = 0
local avoidsynccount = 0

local function matches(v, a, b)
  return (v == a or (b == nil or v == b))
end

do
  local flowybar = {}
  local flowxbar = {}

  function flowybar.showbar(ybar, p)
    local scroll = ybar[_scroll]
    local portal = scroll[_portal]
    local xbar = scroll[_xbar]

    if xbar then
      ybar:relink(linkers.ybar, p, scroll.h - xbar.t)
      xbar:relink(linkers.xbar, xbar.xval, scroll.w - ybar.l)
    else
      ybar:relink(linkers.ybar, p, 0)
    end

    portal:relink(linkers.portal, scroll.w - ybar.l, portal.yval)
  end

  function flowxbar.showbar(xbar, p)
    --TODO clamp p 0 to 1
    local scroll = xbar[_scroll]
    local portal = scroll[_portal]
    local ybar = scroll[_ybar]

    local movesubject = scroll[_subject].b == portal.h

    if ybar then
      xbar:relink(linkers.xbar, p, scroll.w - ybar.l)
      ybar:relink(linkers.ybar, ybar.xval, scroll.h - xbar.t)
    else
      xbar:relink(linkers.xbar, p, 0)
    end
    portal:relink(linkers.portal, portal.xval, scroll.h - xbar.t)
    if movesubject then
      scroll[_subject]:moveby(nil, -math.huge)
    else
      --print('not moving for xbar', scroll[_subject].b, portal.h)
    end
  end

  function flowybar.hidebar(ybar, p)
    local scroll = ybar[_scroll]
    local portal = scroll[_portal]
    local xbar = scroll[_xbar]

    if xbar then
      ybar:relink(linkers.ybar, p, scroll.h - xbar.t)
      xbar:relink(linkers.xbar, xbar.xval, scroll.w - ybar.l)
    else
      ybar:relink(linkers.ybar, p, 0)
    end
    --portal:relink(linkers.portal, scroll.w - ybar.l, portal.yval)
  end

  function flowxbar.hidebar(xbar, p)
    --TODO clamp p 0 to 1
    local scroll = xbar[_scroll]
    local portal = scroll[_portal]
    local ybar = scroll[_ybar]
    if ybar then
      xbar:relink(linkers.xbar, p, scroll.w - ybar.l)
      ybar:relink(linkers.ybar, ybar.xval, scroll.h - xbar.t)
    else
      xbar:relink(linkers.xbar, p, 0)
    end
    --portal:relink(linkers.portal, portal.xval, scroll.h - xbar.t)
  end

  local function syncportal(scroll)
    local portal = scroll[_portal]
    local xbar = scroll[_xbar]
    local ybar = scroll[_ybar]
    local xbarnewmode
    local ybarnewmode

    if xbar then
      if xbar.autohide == 'unhide' then
        --print('showing xbar')
        xbar.autohide = 'show'
        xbarnewmode = 'showbar'
      elseif xbar.autohide == 'unshow' then
        --print('hiding xbar')
        xbar.autohide = 'hide'
        xbarnewmode = 'hidebar'
      end
    end

    if ybar then
      if ybar.autohide == 'unhide' then
        --print('showing ybar')
        ybar.autohide = 'show'
        ybarnewmode = 'showbar'
      elseif ybar.autohide == 'unshow' then
        --print('hiding ybar')
        ybar.autohide = 'hide'
        ybarnewmode = 'hidebar'
      end
    end

    if xbarnewmode or ybarnewmode then      
      if xbar then
        --print('mode', xbarnewmode, 'x', xbar.autohide)
        if xbarnewmode == 'showbar' then
          xbar:endflow()
          xbar:flowvalue(scroll:getflow('showxbar'), 0, 1, flowxbar[xbarnewmode])
        elseif xbarnewmode == 'hidebar' then
          xbar:endflow()
          xbar:flowvalue(scroll:getflow('hidexbar'), 1, 0, flowxbar[xbarnewmode])
          portal:relink(linkers.portal, portal.xval, 0)
        end
      end
      if ybar then
        --print('mode', ybarnewmode, 'y', ybar.autohide)
        if ybarnewmode == 'showbar' then
          ybar:endflow()
          ybar:flowvalue(scroll:getflow('showybar'), 0, 1, flowybar[ybarnewmode])
        elseif ybarnewmode == 'hidebar' then
          ybar:endflow()
          ybar:flowvalue(scroll:getflow('hideybar'), 1, 0, flowybar[ybarnewmode])
          portal:relink(linkers.portal, 0, portal.yval)
        end
      end
      if xbar and ybar then
        if not ybarnewmode then ybar:relink(linkers.ybar, ybar.xval, scroll.h - xbar.t) end
        if not xbarnewmode then xbar:relink(linkers.xbar, xbar.xval, scroll.w - ybar.l) end
      end
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

      if scroll[_subject] then
        scroll[_subject]:move(-scroll[_xdim].value, -scroll[_ydim].value)
      end

      sync.model(scroll)
      synccount = synccount + 1
      
      scroll[_insync] = true 
    else
      avoidsynccount = avoidsynccount + 1
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
      xbar[_slider]:move(modelvalue, nil, modelsize, nil)

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
      ybar[_slider]:move(nil, modelvalue, nil, modelsize)

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
    --print('updating value to', value)
    dim.value = value
    scroll[_insync] = false 
  end
end

local function trackpressed(button)
end

local function incpressed(button)
  local scrollbar = button[_scrollbar]
  local scroll = scrollbar[_scroll]
  if scrollbar.axis == 'y' then
    scroll:step(nil, 1)
  else
    scroll:step(1, nil)
  end
end

local function decpressed(button)
  local scrollbar = button[_scrollbar]
  local scroll = scrollbar[_scroll]
  if scrollbar.axis == 'y' then
    scroll:step(nil, -1)
  else
    scroll:step(-1, nil)
  end
end

local function sliderdragged(slider, dx, dy)
  local scrollbar = slider[_scrollbar]
  local scroll = scrollbar[_scroll]
  local modelvalue
  local dim
  local value = 0

  if scrollbar.axis == 'y' then
    dim = scroll[_ydim]
    modelvalue = slider.y + dy
    if scrollbar.modelmax > 0 then
      value = math.floor(dim.max * (modelvalue/scrollbar.modelmax) + .5)
    end
  else
    dim = scroll[_xdim]
    modelvalue = slider.x + dx
    if scrollbar.modelmax > 0 then
      value = math.floor(dim.max * (modelvalue/scrollbar.modelmax) + .5)
    end
  end
 

  __updatevalue(scroll, dim, value)
  sync.scroll(scroll)
end

do --track
  local metacel = metacel['.bar']['.track']

  function metacel:__resize(track)
    local scrollbar = track[_scrollbar]
    if scrollbar.axis == 'y' then
      scrollbar.modelrange = track.h
    else
      scrollbar.modelrange = track.w
    end  
  end

  function metacel:onresize(track)
    sync.model(track[_scrollbar][_scroll])
  end
end

do --portal
  local metacel = metacel['.portal']

  metacel.__relink = false --don't allow subject to relink, must link how scroll makes it

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
      if scroll.h >= ydim.range and scroll.w >= xdim.range then
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

  function metacel:__resize(portal, ow, oh)
    local scroll = portal[_scroll]
    if portal.w ~= ow then 
      __updatesize(scroll, portal, scroll[_xdim], portal.w)
    end
    if portal.h ~= oh then
      __updatesize(scroll, portal, scroll[_ydim], portal.h)
    end
    __checkbars(scroll, portal)
  end

  function metacel:onresize(portal)
    sync.scroll(portal[_scroll])
  end

  do
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

    function metacel:__link(portal, link, linker, xval, yval, option)
      if 'subject' == option then
        local scroll = portal[_scroll]
        __updaterange(scroll, scroll[_xdim], link.w)
        __updaterange(scroll, scroll[_ydim], link.h)
        __checkbars(scroll, portal)
      end
      --TODO revisit if we have to return anything it we arent changing stuff
      return portal, linker, xval, yval, nil 
    end

    function metacel:__linkmove(portal, link, ox, oy, ow, oh)
      local scroll = portal[_scroll]
     
      if scroll[_subject] == link then
        --print('__linkmove')
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

    function metacel:__unlink(portal, link)
    local scroll = portal[_scroll]
    if scroll[_subject] == link then
      scroll[_subject] = nil
      __updaterange(scroll, scroll[_xdim], 0)
      __updaterange(scroll, scroll[_ydim], 0)
      __checkbars(scroll, portal)
      sync.scroll(scroll)

    end
  end
  end

  function metacel:onlinkmove(portal, link)
    local scroll = portal[_scroll]
    --if scroll[_insync] == 'syncing' then return end
    if scroll[_subject] == link then
      --print('onlinkmove sync')
      sync.scroll(portal[_scroll])
    end
  end

  function metacel:onlink(portal, link)
    local scroll = portal[_scroll]
    if scroll[_subject] == link then
      sync.scroll(portal[_scroll])
    end
  end

  
end

do
  local metacel =  metacel['.bar']
  local _new = metacel.new

  function metacel:__describe(scrollbar, t)
    t.axis = scrollbar.axis
    t.size = scrollbar.size
  end

  function metacel:new(scroll, axis, layout, face)
    assert(scroll)
    assert(axis)
    assert(layout)
    face = self:getface(face)

    local scrollbar = _new(self, layout.size, layout.size, face)
    scrollbar[_scroll] = scroll
    scrollbar.axis = axis
    scrollbar.size = layout.size
    scrollbar.autohide = layout.autohide and 'show' or false 
    scrollbar.modelrange = 0
    scrollbar.modelmax = 0
    scrollbar.minmodelsize = layout.track.slider.minsize

    do
      local layout = layout.track
      scrollbar[_track] = self['.track']:new(layout.size, layout.size, layout.face)
      scrollbar[_track][_scrollbar] = scrollbar
      scrollbar[_track].onpress = trackpressed
      scrollbar[_track].onhold = trackpressed
      do
        local layout = layout.slider
        scrollbar[_slider] = self['.slider']:new(layout.size, layout.size, layout.face)
        scrollbar[_slider][_scrollbar] = scrollbar
        scrollbar[_slider].ondrag = sliderdragged
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
    scrollbar[_slider]:link(scrollbar[_track], nil, nil, 'fence')
    return scrollbar
  end
end

--autohide is line or page
function metatable.step(scroll, xsteps, ysteps, mode)
  scroll[_subject]:endflow(scroll:getflow('scroll'))      
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

  --print('scroll to by step', x, y)
  return scroll:scrollto(x, y)
end

local function scrollflowupdate(subject, x, y)
  local scroll = subject[_scroll]
end

do
  local function updateflow(scroll, subject, x, y)
    __updatevalue(scroll, scroll[_xdim], -x)
    __updatevalue(scroll, scroll[_ydim], -y)
    sync.scroll(scroll)
  end

  function metatable.scrollto(scroll, x, y)
    sync.scroll(scroll)
    if scroll[_subject] then
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

      scroll[_subject]:endflow(scroll:getflow('scroll'))      
      scroll[_subject]:flow(scroll:getflow('scroll'), -x, -y, nil, nil,  scroll[_updateflow])
    end
    return scroll
  end
end

function metatable.getvalues(scroll)
  return scroll[_xdim].value, scroll[_ydim].value 
end

function metatable.getmaxvalues(scroll)
  return scroll[_xdim].max, scroll[_ydim].max 
end

function metatable.setsubject(scroll, subject, fillx, filly)
  assert(scroll)
  assert(subject)
  assert(scroll[_portal])
  assert(linkers.subject)
  if scroll[_subject] then
    scroll[_subject]:unlink()
  end

  scroll[_subject] = subject
  subject:link(scroll[_portal], linkers.subject, fillx, filly, 'subject') 
  return scroll
end

--THIS makes scroll a container, its item is getable and setable
function metatable.getsubject(scroll, subject)
  return scroll[_subject]
end

function metatable.getportalrect(scroll)
  return scroll[_portal]:pget('x', 'y', 'w', 'h')
end

function metacel:__link(scroll, link, linker, xval, yval, option)
  if scroll[_subject] and not option then
    return scroll[_subject], linker, xval, yval, option 
  elseif option == 'portal' then
    return scroll[_portal], linker, xval, yval
  elseif option == 'ybar' then
    return scroll[_ybar], linker, xval, yval
  elseif option == 'xbar' then
    return scroll[_xbar], linker, xval, yval
  elseif option == 'raw' then
    return scroll, linker, xval, yval
  elseif scroll[_subject] then
    return scroll[_subject], linker, xval, yval, option 
  end
  return scroll[_portal], linker, xval, yval
end

function metacel:onmousewheel(scroll, direction, x, y, intercepted)
  if not intercepted and scroll[_subject] then
    local invalue = scroll[_subject].y
    if cel.mouse.wheeldirection.down == direction then
      scroll:step(nil, cel.mouse.scrolllines or 1)
    elseif cel.mouse.wheeldirection.up == direction then
      scroll:step(nil, -(cel.mouse.scrolllines or 1))
    end
    return invalue ~= scroll[_subject].y
  end
end

do
  local _new = metacel.new
  function metacel:new(w, h, face)
    face = self:getface(face)
    local layout = face.layout or layout
    local scroll = _new(self, w, h, face)
    scroll.stepsize = layout.stepsize

    scroll[_xdim] = { value = 0, max = 0, size = 0, range = 0, }
    scroll[_ydim] = { value = 0, max = 0, size = 0, range = 0, }

    scroll[_portal] = self['.portal']:new(w, h)
    scroll[_portal][_scroll] = scroll

    local xval
    local yval
    if layout.xbar then
      local layout = layout.xbar
      scroll[_xbar] = self['.bar']:new(scroll, 'x', layout, layout.face)
      yval = scroll[_xbar].size
    end

    if layout.ybar then
      local layout = layout.ybar
      scroll[_ybar] = self['.bar']:new(scroll, 'y', layout, layout.face)
      xval = scroll[_ybar].size
    end

    scroll[_portal]:link(scroll, linkers.portal, xval, yval, 'raw')

    if scroll[_xbar] then
      scroll[_xbar]:link(scroll, linkers.xbar, 1, scroll[_ybar].size, 'raw')
    end
    if scroll[_ybar] then
      scroll[_ybar]:link(scroll, linkers.ybar, 1, scroll[_xbar].size, 'raw')
    end
    return scroll
  end

  local _compile = metacel.compile
  function metacel:compile(t, scroll)
    scroll = scroll or metacel:new(t.w, t.h, t.face)
    if t.subject then
      if cel.iscel(t.subject) then
        scroll:setsubject(t.subject, false, false) 
      else
        scroll:setsubject(t.subject[1], not not t.subject.fillwidth, not not t.subject.fillheight) 
      end
    end
    return _compile(self, t, scroll)
  end

  local _newmetacel = metacel.newmetacel
  function metacel:newmetacel(name)
    local newmetacel, metatable = _newmetacel(self, name) 
    --newmetacel['.portal'] = metacel['.portal']:newmetacel(name .. '.portal')    
    --newmetacel['.bar'] = metacel['.bar']:newmetacel(name .. '.bar')    
    --TODO add in other metacels
    return newmetacel, metatable
  end
end

return metacel:newfactory({layout = layout})
