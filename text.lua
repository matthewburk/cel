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
local _wrapmode = {}
local _str = {}
local _hpad = {}
local _vpad = {}
local _justification = {}
local _naturalh = {}
local _len = {}

local layout = {
  wrap = 'line',
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

--TODO do not call this if text wrap mode is line wrap
local function wrap(text)
  local font = text[_font]
  local textw = text.w - text[_hpad]
  local h=text[_naturalh]-((#text[_lines]-1)*font.lineheight)
  local penx, peny = text[_penx], text[_peny]
  local str = text[_str]
  local maxlinew, nlines, lines = font:wrapat(textw, str, penx, peny, {})

  text[_lines] = lines
  text[_naturalh]=h+((nlines-1)*font.lineheight)
  text:setlimits(text.minw, text.maxw, text[_naturalh], text[_naturalh])
end

local function initstr(text, str, font, layout)
  str=str or ''

  --this removes leading spaces on strings if the string starts with [\n 
  local pattern = str:match('^%[(\n%s+)')
  if pattern then
    str = str:gsub(pattern, '\n'):sub(3)
  end

  local textw, texth, xmin, xmax, ymin, ymax, len=font:measure(str)
  local penx, peny, w, h, l, t, r, b=font:pad(layout.padding, textw, texth, xmin, xmax, ymin, ymax) 

  text[_str] = str
  text[_penx] = penx
  text[_peny] = peny
  text[_hpad] = l+r
  text[_vpad] = t+b
  text[_len] = len

  local minw, maxw=0, 0
  local nlines, lines

  if text[_wrapmode] == 'word' then
    local maxadvance = font:wrap('word', str, penx, peny)
    minw=math.floor(penx+maxadvance+l+r+.5)

    maxadvance, nlines, lines = font:wrap('line', str, penx, peny, {})
    maxw=math.floor(penx+maxadvance+l+r+.5)
  else
    local maxadvance
    maxadvance, nlines, lines = font:wrap('line', str, penx, peny, {})
    minw=math.floor(penx+maxadvance+l+r+.5)
    maxw=minw
  end

  text[_lines]=lines
  text[_naturalh]=h+((nlines-1)*font.lineheight)

  text:setlimits(minw, maxw, text[_naturalh], text[_naturalh], maxw, text[_naturalh])

  if text.w < maxw then
    wrap(text)
  else
  end

  --make text always centered vertically, until there is a good reason to offer alternatives
  if text.h > text[_naturalh] then 
    local peny = text[_peny] + math.floor((text.h - text[_naturalh])/2)
    for i=1, nlines do
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
  return line.peny
end

function metatable.getpenorigin(text)
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

function metatable.len(text)
  return text[_len]
end

function metatable.__tostring(text)
  return 'text[' .. text[_str] .. ']'
end

function metacel:__describe(text, t)
  t.text = text[_str]
  t.font = text[_font]  
  t.lines = text[_lines]
end

--TODO decrease calls to __resize for links in a col/row
function metacel:__resize(text, ow, oh)
  if text.w ~= ow then
    wrap(text)
    justify(text)
  end

  --make text always centered vertically, until there is a good reason to offer alternatives
  if text.h > text[_naturalh] then
    local font = text[_font]
    local lines = text[_lines]
    local peny = text[_peny] + math.floor((text.h - text[_naturalh])/2)
    for i=1, #lines do
      local line = lines[i]
      line.peny = peny
      peny = peny + font.lineheight
    end
  end
end

do
  local _new = metacel.new
  function metacel:new(str, face, wrapmode)
    face = self:getface(face)
    local text = _new(self, 0, 0, face)
    text[_layout] = face.layout or layout
    text[_font] = face.font
    text[_wrapmode] = wrapmode or text[_layout].wrap
    initstr(text, str, text[_font], text[_layout])
    justify(text)
    return text
  end

  local _compile = metacel.compile
  function metacel:compile(t, text)
    text = text or metacel:new(t.text, t.face, t.wrap)
    if t.justify then
      text:justify(t.justify)
    end
    return _compile(self, t, text)
  end
end

return metacel:newfactory({layout = layout})
