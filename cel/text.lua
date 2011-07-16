local cel = require 'cel'

local metacel, metatable = cel.newmetacel('text')

local _font = {}
local _lines = {}
local _penx = {}
local _peny = {}
local _str = {}
local _padl = {}
local _padt = {}
local _padr = {}
local _padb = {}
local _layout = {}
local _wrap = {}

local layout = {
  fit = 'default',
  fitx = 'default',
  fity = 'default',
  padding = {
    l = 2,
    t = 2,
  },
}

function metatable:getbaseline(i)
  i = i or 1
  local line = self[_lines][i]
  if line then
    return line.penx, line.peny
  end
end

--returns x,y,w,h for the line relative to teh top left of the text cel
function metatable:getlinerect(i)
  local line = self[_lines][i]
  if line then
    return self[_padl], line.y, self.w - self[_padl] - self[_padr], line.h
  end
end

--returns i, j, portion of the string on the line, string.sub(text:gettext(), i, j) would
--give the string that the line contains
function metatable:getlinerange(i)
  local line = self[_lines][i]
  if line then
    return line.i, line.j
  end
end

--returns the index of the line that contains the i'th character in the text string
--and the index of the line that contains the j'th character in the text string
function metatable:getlineindex(i, j)
  local ri, rj
  for index, line in ipairs(self[_lines]) do
  end
end

function metatable:getfont()
  return self[_font]
end

function metatable.pickline(text, y)
  local lines = text[_lines]

  if not lines then return end

  local start = lines[1].y
  local lineh = lines[1].h

  if lineh < 1 then return end
  --normalize y
  y = y - start

  if y < 0 then return end

  local index = math.ceil(y / lineh) 

  return index
end

local function reflow(text)
  local w, h = text.w, text.h
  local font = text[_font]
  local str = text[_str]
  local penx = text[_penx]
  local peny = text[_peny]
  local lineheight = font.lineheight--:height()

  local lines = {}
  w = w - (text[_padl] or 0)
  w = w - (text[_padr] or 0)

  local y = text[_padt] or 0

  for i, j in font:wordwrap(str, w) do
    lines[#lines + 1] = {i = i, j = j, penx = penx, peny = peny, y = y, h = lineheight}
    peny = peny + lineheight
    y = y + lineheight
  end

  text[_lines] = lines 

  return y + (text[_padb] or 0)
end

function metatable:settext(str)
  str = str or ''
  local font = self[_font]
  local layout = self[_layout]

  self[_str] = str

    local penx, peny, w, h, l, t, r, b = font:pad(layout, font:measure(str)) 
    self[_padl] = l
    self[_padt] = t
    self[_padr] = r
    self[_padb] = b
    self[_penx] = penx
    self[_peny] = peny

    --TODO delay defining a line until it is described
    if self[_wrap] then
      --TODO don't want to reflow twice when chaning the text
      local minh = reflow(self)
      metacel:setlimits(self, nil, w, minh, nil)
    else
      self[_lines] = {{i = 1, j = nil, penx = penx, peny = peny, 
                       y = t or 0, h = font.lineheight}}
      metacel:setlimits(self, w, w, h, h)
    end
    self:refresh()
end

function metatable:gettext()
  return self[_str]
end

function metatable:getpadding()
  return self[_padl], self[_padt], self[_padr], self[_padb]
end

--true == wrap
--false == nowrap
function metatable.setwrapmode(text, mode)
  if mode then
    metacel:setlimits(text, nil, nil, nil, nil)
  else
    local font, str, layout = text[_font], text[_str], text[_layout]
    local _, _, w, h = font:pad(layout, font:measure(str))
    metacel:setlimits(text, w)
  end
end

function metacel:__describe(text, t)
  t.text = text[_str]
  t.font = text[_font]  
  t.lines = text[_lines]
end

--TODO decrease calls to __resize for links in a sequence
do
  function metacel:__resize(text, ow, oh)
    if text.w ~= ow and text[_wrap] then
      local minh = reflow(text)
      self:setlimits(text, text.minw, text.maxw, minh, text.maxh, nil, minh)
    end
  end
end

do
  local math = math
  local _new = metacel.new
  function metacel:new(str, wrapmode, face)
    face = self:getface(face)

    local font = face.font
    local layout = face.layout or layout
    local penx, peny, w, h, l, t, r, b = font:pad(layout, font:measure(str)) 
    local text 
    if wrapmode ~= 'nowrap' then
      text = _new(self, w, h, face, nil, w, h, nil)
      text[_wrap] = 'word'
    else
      text = _new(self, w, h, face, w, w, h, h)
      text[_wrap] = nil 
    end

    text[_layout] = layout
    text[_padl] = l
    text[_padt] = t
    text[_padr] = r
    text[_padb] = b
    text[_font] = font
    text[_str] = str
    text[_penx] = penx --TODO this should be an integer already
    text[_peny] = peny

    do
      local int, zero = math.modf(penx) assert(zero == 0)
      local int, zero = math.modf(peny) assert(zero == 0)
    end
    --TODO delay defining a line until it is described
    text[_lines] = {{i = 1, j = nil, penx = penx, peny = peny, y = t or 0, h = font.lineheight}}

    return text
  end

  local _compile = metacel.compile
  function metacel:compile(t, text)
    return _compile(self, t, text or metacel:new(t.text, t.wrapmode, t.face))
  end
end

return metacel:newfactory({layout = layout})
