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
local M = require 'cel.core.module'
local _ENV = require 'cel.core.env'
setfenv(1, _ENV)

M.util = require('cel.util')

local mouse = require('cel.core.mouse')
local keyboard = require('cel.core.keyboard')
require('cel.core.face')
require('cel.core.event')
require('cel.core.driver')
require('cel.core.metacel')
require('cel.core.cel')
require('cel.core.root')

M.col = require('cel.core.col')
M.row = require('cel.core.row')
M.slot = require('cel.core.slot')

do --cel.installdriver
  function M.installdriver(mousetable, keyboardtable, t)
    function M.installdriver()
      error('a driver is already installed')
    end

    M.util.readonly(mousetable.buttons, mouse.buttons)
    M.util.readonly(mousetable.states, mouse.states)
    M.util.readonly(mousetable.wheel, mouse.wheel)
    M.util.readonly(keyboardtable.keys, keyboard.keys)
    M.util.readonly(keyboardtable.states, keyboard.states)

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
  return _ENV.metacel:newmetacel(name)
end

--cel.new
function M.new(w, h, face)
  return metacel:new(w, h, face and metacel:getface(face))
end

function M.iscel(t)
  return type(t) == 'table' and rawget(t, _metacel) ~= nil
end

function M.tocel(v, host)
  local typ = type(v)
  if typ == 'table' and rawget(v, _metacel) then return v end
  if typ == 'string' then
    if host then return host[_metacel]:__celfromstring(host, v) end
    return M.label.new(v) 
  end
end

do --cel.debugjoins
  function M.debugjoins()
    dprint(string.rep('-', 40))
    local a = 0
    for anchor, t in pairs(joins) do
      a = a + 1
      dprint('anchor', anchor)

      local j = 0
      for joinedcel in pairs(t) do
        dprint('  joinedcel', joinedcel)
        j = j + 1
      end
      dprint(j, string.rep('j', j))
    end
    dprint(a, string.rep('a', a))
  end
end

do --cel.translate
  function M.translate(from, x, y, to) 
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

function M.touchlinksonly(cel, x, y)
  local metacel = cel[_metacel]
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

function M.notouch()
  return false
end

do --cel.describe, cel.printdescription
  local metadescription = {
    updaterect = updaterect 
  }
  local count = 0
  local _description

  local updaterect = updaterect
  function M.describe()
    local altered = false
    if not _description or root[_refresh] then
      updaterect.l = 99999
      updaterect.t = 99999
      updaterect.r = 0
      updaterect.b = 0

      count = count + 1
      metadescription.timer = M.timer()
      metadescription.count = count 
      _description = describe(root, nil, 0, 0, 0, 0, root[_w], root[_h])

      if updaterect.r < updaterect.l or updaterect.b < updaterect.t then
        updaterect.l = 0
        updaterect.t = 0
        updaterect.r = 0
        updaterect.b = 0
      end

      altered = true
    end
    return _description, metadescription, altered
  end
  local write = io.write
  local format = string.format

  local function printdescription(t, indent)
    t.face:print(t, indent, t.face[_name])
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

  function M.printdescription(t, metadescription)
    if metadescription then
      io.write(string.format('count:%d\ntimer:%d\n', t.count, t.timer))
      io.write(string.format('updaterect { l:%d t:%d r:%d b:%d }\n',
                t.updaterect.l, t.updaterect.t, t.updaterect.r, t.updaterect.b))

      t = t.description 
    end
    if t then
      printdescription(t, '')
    end
    io.flush()
  end
end

do --cel.doafter
  tasks = {} --ENV.tasks

  --TODO optimize, can create a lot of gc churn
  function M.doafter(ms, f)
    if not f then
      error('expected a function', 2)
    end

    local task = {
      func = f;
      due = M.timer() + ms,
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

    return f
  end
end

do --cel.getlinker
  function M.getlinker(name)
    return linkers[name] 
  end
end

do --clipboard
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
--from http://www.freetype.org/freetype2/docs/glyphs/glyphs-2.html
--resolution is DPI
--pixel_size = point_size * resolution / 72
--pixel_coord = grid_coord * pixel_size / EM_size
  
  local fontmt = {}
  do
    local string_sub = string.sub
    local string_char = string.char
    local string_byte = string.byte

    local function clamp(v, min, max)
      if v < min then v = min end
      if v > max then v = max end
      return v
    end

    do
      function fontmt.height(font)
        return font.ascent + font.descent
      end

      function fontmt.measure(font, s, i, j)
        if not s then return 0, 0, 0, 0, 0, 0, 0 end

        local start = i or 1
        local len = j and j-i+1 or #s 
        local xmin, xmax, ymin, ymax = 32000, -32000, 32000, -32000
        local penx = 0
        local nglyphs = 0

        for uchar in string.gmatch(s, '([%z\1-\127\194-\244][\128-\191]*)') do
        --for i=1, #s do local uchar = string_sub(s, i, i)
          if start > 1 then
            start=start-1
          elseif len > 0 then
            len=len-1

            local glyph = font.metrics[uchar]
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
            nglyphs = nglyphs + 1
          else
            break
          end
        end

        if xmin > xmax then
          return penx, font.ascent + font.descent, 0, 0, 0, 0, 0
        end

        return penx, font.ascent + font.descent, xmin, xmax, ymin, ymax, nglyphs
      end

      ---[[
      function fontmt.measureadvance(font, s, i, j)
        if not s then return 0 end
        if not i or i < 1 then i=1 end
        if j and i > j then return 0 end

        local advance = 0
        local count=0

        for uchar in string.gmatch(s, '([%z\1-\127\194-\244][\128-\191]*)') do
          count=count+1
          if count >= i then
            local glyph = font.metrics[uchar]
            advance=advance+glyph.advance
          end
          if count == j then
            return advance
          end
        end
        return advance
      end
      --]]

      --[[
      function fontmt.measureadvance(font, s, i, j)
        if not s then
          return 0
        end

        i = (i and math.max(i, 1)) or 1
        j = j or #s
        local advance = 0

        for i=i, j do
          local b = string_sub(s, i, i)

          if not b then return 0 end

          local glyph = font.metrics[b]
          advance = advance + glyph.advance
        end
        return advance
      end
      --]]

      --TODO move to utility package
      local function lerp(a, b, p)
        return a + p * (b -a)
      end

      function fontmt.pick(font, x, s)
        local metrics=font.metrics
        local penx = 0
        local count=0

        for uchar in string.gmatch(s, '([%z\1-\127\194-\244][\128-\191]*)') do
        --for i=1, #s do local uchar = string_sub(s, i, i)
          count=count+1
          local glyph = metrics[uchar]
          local nextpenx = penx + glyph.advance

          if nextpenx > x then
            local mid = lerp(penx, nextpenx, .5)
            if x < mid then
              return count-1, penx
            else
              return count, nextpenx
            end
          end
          penx = nextpenx
        end 

        return #s, penx
      end
    end

    do
      local iswhitespace = { [' ']=true, ['\t']=true, ['\r']=true, ['\n']='true' }

      local function wordwrap(font, s, penx, peny, lines)
        local metrics = font.metrics
        local advance=0
        local maxadvance=0
        local nlines=0
        local i=1
        local j=0

        for uchar in string.gmatch(s, '([%z\1-\127\194-\244][\128-\191]*)') do
        --for i=1, #s do local uchar = string_sub(s, i, i)
          local glyph = metrics[uchar]

          if not iswhitespace[uchar] then
            advance = advance+glyph.advance
            --include uchar in line text
            j=j+#uchar
          else
            if j >= i then --haveword
              nlines=nlines+1
              if advance > maxadvance then maxadvance=advance end

              if lines then
                lines[nlines] = {text=string.sub(s, i, j), penx=penx, peny=peny, advance=advance}
                peny = peny + font.lineheight
              end
            end

            advance=0
            j=j+#uchar
            --skip whitespace
            i=j+1
          end
        end

        if advance > 0 then
          if j >= i then --haveword
            nlines=nlines+1
            if advance > maxadvance then maxadvance=advance end

            if lines then
              lines[nlines] = {text=string.sub(s, i, j), penx=penx, peny=peny, advance=advance}
              peny = peny + font.lineheight
            end
          end
        end

        return maxadvance, nlines, lines
      end

      local function linewrap(font, s, penx, peny, lines)
        local metrics = font.metrics
        local advance=0
        local maxadvance=0
        local nlines=0
        local i=1
        local j=0

        for uchar in string.gmatch(s, '([%z\1-\127\194-\244][\128-\191]*)') do
        --for i=1, #s do local uchar = string_sub(s, i, i)
          local glyph = metrics[uchar]

          if '\n' ~= uchar then
            advance = advance+glyph.advance
            --include uchar in line text
            j=j+#uchar
          else
            nlines=nlines+1
            if advance > maxadvance then maxadvance=advance end

            if lines then
              local text
              if j >= i then --haveword
                text = string.sub(s, i, j)
              else
                text = ''
              end
              lines[nlines] = {text=text, penx=penx, peny=peny, advance=advance}
              peny = peny + font.lineheight
            end

            advance=0
            j=j+#uchar
            --skip whitespace
            i=j+1
          end
        end

        if advance > 0 then
          nlines=nlines+1
          if advance > maxadvance then maxadvance=advance end

          if lines then
            local text
            if j >= i then --haveword
              text = string.sub(s, i, j)
            else
              text = ''
            end
            lines[nlines] = {text=text, penx=penx, peny=peny, advance=advance}
          end
        end

        return maxadvance, nlines, lines
      end

      --word wrapmode will remove all whitespace, and each word will be on its own line
      --line wrapmode will remove \r and \n, all other whitspace is preserved
      --penx of first line, obtain via font:pad
      --peny of first line, obtain via font:pad
      function fontmt.wrap(font, wrapmode, s,  penx, peny, lines)
        if not s then
          return 0, 0, lines
        elseif wrapmode == 'word' then
          return wordwrap(font, s, penx, peny, lines)
        else
          return linewrap(font, s, penx, peny, lines)
        end
      end

      --line.advance for each line returned does not include trailing whitespace
      function fontmt.wrapat(font, advancebreak, s, penx, peny, lines)
        lines = lines or {}
        local metrics = font.metrics
        local maxadvance=0
        local nlines=0

        local inkadvance=0
        local lineadvance=0
        local wordadvance=0 
        local linei=1
        local linej=0
        local wordi=1
        local wordj=1
        local whitespace
        local wordfinished

        for uchar in string.gmatch(s, '([%z\1-\127\194-\244][\128-\191]*)') do
        --for i=1, #s do local uchar = string_sub(s, i, i)
          local glyph = metrics[uchar]

          if whitespace and (not iswhitespace[uchar]) then --if starting a word
            wordi=linej+1
            wordj=linej+1
            wordadvance=0
          end

          if not whitespace and iswhitespace[uchar] then --ending a word
            inkadvance=lineadvance
          end

          whitespace=iswhitespace[uchar]

          repeat
            local done=true

            --linebreak
            if '\n' == uchar then
              if inkadvance > maxadvance then maxadvance=inkadvance end
              local text
              if linej >= linei then 
                text = string.sub(s, linei, linej) 
              else 
                text = '' 
              end
              nlines=nlines+1
              lines[nlines] = {text=text, penx=penx, peny=peny, advance=inkadvance}
              peny = peny + font.lineheight

              linej=linej+#uchar
              linei=linej+1 --skip \n
              lineadvance=0
              inkadvance=0

            --advancebreak
            elseif lineadvance+glyph.advance > advancebreak and (not whitespace) then
              done=false --process this char again

              if wordi > linei then --working on second+ word, break at beginning of this word
                lineadvance=lineadvance-wordadvance
                if inkadvance > maxadvance then maxadvance=inkadvance end
                local text=string.sub(s, linei, wordi-1)
                nlines=nlines+1
                lines[nlines] = {text=text, penx=penx, peny=peny, advance=inkadvance}
                peny = peny+font.lineheight

                linei=wordi
                lineadvance=wordadvance
                inkadvance=wordadvance

              elseif wordj > wordi then --working on first word but not first char, break before this char
                if lineadvance > maxadvance then maxadvance=lineadvance end
                local text = string.sub(s, wordi, wordj) 
                nlines=nlines+1
                lines[nlines] = {text=text, penx=penx, peny=peny, advance=lineadvance}
                peny = peny+font.lineheight

                linei=wordj+1
                linej=linei
                lineadvance=0
                inkadvance=0

                wordi=linei
                wordj=linei
                wordadvance=0

              else --first char in line exceeds advancebreak, and may be follwed by whitespace which should be on same line
                done=true --go to next char
                linej=linej+#uchar
                wordj=linej
                lineadvance=lineadvance+glyph.advance
                wordadvance=wordadvance+glyph.advance
                inkadvance=lineadvance
              end

            --no break
            else
              --include space at ends of words even if whitespace exceeds advancebreak
              linej=linej+#uchar
              wordj=linej
              lineadvance=lineadvance+glyph.advance
              wordadvance=wordadvance+glyph.advance

              
            end
          until done
        end

        if lineadvance > 0 then
          if lineadvance > maxadvance then maxadvance=lineadvance end
          local text
          if linej >= linei then 
            text = string.sub(s, linei, linej) 
          else 
            text = '' 
          end
          nlines=nlines+1
          lines[nlines] = {text=text, penx=penx, peny=peny, advance=lineadvance}
        end

        return maxadvance, nlines, lines
      end
    end

    do
      --font is font passed to cel.text.measure
      --layout is where margin is defined
      --w, h, xmin, xmax, ymin, ymax is results returns from cel.text.measure
      local nopadding = {}
      function fontmt.pad(font, padding, w, h, xmin, xmax, ymin, ymax)
        padding = padding or nopadding
        local fitx = padding.fitx or padding.fit
        local fity = padding.fity or padding.fit

        local penx, peny = 0, 0

        if 'bbox' == fitx and 'bbox' == fity then
          w = xmax - xmin
          h = ymax - ymin

          local l = padding.l or 0
          if type(l) == 'function' then l = math.floor(l(w,h,font) + .5) end
          local t = padding.t or 0
          if type(t) == 'function' then t = math.floor(t(w,h,font) + .5) end
          local r = padding.r or l
          if type(r) == 'function' then r = math.floor(r(w,h,font) + .5) end
          local b = padding.b or t
          if type(b) == 'function' then b = math.floor(b(w,h,font) + .5) end

          w = w + l + r 
          h = h + t + b

          return -xmin + l, -ymin + t, w, h, l, t, r, b
        elseif 'bbox' == fitx then
          w = xmax - xmin

          local l = padding.l or 0
          if type(l) == 'function' then l = math.floor(l(w,h,font) + .5) end
          local t = padding.t or 0
          if type(t) == 'function' then t = math.floor(t(w,h,font) + .5) end
          local r = padding.r or l
          if type(r) == 'function' then r = math.floor(r(w,h,font) + .5) end
          local b = padding.b or t
          if type(b) == 'function' then b = math.floor(b(w,h,font) + .5) end

          w = w + l + r 
          h = h + t + b

          return -xmin + l, t+font.ascent, w, h, l, t, r, b
        elseif 'bbox' == fity then
          h=ymax-ymin

          local l = padding.l or 0
          if type(l) == 'function' then l = math.floor(l(w,h,font) + .5) end
          local t = padding.t or 0
          if type(t) == 'function' then t = math.floor(t(w,h,font) + .5) end
          local r = padding.r or l
          if type(r) == 'function' then r = math.floor(r(w,h,font) + .5) end
          local b = padding.b or t
          if type(b) == 'function' then b = math.floor(b(w,h,font) + .5) end

          local advance = font.metrics[' '].advance
          l=l+math.floor(advance/2)
          r=r+math.floor(.9+advance/2)
          w = w + l + r 
          h = h + t + b

          return l, -ymin + t, w, h, l, t, r, b
        else
          local l = padding.l or 0
          if type(l) == 'function' then l = math.floor(l(w,h,font) + .5) end
          local t = padding.t or 0
          if type(t) == 'function' then t = math.floor(t(w,h,font) + .5) end
          local r = padding.r or l
          if type(r) == 'function' then r = math.floor(r(w,h,font) + .5) end
          local b = padding.b or t
          if type(b) == 'function' then b = math.floor(b(w,h,font) + .5) end

          --local advance = font.metrics[' '].advance
          --l=l+math.floor(advance/2)
          --r=r+math.floor(.9+advance/2)
          w = w + l + r 
          h = h + t + b

          return l, t+font.ascent, w, h, l, t, r, b
        end
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

do
  M.flows = {}

  local function lerp(a, b, p)
    return a + p * (b -a)
  end

  local function smoothstep(a, b, p)
    return lerp(a, b, p*p*(3-2*p))
  end

  local function rlerp(a, b, c)
    return (c - a)/(b - a);
  end

  --
  --flow = {
    --iteration = 1,
    --duration = millis,
    --mode = 'value'|'rect',
    --finalize = false,
    --}
  local function flowrect(interp, maxduration, flow, ox, fx, oy, fy, ow, fw, oh, fh)
    if flow.duration >= maxduration then return fx, fy, fw, fh end
    local dt = flow.duration/maxduration
    local x = interp(ox, fx, dt)
    local y = interp(oy, fy, dt) 
    local w = interp(ow, fw, dt)
    local h = interp(oh, fh, dt)
    return x, y, w, h, true
  end

  local function flowvalue(interp, maxduration, flow, ov, fv)
    if flow.duration > maxduration then return fv end
    return interp(ov, fv, flow.duration/maxduration), true
  end
 
  do
    do
      local flows = setmetatable({}, {__mode = 'v'})

      local function flowrect(speed, flow, ox, fx, oy, fy, ow, fw, oh, fh)
        local dis = (flow.duration/1000)*speed
        local fdis = math.max(math.abs(fx-ox), math.abs(fy-oy), math.abs(fw-ow), math.abs(fh-oh))

        if dis >= fdis then
          return fx, fy, fw, fh 
        end

        local d = dis/fdis
        local x = lerp(ox, fx, d)
        local y = lerp(oy, fy, d) 
        local w = lerp(ow, fw, d)
        local h = lerp(oh, fh, d)
        return x, y, w, h, true
      end

      local function flowvalue(speed, flow, ov, fv)
        local dis = (flow.duration/1000)*speed
        local fdis = math.abs(fv - ov)

        if dis >= fdis then
          return fv
        end

        return lerp(ov, fv, dis/fdis), true
      end

      function M.flows.constant(pixelspersecond, mode)
        local f = flows[pixelspersecond]

        if not f then
          f = function(flow, ...)
            if flow.mode == 'rect' then
              return flowrect(pixelspersecond, flow, ...)
            else
              return flowvalue(pixelspersecond, flow, ...)
            end
          end
          flows[pixelspersecond] = f
        end

        return f
      end
    end

    local flows = setmetatable({}, {__mode = 'v'})
    function M.flows.linear(millis)
      local f = flows[millis]

      if not f then
        f = function(flow, ...)
          if flow.mode == 'rect' then
            return flowrect(lerp, millis, flow, ...)
          else
            return flowvalue(lerp, millis, flow, ...)
          end
        end
        flows[millis] = f
      end

      return f
    end

    local flows = setmetatable({}, {__mode = 'v'})
    function M.flows.smooth(millis)
      local f = flows[millis]

      if not f then
        f = function(flow, ...)
          if flow.mode == 'rect' then
            return flowrect(smoothstep, millis, flow, ...)
          else
            return flowvalue(smoothstep, millis, flow, ...)
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
  return function(hw, hh, x, y, w, h, xvals, yvals, minw, maxw, minh, maxh)
    x, y, w, h = a(hw, hh, x, y, w, h, xvals and xvals[1], yvals and yvals[1], minw, maxw, minh, maxh)
    --TODO why am i clamping to min/max here, shouldn't w/h be able to be outside of min/max then a cel will 
    --enforce that min/max after executing a linker
    if w > maxw then w = maxw end
    if w < minw then w = minw end
    if h > maxh then h = maxh end
    if h < minh then h = minh end
    x, y, w, h = b(hw, hh, x, y, w, h, xvals and xvals[2], yvals and yvals[2], minw, maxw, minh, maxh)
    return x, y, w, h
  end
end

function M.addlinker(name, linker)
  if type(name) ~= 'string' then
    return false, 'name of linker must be a string'
  end
  if linkers[name] then
    return false, string.format('linker %s already exists', name)
  end
  linkers[name] = linker
  return linker
end

do
  local empty = {}
  local function recurse(a, b, hw, hh, x, y, w, h, xvals, yvals, minw, maxw, minh, maxh)
    local vhx, vhy, vhw, vhh = a(hw, hh, x, y, w, h, xvals and xvals[1], yvals and yvals[1], minw, maxw, minh, maxh)
    x, y, w, h = b(vhw, vhh, x - vhx, y - vhy, w, h, xvals and xvals[2], yvals and yvals[2], minw, maxw, minh, maxh)
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



do
  function M.newfactory(metacel, metatable)
    print(debug.traceback('deprecated function'))
    return metacel:newfactory(metatable) 
  end
end

----[[ TODO load on demand


function M.colorface(color)
  local face = M.getface('cel', color..'#color#')
  if not face then 
    face = M.getface('cel'):new {
      color = color
    }:register(color..'#color#')
  end
  return face
end

M.string = {}

function M.string.link(s, host, ...)
  return host[_metacel]:__celfromstring(host, s):link(host, ...)
end

function M.newnamespace(N)

  N.cel = setmetatable({}, {
    __call=function(_, t)
      return N.compile('cel', t)      
    end})

  N.cel.new = function(...)
    return N.new('cel', ...)
  end

  local __index = function(namespace, k)
    --print('namespace __index', namespace, k)
    local v = M[k]
    if M.isfactory(v) then
      namespace[k] = setmetatable({}, {
        __index = v,
        __call = function(_, t)
          return N.compile(k, t)
        end,
      })

      namespace[k].new = function(...)
        return N.new(k, ...)
      end

      return namespace[k]
    else
      namespace[k] = v
      return namespace[k]
    end
  end

  
  --face
  --linkers
  --root

  return setmetatable(N, {__index=__index})
end


do
  local forks = setmetatable({}, {__mode='k'})

  
  function M.fork(acel, f)
    local fork = coroutine.wrap(f)

    local function yield(...)
      forks[acel] = fork
      return coroutine.yield(...)
    end

    return fork(acel, yield)
  end

  function M.resumefork(cel, ...)
    local acel = cel
    local fork = forks[cel]
    while (not fork) and cel do
      cel = rawget(cel, _host)
      if cel then
        fork = forks[cel]
      end
    end

    if fork then
      forks[cel] = false 
      return fork(...)
    end

    for k, v in pairs(forks) do
      dprint('fork', k, v)
    end
    error(string.format('cel %s is not forked', tostring(acel)))
  end
end

do --cel.trackmouse
  function M.trackmouse(func)
    _ENV.mousetrackerfuncs[func] = true
  end
end

do
  local proxyM = newproxy(true)
  getmetatable(proxyM).__index = M 
  getmetatable(proxyM).__newindex = function() error('attempt to update a read-only table', 2) end
  getmetatable(proxyM).__call = function(proxyM, t)
    return metacel:compile(t)
  end
  getmetatable(proxyM).__metatable = function() error('protected table') end
  M.cel = proxyM --this makes new and compile as defined by a namespace able to follow same rules for all metacels
  return proxyM 
end


