local cel = require 'cel'

local metacel, metatable = cel.newmetacel('richtext')

local _font = {}
local _lines = {}
local _penx = {}
local _peny = {}
local _text = {}
local _padl = {}
local _padt = {}
local _padr = {}
local _padb = {}
local _layout = {}
local _caret = {}

local layout = {
  wordwrap = true,
  linewrap = true,
  padding = {
    l = 2,
    t = 2,
  },
}

function metatable.gettext(richtext)
  return richtext[_text]
end

local function synccaret(richtext, caret)
  if caret then
    local lines = richtext[_lines]
    --TODO tablex.bsearch
    for index, line in ipairs(lines) do
      if line.i > caret.i then
        break
      end
      caret.lineindex = index
      caret.peny = line.peny
    end
    local line = lines[caret.lineindex]
    --print(string.format('caret.i %d, line.i %d, line.j %d', caret.i, line.i, line.j))
    caret.penx = richtext[_font]:measureadvance(richtext[_text], line.i, caret.i - 1) + (richtext[_padl] or 0)
  end
end

--true == wrap
--false == nowrap
function metatable.setwrapmode(richtext, mode)
  if mode then
    metacel:setlimits(richtext, nil, nil, nil, nil)
  else
    local font, text, layout = richtext[_font], richtext[_text], richtext[_layout]
    local _, _, w, h = font:pad(layout, font:measure(text))
    metacel:setlimits(richtext, w)
  end
end

local function __reflow(richtext, w, h)
  --print('text-reflow')
  local font = richtext[_font]
  local text = richtext[_text]
  local penx = richtext[_penx]
  local peny = richtext[_peny]
  local caret = richtext[_caret]
  local fonth = font.lineheight--:height()

  local lines = {}
  w = w - (richtext[_padl] or 0)
  w = w - (richtext[_padr] or 0)

  local y = richtext[_padt] or 0

  for i, j in font:wordwrap(text, w) do
    lines[#lines + 1] = {i = i, j = j, penx = penx, peny = peny, y = y, h = fonth}
    peny = peny + fonth
    y = y + fonth
  end

  richtext[_lines] = lines 

  if richtext[_caret] then
    synccaret(richtext, richtext[_caret]) 
  end

  --return fonth * (#lines) + ((richtext[_padt] or 0) + (richtext[_padb] or 0))
  return y + (richtext[_padb] or 0)
end

function metacel:__describe(richtext, t)
  t.text = richtext[_text]
  t.font = richtext[_font]  
  t.lines = richtext[_lines]

  local caret = richtext[_caret]
  if caret and 1 == richtext:hasfocus() then
    t.caret = caret.i
    t.caretx = caret.penx
    t.carety = caret.peny
    t.caretline = t.lines[caret.lineindex]
  else
    t.caret = false
    t.caretx = 0
    t.carety = 0
    t.caretline = false
  end
end

--[[ This is faster for small < 1000 or so in a sequence, but is also incorrect,
--doing it the right way is vastly faster for >1000 in a sequence
do
  local n = 0
  function metacel:refit(richtext, minh)
    n = n + 1
    if n % 100 == 0 then
    print('refit', n, elapsedtime())
  end
    richtext._refitcall = nil
    local minh = __reflow(richtext, richtext.w, richtext.h)
    self:setlimits(richtext, richtext.minw, richtext.maxw, minh, richtext.maxh)
    richtext:resize(nil, minh)
  end

  function metacel:__resize(richtext, ow, oh)
    if richtext.w ~= ow then
      if richtext._refitcall then
        richtext._refitcall.cancel = true
      end
      richtext._refitcall = self:asyncall('refit', richtext)
    end
  end
end
--]]
---[[
--TODO this is the right way, but must find a way to decrease calls to __resize for links in a sequence
do
  function metacel:__resize(richtext, ow, oh)
    if richtext.w ~= ow then
      local minh = __reflow(richtext, richtext.w, richtext.h)
      self:setlimits(richtext, richtext.minw, richtext.maxw, minh, richtext.maxh)
      richtext:resize(nil, minh)
    end
  end
end
--]]


local function pickline(richtext, y)

  local lines = richtext[_lines]

  if not lines then return end

  local start = lines[1].y
  local lineh = lines[1].h

  if lineh < 1 then return end
  --normalize y
  y = y - start

  if y < 0 then return end

  local index = math.ceil(y / lineh) 
  return lines[index], index
end


local function picktext(richtext, x, y)
  local line, lineindex = pickline(richtext, y)
  if line then
    --normalize x
    x = x - line.penx

    local index, penx = richtext[_font]:pickpen(richtext[_text], line.i, line.j, x)
    richtext[_caret] = cel.richtext.caret(richtext[_text], index, penx + line.penx , line.peny, lineindex)
  end
end

--[[
function metacel:onmousemove(text, x, y)
  local mouse = text.mouse

  if text:hasmousetrapped() and 1 == mouse:buttonstate(1) then
    local newcaretpos, newcaret = nearestpenx(text, x)
    text:movecaret(newcaret, 'select')
    text[_caret]:select(index, penx, peny)
  end
end
--]]

function metacel:onmouseup(richtext, button, x, y, intercepted)
  richtext:freemouse()
end

function metacel:onmousedown(richtext, state, button, x, y, intercepted)
  if intercepted then return end

  local buttons = cel.mouse.buttons

  if cel.match(button, buttons.left, buttons.right, buttons.middle) then
    richtext:trapmouse()
    richtext:takefocus()
    picktext(richtext, x, y)
    return true
  end
end

do
  local math = math
  local _new = metacel.new
  function metacel:new(text, wrapmode, face)
    face = self:getface(face)

    local font = face.font
    local layout = face.layout or layout
    local penx, peny, w, h, l, t, r, b = font:pad(layout, font:measure(text)) 
    local richtext 
    if wrapmode ~= 'nowrap' then
      richtext = _new(self, w, h, face, nil, w, h, nil)
    else
      richtext = _new(self, w, h, face, w, w, h, h)
    end

    richtext[_layout] = layout
    richtext[_padl] = l
    richtext[_padt] = t
    richtext[_padr] = r
    richtext[_padb] = b
    richtext[_font] = font
    richtext[_text] = text
    richtext[_penx] = math.modf(penx) --TODO this should be an integer already
    richtext[_peny] = math.modf(peny)
    --TODO delay defining a line until it is described
    richtext[_lines] = {{i = 1, j = nil, penx = penx, peny = peny, y = t or 0, h = font.lineheight}}

    return richtext
  end

  local _compile = metacel.compile
  function metacel:compile(t, richtext)
    return _compile(self, t, richtext or metacel:new(t.text, t.wrapmode, t.face))
  end
end

local function caret(text, index, penx, peny, lineindex)
  return {
    text = text,
    i = index,
    j = nil,
    penx = penx,
    peny = peny,
    lineindex = lineindex,
  }
end

return metacel:newfactory({layout = layout, caret = caret})
