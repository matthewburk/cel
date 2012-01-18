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
local cel = require 'cel'

local metacel, metatable = cel.newmetacel('text')

local _font = {}
local _lines = {}
local _penx = {}
local _peny = {}
local _layout = {}
local _wrap = {}
local _str = {}
local _hpad = {}
local _vpad = {}
local _justification = {}

local layout = {
  wrap = 'word',
  padding = {
    fit = 'default',
    fitx = 'default',
    fity = 'default',
    l = 2,
    t = 2,
  },
}

local function justify(text, w)
  w = w or text.w
  local textw = w - text[_hpad]
  local justification = text[_justification] or text[_layout].justification
  local lines = text[_lines]
  local penx = text[_penx]
  if 'center' == justification then
    for i=1, #lines do
      local line = lines[i]
      line.penx = math.floor(penx + ((textw-line.advance)/2))
    end
  elseif 'right' == justification then
    for i=1, #lines do
      local line = lines[i]
      line.penx = math.floor(penx + (textw-line.advance))
    end
  end
end

local function wrap(text)
  local lines = {}
  local font = text[_font]
  local textw = text.w - text[_hpad]

  do --lines
    local penx, peny = text[_penx], text[_peny]
    local str = text[_str]
    local i = 1

    while true do
      local j, advance, char = font:wrapat(str, i, #str, textw, text[_wrap])
      if not j then break end
      lines[#lines + 1] = { i = i, j = j, penx = penx, peny = peny, advance=advance }
      peny = peny + font.lineheight
      i = j + 1
    end
  end

  text[_lines] = lines

  local minh = font.ascent + font.descent + ((#lines-1)*font.lineheight) + text[_vpad]
  text:setlimits(text.minw, text.maxw, minh, minh)
end

local function initstr(text, str, font, layout)
  str = str or ''

  --this removes leading spaces on strings if the string starts with [\n 
  local pattern = str:match('^%[(\n%s+)')
  if pattern then
    str = str:gsub(pattern, '\n'):sub(3)
  end


  local textw, texth, xmin, xmax, ymin, ymax = font:measure(str)
  local penx, peny, w, h, l, t, r, b = font:pad(layout.padding, textw, texth, xmin, xmax, ymin, ymax ) 

  text[_str] = str
  text[_penx] = penx
  text[_peny] = peny
  text[_hpad] = l + r
  text[_vpad] = t + b

  local lines = {}
  text[_lines] = lines

  local maxlines = 0
  local minw, minh = 0, 0
 
  do --minw
    local i = 1
    while true do
      local j, advance = font:wrap(str, i, #str, text[_wrap])
      if not j then break end
      i = j + 1
      if advance > minw then minw = advance end
      maxlines = maxlines + 1
    end
  end

  minw = minw + l + r

  local maxlinew = 0

  do --lines
    local i = 1
    while true do
      local j, advance = font:wrap(str, i, #str, 'line')
      if not j then break end
      lines[#lines + 1] = {i = i, j = j, penx = penx, peny = peny, advance=advance}
      peny = peny + font.lineheight
      i = j + 1
      if advance > maxlinew then maxlinew = advance end
    end
  end

  maxlinew = maxlinew + l + r

  minh = font.ascent + font.descent + ((#lines-1)*font.lineheight) + text[_vpad]

  text:setlimits(minw, maxlinew, minh, minh, maxlinew, minh)

  if text.w < maxlinew then
    wrap(text)
  else
  end


  if text.h > minh then --make text always centered vertically, until there is a good reason to offer alternatives
    local peny = text[_peny] + math.floor((text.h - minh)/2)
    for i=1, #lines do
      local line = lines[i]
      line.peny = peny
      peny = peny + font.lineheight
    end
  end
end

function metatable.justify(text, value)
  text[_justification] = value
  justify(text)
  return text:refresh()
end

function metatable.getfont(text)
  return text[_font]
end

function metatable.getbaseline(text)
  local line = text[_lines][1]
  return line.penx, line.peny
end

function metatable.getline(text, i, property, ...)
  local line = text[_lines][i]
  if line then
    if property then
      return line[property], text:getline(i, ...)
    end
  end
end

function metatable.settext(text, str)
  initstr(text, str, text[_font], text[_layout])
  justify(text)
  return text:refresh()
end

function metatable.printf(text, format, ...)
  return text:settext(string.format(format, ...))
end

function metatable.gettext(text)
  return text[_str]
end

function metatable.__tostring(text)
  return 'text[' .. text[_str] .. ']'
end

function metacel:__describe(text, t)
  t.text = text[_str]
  t.font = text[_font]  
  t.lines = text[_lines]
end

--TODO decrease calls to __resize for links in a sequence
function metacel:__resize(text, ow, oh)
  if text.w ~= ow then
    wrap(text)
    justify(text)
  end

  --make text always centered vertically, until there is a good reason to offer alternatives
  if text.h > text.minh then
    local font = text[_font]
    local lines = text[_lines]
    local peny = text[_peny] + math.floor((text.h - text.minh)/2)
    for i=1, #lines do
      local line = lines[i]
      line.peny = peny
      peny = peny + font.lineheight
    end
  end
end

do
  local _new = metacel.new
  function metacel:new(str, face, wrap)
    face = self:getface(face)
    local text = _new(self, 0, 0, face)
    text[_layout] = face.layout or layout
    text[_font] = face.font
    text[_wrap] = wrap or text[_layout].wrap
    initstr(text, str, text[_font], text[_layout])
    justify(text)
    return text
  end

  local _compile = metacel.compile
  function metacel:compile(t, text)
    return _compile(self, t, text or metacel:new(t.text, t.face, t.wrap))
  end
end

return metacel:newfactory({layout = layout})
