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

function metatable.append(richtext, acel)

end

function metatable.pushfont(richtext, font)
end

function metatable.pushcolor(richtext, color)
end
function metatable.pushstyle(richtext, style)
end

cel.ftext { 
 'Hello my name [font=arial][size=15] is slime shayd' [/size];
}

function metatable.format(richtext, font, style, color)
end

do

print('-----------------')
local pi=0
local s="[b]THE[/b][c][f][font=shat][color] brOWN FOx[/font] JUMPS what the.."
local t = {}
string.gsub (s, "()(%b[])()", function(i, f, j)
  print(i, f, j)
  local words = s:sub(pi, i-1)
  t[#t+1] = #words > 0 and words or nil
  t[#t+1] = f
  pi = j
end)
t[#t+1] = s:sub(pi, -1)
print(unpack(t))

  

  local function f(i, format, j)
    
  end
  function metatable.write(richtext, text)
    local t = {}
    richtext[_text] = text:gsub('()(%b[])()', function(i, format, j)
      local a = text:sub(pi, i)
      pi
    end)
    richtext[_tokens] = tokenize(richtext[_text])
  end
end

local function tokenize(text)
  local tokens = {}

  local function compare(a, b)
    if a == b then 
      return false 
    else
      return a[2] <= b[2]
    end
  end

  do
    local i, j = text:find('%S+')
    while i do
      tokens[#tokens+1]= {class='word', i, j, false}
      i, j = text:find('%S+', j + 1)
    end
  end

  do
    local i, j = text:find('[ ]+')
    while i do
      tokens[#tokens+1]= {class='whitespace',i, j, false}
      i, j = text:find('[ ]+', j + 1)
    end
  end

  do
    local i, j = text:find('\n')
    while i do
      tokens[#tokens+1]= {class='newline', i, j, false}
      i, j = text:find('\n', j + 1)
    end
  end

  do
    local i, j = text:find('\t')
    while i do
      tokens[#tokens+1]= {class='whitespace', i, j, false}
      i, j = text:find('\t', j + 1)
    end
  end

  table.sort(tokens, compare)

  local leadingspace = true

  for i, token in ipairs(tokens) do
    local tokenclass = token.class
    if tokenclass == 'word' then
      leadingspace = false
    elseif tokenclass == 'newline' then
      leadingspace = true
    elseif tokenclass == 'whitespace' then
      token.leadingspace = leadingspace
    end
  end

  return tokens
end

local function spantokens(tokens, lim)
  local penx, peny = 0, 0
  local spanline, span
  local newline, newspan = true, true
  local spans = {}

  for i,token in ipairs(tokens) do
    local metrics = token.metrics

    newline = newline or token.newline
    newspan = newspan or token.newspan

    if newline or penx + metrics.xmax > lim then --create new spanline
      if spanline then --finalize current spanline
        spanline.peny = spanline.peny+peny
        peny=spanline.peny
      end

      penx=metrics.penx      

      spanline = {xmin=0, xmax=0, ymin=0, ymax=0, peny=0, __index=true}
      spanline.__index=spanline
      span = { text=metrics.text; font=metrics.font; i=token.i, j=token.j, style=token.style; color=token.color; penx=penx; }
      setmetatable(span, spanline)
      spans[#spans+1]=span
    else --continue current spanline
      if newspan then --create new span
        span = { text=metrics.text; font=metrics.font; i=token.i, j=token.j, style=token.style; color=token.color; penx=penx; }
        setmetatable(span, spanline)
        spans[#spans+1]=span
      else --continue current span
        span.j = token.j
      end
    end

    penx = penx + metrics.xadvance 

    spanline.xmin=math.min(spanline.xmin, metrics.xmin)
    spanline.xmax=math.max(spanline.xmax, metrics.xmax)
    spanline.ymin=math.min(spanline.ymin, metrics.ymin)
    spanline.ymax=math.max(spanline.ymax, metrics.ymax)
    spanline.peny = math.max(spanline.peny, metrics.font.bbox.ymax)

    newspan=false
    newline=false
  end

  return spans
end

--TODO make cel call describe only when a refresh is triggered from the metacel, or cel, not from a refresh
--because of cel layout
function metacel:__describe(richtext, t)
  local textlayout = {}
  local n = 0

  --TODO dont' copy spans, but don't use them internally either
  for i, span in ipairs(richtext[_textspans]) do
    n=n+1
    textlayout[n] = {
      text=span.text;
      font=span.font;
      penx=span.penx;  
      peny=span.peny;
      i=span.i;
      j=span.j;
      style=span.style;
      color=span.color;
    } 
  end

  t.textlayout=textlayout
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

  local spans = richtext[_spans]
  local span = spans[1] 

  for i, j in font:wordwrap(text, w) do
    span:reset(text, i, j, penx, peny)
    lines[#lines + 1] = {i = i, j = j, penx = penx, peny = peny, h = fonth}
    peny = peny + fonth
  end

  richtext[_lines] = lines 

  return fonth * (#lines) + ((richtext[_padt] or 0) + (richtext[_padb] or 0))
end



function metacel:refit(richtext, minh)
  richtext._refitcall = nil
  self:setlimits(richtext, richtext.minw, richtext.maxw, minh, richtext.maxh)
  richtext:resize(nil, minh)
end

function metacel:__resize(richtext, ow, oh)
  if richtext.w ~= ow then
    local minh = __reflow(richtext, richtext.w, richtext.h)

    if richtext._refitcall then
      richtext._refitcall.cancel = true
    end
    richtext._refitcall = self:asyncall('refit', richtext, minh)
  end
end

--[[
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
--]]

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
    --picktext(richtext, x, y)
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
    richtext[_lines] = {{i = 1, j = nil, penx = penx, peny = peny, h = font.lineheight}}

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

return cel.newfactory(metacel, {
  layout = layout, caret = caret,
})
