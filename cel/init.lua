
local M = {}
local _ENV = setmetatable({}, {__index = function(_ENV, key) 
                                           local v = _G[key]
                                           if v then 
                                             _ENV[key] = v 
                                             --print('got gloable', key, v)
                                           else
                                             error(string.format('bad index %s', tostring(key)), 2)
                                           end
                                           return v
                                         end})

setfenv(1, _ENV)



do
  local newproxy = newproxy
  local function privatekey(name) 
    return function() return name end
    --return {} 
    --return '__pk_' .. name 
  end

  _formation = privatekey('_formation')
  _host = privatekey('_host')
  _links = privatekey('_links')
  _next = privatekey('_next')
  _prev = privatekey('_prev')
  _trap = privatekey('_trap')
  _focus = privatekey('_focus')
  _name = privatekey('_name')
  _x = privatekey('_x')
  _y = privatekey('_y')
  _w = privatekey('_w')
  _h = privatekey('_h')
  _metacel = privatekey('_metacel')
  _vectorx = privatekey('_vectorx')
  _vectory = privatekey('_vectory')
  _linker = privatekey('_linker')
  _xval = privatekey('_xval')
  _yval = privatekey('_yval')
  _face = privatekey('_face')
  _pick = privatekey('_pick')
  _describe = privatekey('_describe')
  _movelink = privatekey('_movelink')
  _metafaces = privatekey('_metafaces')
  _minw = privatekey('_minw')
  _minh = privatekey('_minh')
  _maxw = privatekey('_maxw')
  _maxh = privatekey('_maxh')
  _mousedownlistener = privatekey('_mousedownlistener')
  _mouseuplistener = privatekey('_mouseuplistener')
  _focuslistener = privatekey('_focuslistener')
  _timerlistener = privatekey('_timerlistener')
  _keys = privatekey('_keys') 
  _buttonstates = privatekey('_buttonstates')
  _keystates = privatekey('_keystates')
  _celid = privatekey('_celid')
  _disabled = privatekey('_disabled')
end

maxdim = 2^31-1
maxpos = 2^31-1
minpos = -(2^31)

function _getminw(cel) return cel[_minw] or 0 end
function _getmaxw(cel) return cel[_maxw] or 2^31-1 end
function _getminh(cel) return cel[_minh] or 0 end
function _getmaxh(cel) return cel[_maxh] or 2^31-1 end


M.util = require('cel.util')

timer = {millis = 0} --ENV.timer

--ENV.linkers
linkers = require 'cel.linkers'

M.mouse = require('cel._mouse')(_ENV, M)

M.keyboard = require('cel._keyboard')(_ENV, M)

M.face = require('cel._face')(_ENV, M)

require('cel._event')(_ENV, M)
require('cel._driver')(_ENV, M)
require('cel._cel')(_ENV, M)

_ENV.root = require('cel._root')(_ENV, M)

M.match = M.util.match

do --cel.installdriver
  function M.installdriver(mousetable, keyboardtable, t)
    function M.installdriver()
      error('a driver is already installed')
    end

    M.util.readonly(mousetable.buttons, M.mouse.buttons)
    M.util.readonly(mousetable.buttonstates, M.mouse.buttonstates)
    M.util.readonly(mousetable.wheeldirection, M.mouse.wheeldirection)

    M.util.readonly(keyboardtable.keys, M.keyboard.keys)
    M.util.readonly(keyboardtable.keystates, M.keyboard.keystates)

    driver.root = _ENV.root
    return driver
  end
end

--cel.timer
function M.timer()
  return timer.millis 
end

--cel.newmetacel
function M.newmetacel(name)
  return metacel:newmetacel(name)
end

--cel.new
function M.new(w, h, face)
  return metacel:new(w, h, face and metacel:getface(face))
end

function M.iscel(t)
  return rawget(t, _metacel) ~= nil
end

function M.tocel(v, host)
  local typ = type(v)
  if typ == 'table' and rawget(v, _metacel) then return v end
  if typ == 'string' then
    if host then return host[_metacel]:__celfromstring(host, v) end
    return M.label.new(v) 
  end
end

do --cel.translate
  function M.translate(from, to, x, y) 
    while from do
      x = x + from[_x]
      y = y + from[_y]

      if to == from[_host] then
        return x, y
      end

      from = from[_host] 
    end
  end
end

do --cel.describe, cel.printdescription
  local preamble = {}
  local count = 0

  function M.describe()
    local altered = false
    if not preamble.description or refreshtable[root] then
      refreshtable = {}
      count = count + 1
      preamble.timestampdescribe = M.timer()
      preamble.count = count 
      preamble.description = describe(root, nil, 0, 0, 0, 0, root[_w], root[_h])
      altered = true
    end
    return preamble, altered
  end
  local write = io.write
  local format = string.format

  local function printdescription(t, indent)
    write(indent, format('%d %s[%s] {x:%d y:%d w:%d h:%d id:%s [l:%d t:%d r:%d b:%d]',
    t.id, t.metacel, tostring(t.face[_name]) or t.metacel, t.x, t.y, t.w, t.h, tostring(t.id),
    t.clip.l, t.clip.t, t.clip.r, t.clip.b))
    if t.mouse then write(',mouse') end
    if t.keyboard then write(',keyboard') end
    if t.focus then 
      write(',focus[') 
      if t.focus.mouse then write('mouse') end
      if t.focus.keyboard then write('keyboard') end
      write(']') 
    end

    if #t > 0 then
        write('\n')
      local subindent = indent .. '  '
      for i = #t,1,-1 do
        printdescription(t[i], subindent)  
      end
      write(indent, '}\n')
    else
      write('}\n')
    end
  end

  function M.printdescription(t, destination)
    write = destination or io.write
    t = t or M.getdescription() 
    printdescription(t, '')
    write = io.write
    io.flush()
  end

  --TODO remove this, its a hack
  function M.getdescription()
    return preamble.description
  end
end

do --cel.doafter
  tasks = {} --ENV.tasks

  local function canceltask(task)
    task.action = nil
  end

  function M.doafter(ms, f)
    if not f then
      error('expected a function', 2)
    end

    local due = M.timer() + ms
    local task = {
      action = f;
      cancel = canceltask,
      due = due,
      next = nil,
    }

    local prev = tasks
    local next = tasks.next

    while next do
      if task.due < next.due then
        task.next = next
        break
      end
      prev = next
      next = next.next
    end

    prev.next = task
    return task
  end
end

do --getlinker
  function M.getlinker(name)
    return linkers[name] 
  end
end

do --clipbaord
  local defaultclipboard = {}

  function M.clipboard(command, data)
    if driver.clipboard then
      return driver.clipboard(command, data)
    else
      if command == 'get' then
        return defaultclipboard.data
      elseif command == 'put' then
        defaultclipboard.data = data
        return defaultclipboard.data
      end
    end
  end
end

do --loadfont TODO make driver supply path and extension
  local fonts = setmetatable({}, {__mode = 'v'})

  local fontmt = {}
  do
    local string_byte = string.byte

    local function clamp(v, min, max)
      if v < min then v = min end
      if v > max then v = max end
      return v
    end

    function glyphs(font, s, i, j)
      i = (i and math.max(i, 1)) or 1
      j = j or #s
      return function(j, i)
        i = i + 1
        if i > j then return end
        return i, font.metrics[string_byte(s, i)]
      end, j, i - 1
    end

    do
      function fontmt.height(font)
        return font.bbox.ymax - font.bbox.ymin
      end

      function fontmt.measure(font, text, i, j)
        if not text --[[or #text < 1--]] then
          return 0, 0, 0, 0, 0, 0
        end

        local xmin, xmax, ymin, ymax = 32000, -32000, 32000, -32000
        local penx = 0

        for i, glyph in glyphs(font, text, i, j) do
          local glyph_xmin = penx + glyph.xmin
          local glyph_xmax = penx + glyph.xmax

          if glyph_xmin < xmin then
            xmin = glyph_xmin
          end
          if glyph_xmax > xmax then
            xmax = glyph_xmax
          end
          if glyph.ymin < ymin then
            ymin = glyph.ymin
          end
          if glyph.ymax > ymax then
            ymax = glyph.ymax
          end

          penx = penx + glyph.advance
        end

        if xmin > xmax then
          return penx, font.bbox.ymax - font.bbox.ymin, 0, 0, 0, 0
        end

        return penx, font.bbox.ymax - font.bbox.ymin, xmin, xmax, ymin, ymax
      end

      function fontmt.measureadvance(font, s, i, j)
        if not s --[[or #s < 1--]] then
          return 0
        end
        local advance = 0
        for i, glyph in glyphs(font, s, i, j) do
          advance = advance + glyph.advance
        end
        return advance
      end

      function fontmt.measurebbox(font, s, i, j)
        if not s --[[or #s < 1--]] then
          return 0, 0, 0, 0
        end
        local xmin, xmax, ymin, ymax = 32000, -32000, 32000, -32000
        local penx = 0

        for i, glyph in glyphs(font, s, i, j) do
          local glyph_xmin = penx + glyph.xmin
          local glyph_xmax = penx + glyph.xmax

          if glyph_xmin < xmin then
            xmin = glyph_xmin
          end
          if glyph_xmax > xmax then
            xmax = glyph_xmax
          end
          if glyph.ymin < ymin then
            ymin = glyph.ymin
          end
          if glyph.ymax > ymax then
            ymax = glyph.ymax
          end

          penx = penx + glyph.advance
        end

        if xmin > xmax then
          return 0, 0, 0, 0
        end

        return xmin, xmax, ymin, ymax
      end

      local function interpolate(a, b, p)
        return a + p * (b -a)
      end

      ---[[
      local math = math
      function fontmt.pickpen(font, text, i, j, x)
        local penx = 0
        i = (i and math.max(i, 1)) or 1
        j = j or #text
        local s = text
        for i = i, j do
          local glyph = font.metrics[string_byte(s, i)]
          local nextpenx = penx + glyph.advance
          if nextpenx > x then
            local mid = interpolate(penx, nextpenx, .5)
            if x < mid then
              return i, penx
            else
              return i + 1, nextpenx
            end
          end
          penx = nextpenx
        end 
        return j + 1, penx
      end
      --]]
    end


    do
      local function fencetext(font, text, i, j, fence)
        local index, advance = font:pickpen(text, i, j, fence)

        if advance > fence then
          return math.max(i, index -2)
        end
        return math.max(i, index-1)
      end

      --boundaries rightboundary, newline, word
      --preserves word continuity if possible
      function fontmt.wordwrap(font, text, rightboundary, mode, i, j)
        i = i or 1 
        j = j or #text
        mode = mode or 'strongwords' --strongwords means they don't get sliced unless there is no other choice
        --weaklines means lines can be sliced
        local string = string
        return function()
          if (not i) or i > j then return end
          local ri = i
          local k = fencetext(font, text, i, j, rightboundary)

          if k == j then
            local lb = string.find(text, '\n', i)
            if lb and lb - 1 <= k then 
              i = lb + 1
              return ri, lb - 1
            else
              i = nil
              return ri, k 
            end
          end

          do
            local lb = string.find(text, '\n', i)
            if lb and lb - 1 <= k then 
              i = lb + 1
              return ri, lb - 1
            end
          end
         
          if mode ~= 'strongwords' then
            i = k < j and k + 1 or nil
            return ri, k
          end

          do
            local retj, retk = k, k + 1
            local wbi, wbj = string.find(text, '%S%s+', i)
            while wbi and wbi <= k do
              retj, retk = wbi, wbj + 1
              wbi, wbj = string.find(text, '%S%s+', wbj + 1)
            end

            i = retk <= j and retk or nil
            return ri, retj 
          end
        end
      end

      --font is font passed to cel.text.measure
      --layout is where margin is defined
      --w, h, xmin, xmax, ymin, ymax is results returns from cel.text.measure
      function fontmt.pad(font, layout, w, h, xmin, xmax, ymin, ymax)
        local fitx = layout.fitx or layout.fit or 'default'
        local fity = layout.fity or layout.fit or 'default'
        --w is advancew, h is font height

        if 'default' == fitx then
          xmin = math.min(xmin, 0) --left is lesser of penx of xmin
          w = math.max(w, xmax - xmin) --right greater of advance or rightmost pixel as drawn
        elseif 'bbox' == fitx then
          w = xmax - xmin
        elseif 'multiline' == fitx then --TODO what is multiline for, is this really needed
          xmin = math.min(font.bbox.xmin, 0) --left is lesser of penx or xmin for font
          w = math.max(w, xmax - xmin) --right greater of advance or rightmost pixel as drawn
        end

        if 'bbox' == fity then
          h = ymax - ymin
          --repurposing ymin to indicate where peny should be
          --ymin = ymin 
        else
          --repurposing ymin to indicate where peny should be
          ymin = font.bbox.ymin
        end

        local padding = layout.padding
        if padding then
          local l = padding.l or 0
          local t = padding.t or 0
          if type(l) == 'function' then l = math.floor(l(w,h) + .5) end
          if type(t) == 'function' then t = math.floor(t(w,h) + .5) end

          local r = padding.r or l
          local b = padding.b or t
          if type(r) == 'function' then r = math.floor(r(w,h) + .5) end
          if type(b) == 'function' then b = math.floor(b(w,h) + .5) end

          w = w + l + r 
          h = h + t + b

          --subtractig b from h becuase t and b were both alrady added to h
          return -xmin + l, (h + ymin - b), w, h, l, t, r, b
        end

        return -xmin, h + ymin, w, h
      end
    end
  end

  function M.loadfont(name, size)
    name = name or 'default'
    size = size or 12 

    local key = name .. '-' .. size
    local font = fonts[key]

    if font then
      return font
    end

    if not driver.loadfont then
      error('driver does not implement loadfont')
    end

    name = name .. ':normal:normal'
    local name, weight, slant = name:match("([^:]*):([^:]*):([^:]*)")
    local weight = weight or 'normal'
    local slant = slant or 'normal'

    size = math.modf(96/72 * size) --convert point to pixels

    local ok, ret = pcall(driver.loadfont, name, weight, slant, size)
    if ok then
      font = setmetatable(ret, {__index=fontmt})
    else
      print('ERROR loading font', ret)
      font = setmetatable(driver.loadfont('default', weight, slant, size), {__index=fontmt})
    end
    fonts[key] = font
    return font
  end
end

setmetatable(M, 
  { 

    __index = function(M, key)
      M[key] = select(2, assert(pcall(require, 'cel.' .. key)))
      return M[key]
    end,

  })

do
  M.flows = {}

  local function interpolate(a, b, p)
    return a + p * (b -a)
  end

  --
  --flow = {
    --iteration = 1,
    --duration = millis,
    --mode = 'value'|'rect',
    --finalize = false,
    --}
  local function linearflowrect(maxduration, flow, ox, fx, oy, fy, ow, fw, oh, fh)
    if flow.duration >= maxduration then return fx, fy, fw, fh end
    local dt = flow.duration/maxduration
    local x = interpolate(ox, fx, dt)
    local y = interpolate(oy, fy, dt) 
    local w = interpolate(ow, fw, dt)
    local h = interpolate(oh, fh, dt)
    return x, y, w, h, true
  end

  local function linearflowvalue(maxduration, flow, ov, fv)
    if flow.duration > maxduration then return fv end
    return interpolate(ov, fv, flow.duration/maxduration), true
  end
 
  do
    local flows = setmetatable({}, {__mode = 'v'})

    function M.flows.linear(millis, mode)
      local f = flows[millis]

      if not f then
        f = function(flow, ...)
          if flow.mode == 'rect' then
            return linearflowrect(millis, flow, ...)
          else
            return linearflowvalue(millis, flow, ...)
          end
        end
        flows[millis] = f
      end

      return f
    end
  end
end

function M.composelinker(a, b)
  if type(a) == 'string' then
    a = linkers[a]
  end
  if type(b) == 'string' then
    b = linkers[b]
  end

  assert(a)
  assert(b)

  --TODO memoize
  return function(hw, hh, x, y, w, h, cvals, _)
    x, y, w, h = a(hw, hh, x, y, w, h, cvals and cvals[1], cvals and cvals[2])
    x, y, w, h = b(hw, hh, x, y, w, h, cvals and cvals[3], cvals and cvals[4])
    return x, y, w, h
  end
end

function M.addlinker(name, linker)
  assert(linker)
  if linkers[name] then
    return false, 'linker with that name already exists'
  end
  linkers[name] = linker
  return linker
end

do
  local function recurse(a, b, hw, hh, x, y, w, h, tvals)
    tvals = tvals or empty
    local vhx, vhy, vhw, vhh = a(hw, hh, x, y, w, h, tvals[1], tvals[2])
    x, y, w, h = b(vhw, vhh, x - vhx, y - vhy, w, h, tvals[3], tvals[4])
    return x + vhx, y + vhy, w, h
  end

  function M.rcomposelinker(a, b)
    if type(a) == 'string' then a = linkers[a] end
    if type(b) == 'string' then b = linkers[b] end

    return function(...)
      return recurse(a, b, ...)
    end
  end
end

function M.vhost(vhostlinker, linker)
  if type(vhostlinker) == 'string' then
    vhostlinker = linkers[vhostlinker] --TODO don't put host virtualizer in with linkers
  end
  if type(linker) == 'string' then
    linker = linkers[linker]
  end

  assert(linker)
  return function(hw, hh, x, y, w, h, cvals, _)
    return vhostlinker(hw, hh, x, y, w, h, cvals and cvals[1], cvals and cvals[2],
    linker, cvals and cvals[3], cvals and cvals[4])
  end
end

do
  local empty = {}
  function M.composevhost(a, b)
    if type(a) == 'string' then a = linkers[a] end
    if type(b) == 'string' then b = linkers[b] end

    --TODO memoize
    return function(hw, hh, x, y, w, h, cvals, _)
      cvals = cvals or empty
      local vhx, vhy, vhw, vhh = a(hw, hh, x, y, w, h, cvals[1], cvals[2])
      x, y, w, h = b(vhw, vhh, x - vhx, y - vhy, w, h, cvals[3], cvals[4])
      return x + vhx, y + vhy, w, h
    end
  end
end

--[[
function M.virtualhost(host, xval, yval, linker)
  return host, 
end
--]]

do
  M.color = {}
  local math_min = math.min
  local math_max = math.max
  local math_floor = math.floor
  local string_char = string.char
  local string_byte = string.byte
  function M.color.encode(r, g, b, a)
    r = r and math_min(255, math_max(255 * r, 0)) or 0
    g = g and math_min(255, math_max(255 * g, 0)) or 0
    b = b and math_min(255, math_max(255 * b, 0)) or 0
    a = a and math_min(255, math_max(255 * a, 0)) or 255
    return string_char(r, g, b, a)
  end
  function M.color.rgb(r, g, b)
    return string_char(r, g, b, 255)
  end
  function M.color.rgba(r, g, b, a)
    return string_char(r, g, b, a)
  end

  function M.color.decode(color)
    return string_byte(color, 1, 4)
  end

end

do
  function M.newfactory(metacel, metatable)
    print(debug.traceback('deprecated function'))
    return metacel:newfactory(metatable) 
  end
end

----[[ TODO load on demand
M.sequence = {
  x = require('cel._sequencex')(_ENV, M),
  y = require('cel._sequencey')(_ENV, M),
}

M.slot = require('cel._slot')(_ENV, M)
M.grid = require('cel._grid')(_ENV, M)
--]]


M.string = {}

function M.string.link(s, host, ...)
  return host[_metacel]:__celfromstring(host, s):link(host, ...)
end

do
  local proxyM = newproxy(true)
  getmetatable(proxyM).__index = M 
  getmetatable(proxyM).__newindex = function() error('attempt to update a read-only table', 2) end
  getmetatable(proxyM).__call = function(proxyM, t)
    return metacel:compile(t)
  end
  getmetatable(proxyM).__metatable = function() error('protected table') end
  return proxyM 
end

--[[
local function touchlinksonly(cel, x, y)
  local metacel = cel[_metacel]
  if metacel[_pick] then 
    local link = metacel[_pick](metacel, cel, x, y)
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
--]]
